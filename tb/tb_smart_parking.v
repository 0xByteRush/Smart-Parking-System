`timescale 1ns / 1ps
// Self-checking testbench for Smart_Parking_System.
// The debouncer delay is shortened so a button press takes tens of cycles instead of 5 ms.
module tb_smart_parking;
    reg sysclk = 0, reset = 0;
    reg normal_enter = 0, normal_exit = 0, handicap_enter = 0, handicap_exit = 0;
    wire LED_Handicap_RED, LED_Handicap_GREEN, LED_Normal_RED, LED_Normal_GREEN;
    wire [7:0] seg, an;
    integer errors = 0, i;

    Smart_Parking_System dut (
        .sysclk(sysclk), .reset(reset),
        .normal_enter(normal_enter), .normal_exit(normal_exit),
        .handicap_enter(handicap_enter), .handicap_exit(handicap_exit),
        .LED_Handicap_RED(LED_Handicap_RED), .LED_Handicap_GREEN(LED_Handicap_GREEN),
        .LED_Normal_RED(LED_Normal_RED), .LED_Normal_GREEN(LED_Normal_GREEN),
        .seg(seg), .an(an)
    );

    defparam dut.debounced_signal.delay  = 4;
    defparam dut.debounced_signal1.delay = 4;
    defparam dut.debounced_signal2.delay = 4;
    defparam dut.debounced_signal3.delay = 4;

    always #5 sysclk = ~sysclk; // 100 MHz, like the Nexys A7 clock

    // Hold a button long enough for the debouncer to accept it, then release it
    task press(input integer which);
        begin
            case (which)
                0: normal_enter = 1;
                1: normal_exit = 1;
                2: handicap_enter = 1;
                3: handicap_exit = 1;
            endcase
            repeat (20) @(posedge sysclk);
            {normal_enter, normal_exit, handicap_enter, handicap_exit} = 4'b0;
            repeat (20) @(posedge sysclk);
        end
    endtask

    task expect_counts(input [4:0] normal, input [2:0] handicap, input [8*40-1:0] label);
        begin
            if (dut.normal_count !== normal || dut.handicap_count !== handicap) begin
                $display("FAIL %0s: normal=%0d (want %0d) handicap=%0d (want %0d)",
                         label, dut.normal_count, normal, dut.handicap_count, handicap);
                errors = errors + 1;
            end else
                $display("PASS %0s: normal=%0d handicap=%0d", label, normal, handicap);
            if (LED_Normal_GREEN !== (normal > 0) || LED_Normal_RED !== (normal == 0) ||
                LED_Handicap_GREEN !== (handicap > 0) || LED_Handicap_RED !== (handicap == 0)) begin
                $display("FAIL %0s: status LEDs do not match the counts", label);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // The debouncers have no reset, so give their registers a known start (an FPGA powers them up at 0)
        dut.debounced_signal.new  = 0; dut.debounced_signal.count  = 0; dut.debounced_signal.cleanclk  = 0;
        dut.debounced_signal1.new = 0; dut.debounced_signal1.count = 0; dut.debounced_signal1.cleanclk = 0;
        dut.debounced_signal2.new = 0; dut.debounced_signal2.count = 0; dut.debounced_signal2.cleanclk = 0;
        dut.debounced_signal3.new = 0; dut.debounced_signal3.count = 0; dut.debounced_signal3.cleanclk = 0;

        reset = 1; repeat (3) @(posedge sysclk); reset = 0; repeat (3) @(posedge sysclk);
        expect_counts(20, 5, "after reset");

        press(0); press(0); press(0);
        expect_counts(17, 5, "3 normal entries");

        press(1);
        expect_counts(18, 5, "1 normal exit");

        for (i = 0; i < 25; i = i + 1) press(0);
        expect_counts(0, 5, "normal lot full saturates at 0");

        press(1);
        expect_counts(1, 5, "exit from a full lot");

        for (i = 0; i < 25; i = i + 1) press(1);
        expect_counts(20, 5, "normal lot empty saturates at 20");

        for (i = 0; i < 7; i = i + 1) press(2);
        expect_counts(20, 0, "handicap lot full saturates at 0");

        for (i = 0; i < 7; i = i + 1) press(3);
        expect_counts(20, 5, "handicap lot empty saturates at 5");

        // A button held down must count once, not once per clock
        normal_enter = 1; repeat (200) @(posedge sysclk); normal_enter = 0; repeat (20) @(posedge sysclk);
        expect_counts(19, 5, "held button counts once");

        reset = 1; @(posedge sysclk); reset = 0; @(posedge sysclk);
        expect_counts(20, 5, "reset restores capacity");

        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule
