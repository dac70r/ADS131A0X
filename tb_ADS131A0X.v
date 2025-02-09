`timescale 1ns / 1ps

module tb_ADS131A0X;

// Testbench signals
reg system_clock;         // 50 MHz system clock
wire [3:0] led;           // LEDs output

// Instantiate the top module (Device Under Test)
ADS131A0X uut (
    .system_clock(system_clock),
    .led(led)
);

// Clock generation (50 MHz clock)
always begin
    #10 system_clock = ~system_clock;  // Toggle every 10ns for a 50 MHz clock
end

// Initial block to drive the testbench signals
initial begin
    // Initialize signals
    system_clock = 0;

    // Display initial values for monitoring
    // $monitor("Time: %0t | system_clock: %b | LED[3:0]: %b", $time, system_clock, led);

    // Run the simulation for a period of time (e.g., 2000 ms)
    #2000000000;

    // End the simulation
    $finish;
end

endmodule
