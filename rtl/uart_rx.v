module uart_rx #(
    parameter BAUD_DIV = 434,
    parameter DATA_BITS = 8,
    parameter PARITY_TYPE = 1,
    parameter STOP_BIT = 1
) (
    input clk,
    input rx,
    input rst_n,
    output reg ready,
    output reg [DATA_BITS-1:0] data_out,
    output reg error
);


    /* Esta máquina de estados indica que se esta recibiendo, o si se esta esperando */
    localparam WAIT = 2'b00;
    localparam DATA = 2'b01;
    localparam PARITY = 2'b10;
    localparam STOP = 2'b11;

    /* Tipos de paridad */
    localparam PARITY_NONE = 0;
    localparam PARITY_EVEN = 1;
    localparam PARITY_ODD = 2;

    /* Se define el state actual, y el próximo state */
    reg [1:0] state, next_state;

    reg tick; // Tick que señala cuando hay que medir el bit del mensaje entrante
    reg [15:0] counter; // Contador interno para sincronizar bien los baudios
    reg [$clog2(DATA_BITS):0] bit_counter; // Contador de bits recibidos del mensaje
    reg [$clog2(STOP_BIT):0] stop_counter; // Contador en caso de tener más de un BIT de parada
    reg parity_bit; // Bit de paridad

    reg income_message; // Señal de que un mensaje está entrando


    // Ticker
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tick <= 0;
            income_message <= 0;
        end else begin
            tick <= 0;
            if (!rx & !income_message) begin
                /* El protocolo UART empieza con un bit = 0 al inicio del mensaje,
                por lo que, al ser rx = 0, significa que un mensaje está llegando.
                Además, se inicia el tick inicial. */
                income_message <= 1;
                tick <= 1;
            end else begin
                if (income_message) begin
                    /* En caso de sí estar llegando un mensaje empieza a contar el counter para
                    sincronizarse de acuerdo a los baudios. Cada vez que se alcanza la frecuencia
                    deseada, se general el tick. El segundo tick demora 1.5 de la frecuencia, para
                    que la medición se realice en medio del bit recibido. Para determinar que estamos
                    contando el segundo, usamos el bit_counter.*/
                    if (bit_counter == 0) begin
                        if (counter == (BAUD_DIV + (BAUD_DIV >> 1)) - 1) begin
                            tick <= 1;
                            counter <= 0;
                        end else begin
                            tick <= 0;
                            counter <= counter + 1;
                        end
                    end else begin
                        if (counter == BAUD_DIV - 1) begin
                            tick <= 1;
                            counter <= 0;
                            /* Si el próximo estado de la FSM va a ser WAIT, significa que se han recibido
                            todos los bits del mensaje, y ya no hay un mensaje llegando, por lo que se
                            establece en 0 */
                            if (next_state == WAIT) begin
                                income_message <= 0;
                            end 
                        end else begin
                            tick <= 0;
                            counter <= counter + 1;
                        end
                    end
                end
                
            end
        end
    end
    
    /* La siguiente parte del código describe que hace cada estado */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT;
            bit_counter <= 0;
            stop_counter <= 0;
            ready <= 1;
            data_out <= 0;
            error <= 0;
            parity_bit <= 0;
        end else if (tick) begin
            case (state)
                WAIT: begin
                    /* Se reinician los contadores de los bits leídos y de la cantidad de bits de stop */
                    bit_counter <= 0;
                    stop_counter <= 0;
                    /* Este es el estado default, establece ready = 0, si se está recibiendo un mensaje
                    y un ready = 1 si no lo está */
                    if (income_message) begin
                        ready <= 0;
                    end else begin
                        ready <= 1;
                    end
                end
                DATA: begin
                    /* Este estado se encarga de ir guardando bit a bit el mensaje que llega. En caso de
                    que se reciban todos los bits, se resetea el bit_counter*/
                    data_out[bit_counter] <= rx;
                    bit_counter <= bit_counter + 1;
                end
                PARITY: parity_bit <= rx;
                STOP: begin
                    /* Este contador es por si hay más de un bit de parada */
                    stop_counter <= stop_counter + 1;

                    /* También se determina si existe un error en el mensaje, si está activada la paridad, segun el tipo de paridad*/
                    case (PARITY_TYPE)
                        PARITY_NONE: error <= (rx != 1);
                        PARITY_EVEN: error <= (parity_bit != ^data_out) | (rx != 1);
                        PARITY_ODD: error <= (parity_bit == ^data_out) | (rx != 1);
                        default: error <= (rx != 1);
                    endcase

                    /* Recibido el final del mensaje, se establece ready = 1 */
                    if (next_state == WAIT)
                        ready <= 1;
                end
            endcase
            /* Se actualiza el estado al siguiente estado */
            state <= next_state;
        end
    end

    /* La siguiente parte del código describe como se elige el siguiente estado */
    always @(*) begin
        /* En caso de no cambiar de estado, se mantiene el actual.*/
        next_state = state;
        case (state)
            WAIT: begin
                /* Sale del estado WAIT a DATA si empieza a recibir un mensaje */
                if (income_message)
                    next_state = DATA;
            end
            DATA: begin
                /* Al llegar todos los bits, se considera paridad si así está configurado */
                if (bit_counter == DATA_BITS - 1)
                    if ((PARITY_TYPE == PARITY_EVEN) || (PARITY_TYPE == PARITY_ODD))
                        next_state = PARITY;
                    else
                        next_state = STOP;
                else
                    next_state = DATA;
            end
            PARITY: next_state = STOP;
            STOP:
                if (stop_counter == STOP_BIT - 1)
                    next_state = WAIT;
            default: next_state = WAIT;
        endcase
    end
endmodule