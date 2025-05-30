
/* SPI Module */

module SPI_Master 
(
	input 				system_clock,									// System Clock from FPGA - 50Mhz
	input 				reset_n,											// Reset button
	
	output 	reg		SPI_MOSI,										// SPI MOSI
	input 				SPI_MISO,										// SPI MISO
	output				SPI_CS,											//	SPI CS
	output 				SPI_SCLK,										// SPI SCLK
	output 	reg 		SPI_RESET,										// SPI_RESET - to reset the ADC
	
	/* Not essential signals - can be removed */
	input					adc_init,										// Trigger signal to init the adc
	input 				adc_ready,										// Trigger signal to send SPI transaction
	output 	 [2:0]	state,											// debug - tracks the current state of SPI
	output 				adc_init_completed,							// debug - tracks the state of spi init (done or not done)
	output 	reg 		adc_transaction_completed,					// debug - tracks the state of spi transaction (yes or no)
	output 		[3:0] count_cs,										// debug - keeps track of the 
	output		[4:0]	state_tracker_output							// debug - keeps track of the state
);

wire	synthesized_clock_4_167Mhz;
reg	stimulus_temp = 1'b0;
wire	[3:0]	count_cs_tracker;
wire	spi_transaction_done;
reg SPI_CS_Temp = 'd1;

clock_synthesizer #(.COUNTER_LIMIT(6))
clock_synthesizer_uut
(
	 .input_clock(system_clock), 										// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_4_167Mhz)						// output clock - 4.167Mhz
);

/* Clock Synthesizer for SPI with CS Consideration */
spi_sclk_generator spi_sclk_generator_uut(
	 .system_clock(synthesized_clock_4_167Mhz),
    .CS(SPI_CS),       							// Stimulus to Start and Stop the Clock
	 .SPI_SCLK(SPI_SCLK),
	 .CLOCK_CYCLES(count_cs_tracker),
	 .spi_transaction_done(spi_transaction_done)
);

/* SPI State Definition */
// Define state encoding using localparams
localparam RESET        				= 3'd0;
localparam IDLE        					= 3'd1;
localparam SETUP       					= 3'd2;
localparam WAIT_TRANSACTION			= 3'd3;
//localparam TRANSACTION_BEGIN			= 3'd4;
localparam TRANSACTION_IN_PROGRESS 	= 3'd5;
localparam TRANSACTION_END 			= 3'd6;

// Current and Next States 
reg [2:0] current_state = 3'b000;
reg [2:0] next_state = 3'b000;

// Local Registers
reg 			adc_init_completed_temp = 1'b0;
reg	[4:0]	state_tracker				= 5'd0;


// State Machine Transition Logic - Defines What Conditions Must be Met to Change States
always @(posedge synthesized_clock_4_167Mhz or negedge reset_n)
	 begin
		if (!reset_n)
			begin
				//current_state <= IDLE;	// do reset things
				state_tracker <= 5'd0;
			end
		else if (adc_init_completed_temp == 1'b0)
			begin 
				//current_state <= SETUP;	// do setup things
				adc_init_completed_temp	<= 1'b1;
				state_tracker <= 5'd1;
			end
		else
			begin
				case(current_state)
					RESET: 
						begin 
							next_state <= IDLE;
							state_tracker <= 5'd2;
						end
					IDLE:
						begin
							state_tracker <= 5'd3;
							next_state <= SETUP;
						end
					SETUP:
						begin
							state_tracker <= 5'd4;
							next_state <= WAIT_TRANSACTION;
						end
					WAIT_TRANSACTION:
						begin
							next_state <= TRANSACTION_IN_PROGRESS;
						end
					TRANSACTION_IN_PROGRESS:
						begin
							state_tracker <= 5'd7;
							if(count_cs_tracker == 'd8) 
								begin
									next_state <= TRANSACTION_END;
								end
							else
								next_state <= TRANSACTION_IN_PROGRESS;
						end
					TRANSACTION_END:
						begin
							state_tracker <= 5'd8;
							next_state <= WAIT_TRANSACTION;
						end
					default:
						begin
							state_tracker <= 5'd9;
							next_state <= IDLE;
						end
				endcase
			end
    end

// State Machine Output Logic
always @(posedge synthesized_clock_4_167Mhz or negedge reset_n)
begin
	case(current_state)
		IDLE:
			begin
				SPI_CS_Temp <= 1;
			end
		SETUP:
			begin
				SPI_CS_Temp <= 1;
			end
		WAIT_TRANSACTION: 
			begin
				SPI_CS_Temp <= 1;
			end
		TRANSACTION_IN_PROGRESS: 
			begin
				SPI_CS_Temp <= 0;
			end
		TRANSACTION_END: 
			begin
				SPI_CS_Temp <= 1;
			end
		default: 
			begin
				SPI_CS_Temp <= 1;
			end
	endcase
end

// State machine next transition (for Software & NIOS II)
always@(posedge system_clock, negedge reset_n)
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
*/
	
	// Debug by Dennis
	assign SPI_CS = SPI_CS_Temp;
	assign state = current_state;
	assign count_cs = count_cs_tracker;
	assign adc_init_completed = adc_init_completed_temp;
	assign state_tracker_output = state_tracker;
	
endmodule 