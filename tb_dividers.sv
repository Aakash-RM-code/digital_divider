`timescale 1ns/1ps

module tb_dividers;

    parameter int WIDTH = 16;

    logic clk;
    logic rst;
    logic start;

    logic [WIDTH-1:0] dividend;
    logic [WIDTH-1:0] divisor;

    // Restoring
    logic [WIDTH-1:0] restoring_q;
    logic [WIDTH-1:0] restoring_r;
    logic restoring_busy;
    logic restoring_done;
    logic restoring_divzero;

    // Non-restoring
    logic [WIDTH-1:0] nonrestoring_q;
    logic [WIDTH-1:0] nonrestoring_r;
    logic nonrestoring_busy;
    logic nonrestoring_done;
    logic nonrestoring_divzero;

    integer i;
    integer expected_q;
    integer expected_r;

    restoring_divider #(
        .WIDTH(WIDTH)
    ) restoring_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(restoring_q),
        .remainder(restoring_r),
        .busy(restoring_busy),
        .done(restoring_done),
        .divide_by_zero(restoring_divzero)
    );

    non_restoring_divider #(
        .WIDTH(WIDTH)
    ) nonrestoring_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(nonrestoring_q),
        .remainder(nonrestoring_r),
        .busy(nonrestoring_busy),
        .done(nonrestoring_done),
        .divide_by_zero(nonrestoring_divzero)
    );


    // 100 MHz clock
    always #5 clk = ~clk;


    task automatic run_test(
        input integer a,
        input integer b
    );

        begin

            expected_q = a / b;
            expected_r = a % b;

            @(negedge clk);

            dividend = a;
            divisor  = b;
            start    = 1'b1;

            @(negedge clk);

            start = 1'b0;

            wait(restoring_done && nonrestoring_done);

            #1;

            if ((restoring_q == expected_q) &&
                (restoring_r == expected_r)) begin

                $display(
                    "[PASS] Restoring: %0d / %0d = %0d R %0d",
                    a, b, restoring_q, restoring_r
                );

            end
            else begin

                $display(
                    "[FAIL] Restoring: %0d / %0d -> Q=%0d R=%0d | Expected Q=%0d R=%0d",
                    a, b,
                    restoring_q,
                    restoring_r,
                    expected_q,
                    expected_r
                );

            end


            if ((nonrestoring_q == expected_q) &&
                (nonrestoring_r == expected_r)) begin

                $display(
                    "[PASS] Non-Restoring: %0d / %0d = %0d R %0d",
                    a, b, nonrestoring_q, nonrestoring_r
                );

            end
            else begin

                $display(
                    "[FAIL] Non-Restoring: %0d / %0d -> Q=%0d R=%0d | Expected Q=%0d R=%0d",
                    a, b,
                    nonrestoring_q,
                    nonrestoring_r,
                    expected_q,
                    expected_r
                );

            end

            if ((restoring_q == expected_q) &&
                (restoring_r == expected_r) &&
                (nonrestoring_q == expected_q) &&
                (nonrestoring_r == expected_r))

                $display("TEST RESULT: PASS\n");

            else

                $display("TEST RESULT: FAIL\n");

        end

    endtask


    initial begin

        clk = 0;
        rst = 1;
        start = 0;

        dividend = 0;
        divisor = 0;

        // Reset
        #20;
        rst = 0;

        // Directed tests
        run_test(17, 5);
        run_test(100, 7);
        run_test(255, 13);
        run_test(1024, 32);
        run_test(12345, 123);
        run_test(65535, 255);
        run_test(1, 1);
        run_test(32768, 2);
        run_test(65535, 1);
        run_test(65535, 65535);

        // Random tests
        for (i = 0; i < 100; i = i + 1) begin

            run_test(
                $urandom_range(1, 65535),
                $urandom_range(1, 65535)
            );

        end

        $display("========================================");
        $display("ALL DIVIDER TESTS COMPLETED");
        $display("========================================");

        #50;

        $finish;

    end

endmodule