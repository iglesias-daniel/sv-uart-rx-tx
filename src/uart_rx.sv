module uart_rx #(
    parameter BAUD_DIV = 434, // baud_rate = 115200 with 50MHz clock
    parameter DATA_BITS = 8,
    parameter ENABLE_PARITY = 1,
) (
    input clk,
    input rx,
    input rst_n,
    output logic ready,
    output logic [DATA_BITS-1:0] data_out,
    output logic error
);

    logic tick;
    logic [15:0] counter;
    logic [$clog2(DATA_BITS):0] bit_counter;
    logic parity_bit;
    logic k;

    logic income_message;

    // Ticker
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tick <= 0;
            income_message <= 0;
        end else begin
            if (!rx) begin
                income_message <= 1;
            end
            if (!income_message) begin
                counter <= 0;
                tick <= 0;
            end else begin
                if (counter == BAUD_DIV - 1) begin
                    tick <= 1;
                    counter <= 0;
                end else begin
                    tick <= 0;
                    counter <= counter + 1;
                end
                if (next_state == WAIT) begin //Modificar esto
                    income_message <= 0;
                end
            end
        end
    end

    // FSM States
    typedef enum logic [1:0] {
        WAIT,
        DATA,
        PARITY,
        STOP
    } state_t;

    state_t state, next_state;

    always_ff @(posedge tick or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT;
            bit_counter <= 0;
            data_out <= 0;
        end else begin
            case (state)
                WAIT: begin
                    if (income_message) begin
                        ready <= 0;
                    end else begin
                        ready <= 1;
                    end
                end
                DATA: begin
                    data_out[bit_counter] <= rx;
                    if (bit_counter == DATA_BITS-1)
                        bit_counter <= 0;
                    else
                        bit_counter <= bit_counter + 1;
                end
                PARITY: parity_bit <= rx;
                STOP: begin 
                    ready <= 1;
                end
            endcase
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            WAIT: begin
                if (income_message)
                    next_state = DATA;
            end
            DATA: begin
                if (bit_counter == DATA_BITS -1)
                    if (ENABLE_PARITY)
                        next_state = PARITY;
                    else
                        next_state = STOP;
                else
                    next_state = DATA;
            end
            PARITY: next_state = STOP;
            STOP: next_state = WAIT;
            default: next_state = WAIT;
        endcase
    end
endmodule