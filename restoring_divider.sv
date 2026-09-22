module restoring_divider #(
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
    logic [WIDTH:0]   remainder_reg;
    logic [WIDTH-1:0] quotient_reg;

    logic [COUNT_WIDTH-1:0] count;

    logic [WIDTH:0] remainder_shift;
    logic [WIDTH:0] remainder_next;
    logic [WIDTH-1:0] quotient_next;

    always_comb begin

        // Shift partial remainder and bring in next dividend bit
        remainder_shift = {
            remainder_reg[WIDTH-1:0],
            dividend_reg[WIDTH-1]
        };

        // Default values
        remainder_next = remainder_shift;
        quotient_next  = {
            quotient_reg[WIDTH-2:0],
            1'b0
        };

        // Trial subtraction
        if (remainder_shift >= {1'b0, divisor_reg}) begin
            remainder_next = remainder_shift - {1'b0, divisor_reg};

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

            // Start operation
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

            // Division iteration
            else if (busy) begin

                remainder_reg <= remainder_next;

                dividend_reg <= {
                    dividend_reg[WIDTH-2:0],
                    1'b0
                };

                quotient_reg <= quotient_next;

                // Last iteration
                if (count == WIDTH-1) begin

                    quotient  <= quotient_next;
                    remainder <= remainder_next[WIDTH-1:0];

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