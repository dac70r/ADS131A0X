
/* SPI Module */

module SPI_Master 
(
	input 				system_clock,			// System Clock from FPGA - 50Mhz
	input 				reset_n,					// Reset button
	input					adc_init,				// Trigger signal to init the adc
	input 				adc_ready,				// Trigger signal to send SPI transaction
	output 	reg [2:0]state,					// Keeps track of the current state of SPI
	
	output 	reg		SPI_MOSI,				// SPI MOSI
	input 				SPI_MISO,				// SPI MISO
	output	reg		SPI_CS,					//	SPI CS
	output 				SPI_SCLK					// SPI SCLK
);

wire synthesized_clock_4_167Mhz;

/* Clock Synthesis for SPI*/
clock_synthesizer #(.COUNTER_LIMIT(6)) clock_synthesizer_uut_0
(
    .input_clock(system_clock), 							// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_4_167Mhz)					// output clock - 4.167Mhz 
);

assign SPI_SCLK = synthesized_clock_4_167Mhz;

/* SPI State Definition */
// Define state encoding using localparams
localparam IDLE        = 2'b00;
localparam SETUP       = 2'b01;
localparam TRANSACTION = 2'b10;

// Current and Next States 
reg [1:0] current_state, next_state;

// State transition logic
    always @(posedge synthesized_clock_4_167Mhz or negedge reset_n) begin
        if (!reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
	 
// Next state logic
	 always @(*) begin
		  case (current_state)
				IDLE:        next_state = adc_init ? SETUP : IDLE;
				SETUP:       next_state = TRANSACTION; 							// Ensures SETUP is visited only once
				TRANSACTION: next_state = adc_ready ? IDLE : TRANSACTION;	// Gets stuck in transaction if SPI Transaction fails
				default:     next_state = IDLE;
		  endcase
	 end
	 
// Output logic - for debugging purposes
    always @(posedge system_clock) begin
        state <= current_state;
    end


endmodule 