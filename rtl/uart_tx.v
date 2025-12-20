module uart_tx #(
    parameter BAUD_DIV = 434,
    parameter DATA_BITS = 8,
    parameter PARITY_TYPE = 1,
    parameter STOP_BIT = 1
) (
    input clk,
    input valid,
    input [DATA_BITS-1:0] data_in,
    input rst_n,
    output wire ready,
    output wire tx
);
    
    /* Esta máquina de estados indica que se esta enviando, o si se esta esperando */
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
    
    reg tick; // Tick que marca cada cuanto sale un bit de la trama
    reg [15:0] counter; // Contador itnerno para sincronizar bien los baudios
    reg [$clog2(DATA_BITS):0] bit_counter; // Contador de bits enviados del mensaje
    reg [$clog2(STOP_BIT):0] stop_counter; // Contador en caso de tener más de un BIT de Stop
    reg parity_bit; // Bit de paridad
    reg send_message;
    reg [DATA_BITS:0] data_sent;

    // Ticker
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tick <= 0;
            send_message <= 0;
            data_sent <= 0;
        end else begin
            if (ready & valid) begin
                send_message <= 1;
                data_sent <= data_in;
            end
            tick <= 0;
            if (send_message) begin
                /* El ticker empieza a funcionar en caso de que exista un mensaje valido para enviar */
                if (counter == BAUD_DIV - 1) begin
                    tick <= 1;
                    counter <= 0;
                    if (next_state == WAIT) begin
                        send_message <= 0;
                    end
                end else begin
                    tick <= 0;
                    counter <= counter + 1;
                end
            end
        end
    end

    /* La siguiente parte del código describe que hace cada estado */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT;
            tx <= 1;
            bit_counter <= 0;
            stop_counter <= 0;
            ready <= 1;
        end else if (tick) begin
            case (state)
                WAIT: begin
                    bit_counter <= 0;
                    stop_counter <= 0;
                    if (valid) begin
                        tx <= 0;
                        ready <= 0;
                    end else begin
                        tx <= 1;
                        ready <= 1;
                    end
                end
                DATA: begin
                    tx <= data_sent[bit_counter];
                    bit_counter <= bit_counter + 1;
                end
                PARITY: tx <= parity_bit;
                STOP: begin
                    tx <= 1;
                    stop_counter <= stop_counter + 1;
                    if (next_state == WAIT)
                        ready <= 1;
                end
            endcase
            state <= next_state;
        end
    end

    /* La siguiente parte del código describe como se elige el siguiente estado */
    always @(*) begin
        next_state = state;
        case (state)
            WAIT: begin
                if (valid)
                    next_state = DATA;
            end
            DATA: begin
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

    always @(*) begin
        case (PARITY_TYPE)
            PARITY_NONE: parity_bit = 0;
            PARITY_EVEN: parity_bit = ~^data_sent;
            PARITY_ODD: partity_bit = ^data_sent;
            default: parity_bit = 0;
        endcase
    end

endmodule