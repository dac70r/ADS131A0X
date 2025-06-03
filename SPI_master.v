
/* SPI Module */

module SPI_Master 
(
	input 				system_clock,									// System Clock from FPGA - 50Mhz
	input 				reset_n,											// Reset button
	
	output 				SPI_MOSI,										// SPI MOSI
	input 				SPI_MISO,										// SPI MISO
	output				SPI_CS,											//	SPI CS
	output 				SPI_SCLK,										// SPI SCLK
	output 		 		SPI_RESET,										// SPI_RESET - to reset the ADC
	
	/* Not essential signals - can be removed */
	output				clock_4_167Mhz_debug,					
	input					adc_init,										// Trigger signal to init the adc
	input 				adc_ready,										// Trigger signal to send SPI transaction
	output 	 [2:0]	state,											// debug - tracks the current state of SPI
	output 				adc_init_completed,							// debug - tracks the state of spi init (done or not done)
	output 	reg 		adc_transaction_completed,					// debug - tracks the state of spi transaction (yes or no)
	output 		[4:0] count_cs,										// debug - keeps track of the 
	output		[4:0]	state_tracker_output							// debug - keeps track of the state
);

// Hard Coded Messages
localparam number_of_bits	= 4'd8 - 'd1;
reg [7:0] message 			= 8'b1010_1010;
reg [7:0] message_part1 	= 8'b1111_1111;
reg [7:0] message_part2 	= 8'b0000_0100;
reg [7:0] message_part3		= 8'b0000_0000;

wire	synthesized_clock_4_167Mhz;					// Main Clock of this Submodule							
wire	[4:0]	count_cs_tracker;							// Tracks the Clock Cycles within each SPI Transmission

// Local Signals
wire 	SPI_SCLK_Temp; 
reg 	SPI_MOSI_Temp 		= 1'd0;
reg 	SPI_CS_Temp 		= 1'd1;							
reg	SPI_RESET_Temp		= 1'd1;
reg 	spi_trigger 		= 1'd1;							// Use this to Control SPI Operation (On/Off)

/* SPI State Definition */
// Define state encoding using localparams
localparam RESET        				= 3'd0;
localparam IDLE        					= 3'd1;
localparam SETUP       					= 3'd2;
localparam WAIT_TRANSACTION			= 3'd3;
localparam WAIT_RESET					= 3'd4;
localparam WAIT_CS						= 3'd5;
localparam TRANSACTION_IN_PROGRESS 	= 3'd6;
localparam TRANSACTION_END 			= 3'd7;

// Current and Next States 
reg [2:0] current_state					 	= 3'b000;
reg [2:0] next_state 						= 3'b000;

// Local Registers and counters
reg 			adc_init_completed_temp = 1'b0;
reg	[4:0]	state_tracker				= 5'd0;
reg	[7:0] adc_reset_count			= 8'd0;	// Counter for ADC Reset	

/* Clock Synthesizer for SPI with CS Consideration */
spi_sclk_generator spi_sclk_generator_uut(
	 .system_clock(system_clock),					// 50 Mhz system clock
	 .SPI_SCLK(SPI_SCLK_Temp),						// SPI_SCLK for output to ADC
	 .CLOCK_CYCLES(count_cs_tracker),			// SPI_SCLK Clock Cycle Count
	 .state_machine(current_state)				// Stimulus to Start and Stop the Clock
);

assign SPI_SCLK = SPI_SCLK_Temp;

// State Machine Transition Logic - Defines What Conditions Must be Met to Change States
always @(*)
	begin
	case(current_state)
			RESET: 
				begin 
					next_state = IDLE;
				end
			IDLE:
				begin
					next_state = SETUP;
				end
			SETUP:
				begin
					next_state = WAIT_RESET;
				end
			WAIT_RESET:
				begin
					if(adc_reset_count == 20)
						next_state = WAIT_TRANSACTION;
					else
						next_state = WAIT_RESET;
				end
			WAIT_TRANSACTION:
				begin
					if(spi_trigger)//spi_transaction_trigger)
						next_state	= WAIT_CS;
					else
						next_state	= WAIT_TRANSACTION;
				end
			WAIT_CS:	// The purpose of this state is to wait for the td (cssc) min 16ns
				begin
					next_state	= TRANSACTION_IN_PROGRESS;
				end
			TRANSACTION_IN_PROGRESS:
				begin
					if(count_cs_tracker == 16) 
						begin
							next_state = TRANSACTION_END;
						end
					else
						next_state = TRANSACTION_IN_PROGRESS;
				end
			TRANSACTION_END:
				begin
					next_state = WAIT_TRANSACTION;
				end
			default:
				begin
					next_state = IDLE;
				end
		endcase
	end

// State Machine Output Logic
always @(posedge synthesized_clock_4_167Mhz)
begin
	case(current_state)
		IDLE:
				SPI_CS_Temp <= 1;
		SETUP:
				SPI_CS_Temp <= 1;
		WAIT_RESET:
			begin
				adc_reset_count <= adc_reset_count + 1;
				SPI_CS_Temp 	<= 1;
				SPI_RESET_Temp <= 0;
			end
		WAIT_TRANSACTION:
			begin
				SPI_RESET_Temp	<= 1;
				SPI_CS_Temp 	<= 1;
			end
		WAIT_CS:
				SPI_CS_Temp <= 0;
		TRANSACTION_IN_PROGRESS: 
				SPI_CS_Temp <= 0;
		TRANSACTION_END: 
				SPI_CS_Temp <= 1;
		default: 
				SPI_CS_Temp <= 1;
	endcase
end

// State machine next transition
always@(posedge synthesized_clock_4_167Mhz, negedge reset_n)
begin
	if(!reset_n)
		current_state 			<= RESET;  
	else
		current_state 			<= next_state; 
end
	
/* Clock Synthesizer - 4.167Mhz*/
clock_synthesizer #(.COUNTER_LIMIT(6))
clock_synthesizer_uut
(
	 .input_clock(system_clock), 										// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_4_167Mhz)						// output clock - 4.167Mhz
);

/* SPI_MOSI Handler */
// This block handles SPI MOSI Signals
reg [3:0]	spi_mosi_bit_count 	= 'd0;
reg 			spi_mosi_byte_count	= 'd1;

always @ (posedge SPI_SCLK_Temp)
begin
	//if(spi_mosi_byte_count == 'd1) begin spi_mosi_byte_count <= 'd0; end
	case(spi_mosi_byte_count)
		0: begin 
			SPI_MOSI_Temp 			<= message_part3[number_of_bits - spi_mosi_bit_count];
			spi_mosi_bit_count 	<= spi_mosi_bit_count + 'd1;
			if(spi_mosi_bit_count == 'd7)
				begin
					spi_mosi_bit_count 	<= 'd0;
					spi_mosi_byte_count 	<= 'd1;
				end
		end
		1: begin
			SPI_MOSI_Temp 			<= message_part3[number_of_bits - spi_mosi_bit_count];
			spi_mosi_bit_count 	<= spi_mosi_bit_count + 'd1;
			if(spi_mosi_bit_count == 'd7)
				begin
					spi_mosi_bit_count 	<= 'd0;
					spi_mosi_byte_count 	<= 'd0;
				end
		end
		default: begin
			SPI_MOSI_Temp 			<= 'd0;
			spi_mosi_bit_count 	<= 'd0;	
			spi_mosi_byte_count 	<= 'd0;
		end
	endcase
end

	// Core Signals 
	assign SPI_CS						= SPI_CS_Temp;
	assign SPI_MOSI 					= SPI_MOSI_Temp;
	assign SPI_RESET					= SPI_RESET_Temp;
	
	// Debug by Dennis
	assign clock_4_167Mhz_debug	= synthesized_clock_4_167Mhz;
	assign state 						= current_state;
	assign count_cs 					= count_cs_tracker;
	assign adc_init_completed 		= adc_init_completed_temp;
	assign state_tracker_output 	= state_tracker;
	
endmodule 

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
