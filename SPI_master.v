
/* SPI Module */

module SPI_Master 
(
	input 				system_clock,									// System Clock from FPGA - 50Mhz
	input 				reset_n,											// Reset button
	
	output 	reg		SPI_MOSI,										// SPI MOSI
	input 				SPI_MISO,										// SPI MISO
	output	reg		SPI_CS,									//	SPI CS
	output 				SPI_SCLK,										// SPI SCLK
	output 	reg 		SPI_RESET,										// SPI_RESET - to reset the ADC
	
	/* Not essential signals - can be removed */
	input					adc_init,										// Trigger signal to init the adc
	input 				adc_ready,										// Trigger signal to send SPI transaction
	output 	reg [2:0]state,											// debug - tracks the current state of SPI
	output 				adc_init_completed,						// debug - tracks the state of spi init (done or not done)
	output 	reg 		adc_transaction_completed,					// debug - tracks the state of spi transaction (yes or no)
	output 		[3:0] count_cs											// debug - keeps track of the 
);

wire synthesized_clock_4_167Mhz;
wire SPI_SCLK_Temp; 

/* Clock Synthesis for SPI*/
clock_synthesizer #(.COUNTER_LIMIT(6)) clock_synthesizer_uut_0
(
    .input_clock(system_clock), 									// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_4_167Mhz)					// output clock - 4.167Mhz 
);

/* Clock Synthesizer for SPI with CS Consideration */
spi_sclk_generator spi_sclk_generator_uut (
    .CLK_4_167(synthesized_clock_4_167Mhz),       					// System clock - 4.167Mhz
    .SPI_CS(SPI_CS),       												// Chip Select (Active LOW)
	 .SPI_SCLK(SPI_SCLK_Temp),
	 .count_cs(count_cs)
); 

assign SPI_SCLK = SPI_SCLK_Temp;

/* SPI State Definition */
// Define state encoding using localparams
localparam RESET        				= 3'd0;
localparam IDLE        					= 3'd1;
localparam SETUP       					= 3'd2;
localparam WAIT_TRANSACTION			= 3'd3;
localparam TRANSACTION_BEGIN			= 3'd4;
localparam TRANSACTION_IN_PROGRESS 	= 3'd5;
localparam TRANSACTION_END 			= 3'd6;

// Current and Next States 
reg [2:0] current_state = 3'b000;
reg [2:0] next_state = 3'b000;

// State Machine Transition Logic
always @(posedge synthesized_clock_4_167Mhz or negedge reset_n)
	 begin
		if (!reset_n)
			begin
				//current_state <= IDLE;	// do reset things
			end
		else if (adc_init_completed == 0)
			begin 
				//current_state <= SETUP;	// do setup things
			end
		else
			begin
				case(current_state)
					RESET: 
						next_state <= IDLE;
					IDLE:
						next_state <= SETUP;
					SETUP:
						next_state <= WAIT_TRANSACTION;
					WAIT_TRANSACTION:
						next_state <= TRANSACTION_BEGIN;
					TRANSACTION_BEGIN: 			
						next_state <= TRANSACTION_IN_PROGRESS;
					TRANSACTION_IN_PROGRESS:
						if(count_cs == 7)
							next_state <= TRANSACTION_END;
						else
							next_state <= TRANSACTION_IN_PROGRESS;
					TRANSACTION_END:
						next_state <= WAIT_TRANSACTION;
					default:
						next_state <= IDLE;
				endcase
			end
    end

// State Machine Output Logic
always @(posedge synthesized_clock_4_167Mhz or negedge reset_n)
begin
	case(current_state)
		IDLE:
			SPI_CS <= 'd0;
		SETUP:
			SPI_CS <= 'd0;
		WAIT_TRANSACTION:
			SPI_CS <= 'd0;
		TRANSACTION_BEGIN: 			
			SPI_CS <= 'd0;
		TRANSACTION_IN_PROGRESS: 	
			SPI_CS <= 'd0;
		TRANSACTION_END:
			SPI_CS <= 'd0;
		default:
			SPI_CS <= 'd0;
	endcase
end

// State machine next transition (for Software & NIOS II)
always@(posedge synthesized_clock_4_167Mhz, negedge reset_n)
begin
	if(!reset_n)
		current_state 			<= RESET;  
	else
		current_state 			<= next_state; 
end
/*
// ADC Init Complete Register - makes sure that the INIT is only performed once 
reg adc_init_completed = 1'b0;

// ADS131A0xReset() Register
reg [31:0] counter = 32'b0;

// CS Register - Start enabling cs_count counting - 7/2/2025
reg count_en = 1'b0;
*/

// State Machine Output logic
/* Behavior: IDLE: 	Checks adc_init_completed. if no, next state will be SETUP. if yes, next state will be TRANSACTION.
				 SETUP:	Runs once. Next state is TRANSACTION
				 TRANSACTION: Checks if adc_ready, if no, STAY in TRANSACTION state. if yes, next state will be IDLE.
*/	
/*
	 always @(*) begin
		  case (current_state)
				// IDLE and default state (000)
				IDLE:				next_state = (adc_init_completed != 1) ? (adc_init ? SETUP : IDLE) : (adc_ready ? TRANSACTION_BEGIN : IDLE);
				
				// Ensures SETUP is only visited once (001)
				SETUP:			next_state = (adc_init_completed == 1) ? TRANSACTION_BEGIN : SETUP; 	
				
				// SPI Transaction - TO BE COMPLETED (010)
				TRANSACTION_BEGIN:	begin
												SPI_CS <= 1'b0;
												next_state = TRANSACTION_IN_PROGRESS;
											end										// No, waiting for adc_ready == 1	
											
				TRANSACTION_IN_PROGRESS: begin 
														if(adc_ready == 1)
															begin
																if(count_cs == 4'd7) begin next_state = TRANSACTION_END; end
																else begin
																		SPI_MOSI <= hello_world_message[count_cs];
																		next_state = TRANSACTION_IN_PROGRESS; 
																	end
															end
														else
															begin 
																next_state = IDLE;
															end
												end	
				// SPI Transaction complete
				TRANSACTION_END: 		begin next_state = IDLE;  SPI_CS <= 1'b1; end
				
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
	*/
endmodule 