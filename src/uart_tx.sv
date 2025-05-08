module uart_tx #(
    parameter BAUD_DIV = 434, // baud_rate = 115200 with 50MHz clock
    parameter DATA_BITS = 8,
    parameter ENABLE_PARITY = 1,
) (
    input clk,
    input valid,
    input [DATA_BITS-1:0] data_in,
    input rst_n,
    output logic ready,
    output logic tx
);
    logic tick;
    logic [15:0] counter;
    logic [$clog2(DATA_BITS):0] bit_counter;
    logic parity_bit;
    logic k;

    // Ticker
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
        end
    end

    // FSM
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
        end else begin
            case (state)
                WAIT: begin
                    if (valid) begin
                        tx <= 0;
                        ready <= 0;
                    end else begin
                        tx <= 1;
                        ready <= 1;
                    end
                end
                DATA: begin
                    tx <= data_in[bit_counter];
                    if (bit_counter == DATA_BITS - 1)
                        bit_counter <= 0;
                    else
                        bit_counter <= bit_counter + 1;
                end
                PARITY: tx <= ^data_in;
                STOP: tx <= 1;
            endcase
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            WAIT: begin
                if (valid)
                    next_state = DATA;
            end
            DATA: begin
                if (bit_counter == DATA_BITS - 1)
                    if (ENABLE_PARITY)
                        next_state = PARITY;
                    else
                        next_state = STOP;
                else
                    next_state = DATA;
            end
            PARITY: begin
                next_state = STOP;
            end
            STOP: begin
                next_state = WAIT;
            end
            default: next_state = WAIT;
        endcase
    end

endmodule