// ADS131A0x Driver Development Project
// Interface: 	SPI Protocol, Cyclone 10 LP Intel FPGA
// Author: 		Dennis Wong
// Date:			6/2/2025 


/* Top Module */
module ADS131A0X (
    input 				system_clock, 			// 50 Mhz system clock
	 output 				[3:0]led					// leds 
);

wire systhesized_clock_1Mhz;					// 1Mhz clock for heartbeat
wire systhesized_clock_4Mhz;					// 4Mhz clock for SPI_Clock

/* Clock Synthesis Instance */
clock_synthesizer clock_synthesizer_uut
(
    .input_clock(system_clock), 							// input clock  - 50 Mhz
	 .clock_pol(led[1])					// output clock - 4.167Mhz 
);

/* Heartbeat Instance */
heartbeat heartbeat_uut(
    .input_clock(system_clock), 							// 50 Mhz system clock
	 .clock_pol(led[0])										// leds 
);

assign led[3:2] = 2'b11;									// assign led to low

endmodule
