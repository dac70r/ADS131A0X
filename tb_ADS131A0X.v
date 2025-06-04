`timescale 1ns / 1ps

module tb_ADS131A0X;

// Testbench signals
reg system_clock;         // 50 MHz system clock
reg SPI_MISO;
reg reset_n;
reg adc_init;
reg adc_ready;

wire [2:0] state;
wire SPI_MOSI;
wire SPI_SCLK;
wire SPI_CS;
wire SPI_RESET;
wire [3:0] led;           // LEDs output
wire adc_init_completed_z;
wire [3:0] count_cs_debug;


// Instantiate the top module (Device Under Test)
ADS131A0X uut (
    .system_clock(system_clock),
	 .SPI_MOSI(SPI_MOSI),
	 .SPI_MISO(SPI_MISO),
	 .SPI_CS(SPI_CS),
	 .SPI_SCLK(SPI_SCLK),
	 .adc_init(adc_init),
	 .adc_ready(adc_ready),
	 .reset_n(reset_n),
	 .state(state),
    	.led(led),
	 .SPI_RESET(SPI_RESET),
	 .adc_init_completed_z(adc_init_completed_z),
	 .count_cs_debug(count_cs_debug)
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
	 #1000
	 adc_init = 1;
	 
	 #1000
	 adc_init = 0;
	 adc_ready = 1;

    // Run the simulation for a period of time (e.g., 2000 ms)
    #50000000;

    // End the simulation
    $finish;
end

endmodule
