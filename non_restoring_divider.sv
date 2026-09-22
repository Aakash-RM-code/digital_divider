module non_restoring_divider #(
    parameter int WIDTH = 16
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             start,

    input  logic [WIDTH-1:0] dividend,
    input  logic [WIDTH-1:0] divisor,

    output logic [WIDTH-1:0] quotient,
    output logic [WIDTH-1:0] remainder,

    output logic             busy,
    output logic             done,
    output logic             divide_by_zero
);

    localparam int COUNT_WIDTH = (WIDTH <= 1) ? 1 : $clog2(WIDTH);

    logic [WIDTH-1:0] divisor_reg;
    logic [WIDTH-1:0] dividend_reg;

    logic signed [WIDTH:0] remainder_reg;

    logic [WIDTH-1:0] quotient_reg;

    logic [COUNT_WIDTH-1:0] count;

    logic signed [WIDTH:0] shifted_remainder;
    logic signed [WIDTH:0] remainder_next;
    logic [WIDTH-1:0] quotient_next;

    always_comb begin

        // 2R + next dividend bit
        shifted_remainder = {
            remainder_reg[WIDTH-1:0],
            dividend_reg[WIDTH-1]
        };

        // Default quotient bit
        quotient_next = {
            quotient_reg[WIDTH-2:0],
            1'b0
        };

        // Non-restoring add/subtract
        if (shifted_remainder >= 0) begin

            remainder_next =
                shifted_remainder - $signed({1'b0, divisor_reg});

        end
        else begin

            remainder_next =
                shifted_remainder + $signed({1'b0, divisor_reg});

        end

        // Quotient digit is determined by the new remainder
        if (remainder_next >= 0) begin

            quotient_next = {
                quotient_reg[WIDTH-2:0],
                1'b1
            };

        end
    end


    always_ff @(posedge clk) begin

        if (rst) begin

            divisor_reg   <= '0;
            dividend_reg  <= '0;
            remainder_reg <= '0;
            quotient_reg  <= '0;

            quotient      <= '0;
            remainder     <= '0;

            count          <= '0;
            busy           <= 1'b0;
            done           <= 1'b0;
            divide_by_zero <= 1'b0;
        end

        else begin

            done <= 1'b0;

            // Start
            if (start && !busy) begin

                if (divisor == 0) begin

                    quotient       <= '0;
                    remainder      <= '0;
                    divide_by_zero <= 1'b1;

                    done <= 1'b1;
                    busy <= 1'b0;

                end
                else begin

                    divisor_reg   <= divisor;
                    dividend_reg  <= dividend;

                    remainder_reg <= '0;
                    quotient_reg  <= '0;

                    count <= '0;

                    busy           <= 1'b1;
                    divide_by_zero <= 1'b0;
                end
            end

            // Iteration
            else if (busy) begin

                remainder_reg <= remainder_next;

                dividend_reg <= {
                    dividend_reg[WIDTH-2:0],
                    1'b0
                };

                quotient_reg <= quotient_next;

                // Final iteration
                if (count == WIDTH-1) begin

                    quotient <= quotient_next;

                    // Final correction
                    if (remainder_next < 0)
                        remainder <=
                            remainder_next[WIDTH-1:0]
                            + divisor_reg;
                    else
                        remainder <=
                            remainder_next[WIDTH-1:0];

                    busy <= 1'b0;
                    done <= 1'b1;

                end
                else begin
                    count <= count + 1'b1;
                end
            end
        end
    end

endmodule