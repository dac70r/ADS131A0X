
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
	output 				SPI_SCLK,				// SPI SCLK
	output 	reg 		SPI_RESET,
	output 				adc_init_completed_z
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

// ADC Init Complete Register - makes sure that the INIT is only performed once 
reg adc_init_completed = 1'b0;

// ADS131A0xReset() Register
reg [31:0] counter = 32'b0;

// State transition logic
    always @(posedge synthesized_clock_4_167Mhz or negedge reset_n) begin
        if (!reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
	 
// Next state logic
/* Behavior: IDLE: 	Checks adc_init_completed. if no, next state will be SETUP. if yes, next state will be TRANSACTION.
				 SETUP:	Runs once. Next state is TRANSACTION
				 TRANSACTION: Checks if adc_ready, if no, STAY in TRANSACTION state. if yes, next state will be IDLE.
*/	
	 always @(*) begin
		  case (current_state)
				IDLE:				next_state = (adc_init_completed != 1) ? (adc_init ? SETUP : IDLE) : (adc_ready ? TRANSACTION : IDLE);
				
				// Ensures SETUP is only visited once
				SETUP:			next_state = (adc_init_completed == 1) ? TRANSACTION : SETUP; 	
				
				TRANSACTION:	next_state = adc_ready ? IDLE : TRANSACTION;									// Gets stuck in transaction if SPI Transaction fails
				default:     next_state = IDLE;
		  endcase
	 end
	 
// Output logic - for debugging purposes
    always @(posedge system_clock) begin
        state <= current_state;
    end
	 
// ADS131A0xReset() - Resets the ADC by pulling RESET pin LOW and then HIGH again
	// Main logic - toggling GPIO pin and adding delay
	always @(posedge synthesized_clock_4_167Mhz or negedge reset_n) begin
	  if (!reset_n) begin
			counter <= 0;
	  end
	  else begin
			if(current_state == SETUP && adc_init_completed !=1) begin  
				counter <= counter + 1;
				// Handle delay for 5ms or 20ms
				if (counter < 32'd20835) begin
					SPI_RESET <= 1'b0;       // Set GPIO pin to LOW (GPIO_PIN_RESET)
				end
				else if (counter < 32'd104_175) begin
					SPI_RESET <= 1'b1;        // Set GPIO pin to HIGH (GPIO_PIN_SET)
				end
				else begin
					counter <= 0;         // Reset counter for next delay
					adc_init_completed <= 1;
				end
			end
	  end
	end 

	assign adc_init_completed_z = adc_init_completed;

endmodule 