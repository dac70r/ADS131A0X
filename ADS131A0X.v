/*
* Name:			ADC Driver Driver Development
* Purpose:		ADC Interface (Wrapper)
* ADC Model: 	ADS131A0x 
* Project: 		ViCAT LSC Proj 
* Interface: 	SPI Protocol, Cyclone 10 LP Intel FPGA
* Author: 		Dennis Wong Guan Ming
* Date:			6/2/2025 
*/

/* Top Module */
module ADS131A0X (
    input 				system_clock, 			// 50 Mhz system clock
	 input				reset_n,					// Reset activated by push button
	 
	 /* Core SPI Signals for ADC */
	 output 				SPI_SCLK,				// SPI SCLK
	 output				SPI_CS,					//	SPI CS
	 output 				SPI_RESET,				// SPI_RESET
	 output 				SPI_MOSI,				// SPI MOSI
	 input 				SPI_MISO,				// SPI MISO

	 /* Supplementary SPI Signals for ADC */
	 // for development purposes, tbc inclusion in main design
	 input				adc_init,			 			// Trigger signal to init the adc					- for simulation (consider removing in final design)
	 input 				adc_ready,				 		// Trigger signal to send SPI transaction			- for simulation (consider removing in final design)
	
	/* Debugging purposes */
	// for debugging this module use only, do not include when integrating with main design
	output				clock_4_167Mhz_debug,		// Keeps track of the main clock used in Submodule
	output [4:0]		state,					 		// Keeps track of the current state of SPI 		- for debugging (remove in final design)
	output 				adc_init_completed, 			// Keeps track of the init progress of the ADC 	- for debugging (remove in final design)
	output [7:0]		count_cs_debug,
	output				heartbeat,		
	output [4:0]		state_tracker_output,
	output [31:0]		spi_miso_data_output,
	output [7:0]		spi_miso_data_cc_output
	);

wire SPI_SCLK_Temp;										// SPI Clock
wire [7:0] count_cs;
wire [7:0] spi_miso_data_cc;

/* Heartbeat Instance */
heartbeat heartbeat_uut
(
    .input_clock(system_clock), 							// 50 Mhz system clock
	 .clock_pol(heartbeat)										// output clock to led0 @ 1Mhz
);

/* SPI_Master Instance */
SPI_Master SPI_Master_uut
(
	.system_clock(system_clock),							// System Clock from FPGA - 50Mhz
	.reset_n(reset_n),										// Reset_n manually activated by push button	
	.SPI_MOSI(SPI_MOSI),										// SPI MOSI
	.SPI_MISO(SPI_MISO),										// SPI MISO
	.SPI_CS(SPI_CS),											//	SPI CS
	.SPI_SCLK(SPI_SCLK_Temp),								// SPI SCLK
	.SPI_RESET(SPI_RESET),
	
	// Non crucial Signals (for simulation and debugging)
	.clock_4_167Mhz_debug(clock_4_167Mhz_debug),
	.state(state),												// Keeps track of the current state of SPI
	.count_cs(count_cs),
	.state_tracker_output(state_tracker_output),
	.spi_miso_data_input(spi_miso_data),				// debug - keeps track of the spi_miso_data received
	.spi_miso_data_cc_output(spi_miso_data_cc)
);

/* Captures Input from the ADC via SPI_MISO */
reg [31:0] spi_miso_data = 32'd0;
always @ (negedge SPI_SCLK_Temp)
begin
	spi_miso_data['d32 - spi_miso_data_cc] <= SPI_MISO;
end

assign SPI_SCLK = SPI_SCLK_Temp;							// Core Signal

// Debug by Dennis 
assign spi_miso_data_output = spi_miso_data;			// For Visualizing the data at SPI_MISO 
assign count_cs_debug = count_cs;	
assign spi_miso_data_cc_output = spi_miso_data_cc;					

endmodule