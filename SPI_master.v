
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
	output				clock_4_167Mhz_debug,						// 
	output 	 	[4:0] state,											// debug - tracks the current state of SPI)
	output 		[7:0] count_cs,										// debug - keeps track of the 
	output		[4:0]	state_tracker_output,						// debug - keeps track of the state
	input			[31:0]spi_miso_data_input,							// debug - keeps track of the spi_miso_data received
	output		[7:0] spi_miso_data_cc_output
);

// Hard Coded Messages
localparam 	number_of_bits			= 'd32;
reg [31:0] message_part_0555 			= 16'b0000_0101_0101_0101_0000_0000_0000_0000;		// 0x0555
reg [31:0] message_part_0655			= 32'h06550101;												// 0x0655
reg [31:0] message_part_0000			= 32'b0000_0000_0000_0000_0000_0000_0000_0000;		// 0x0000

wire	synthesized_clock_4_167Mhz;					// Main Clock of this Submodule							
wire	[7:0]	count_cs_tracker;							// Tracks the Clock Cycles within each SPI Transmission

// Local Signals
wire 			SPI_SCLK_Temp; 
reg 			SPI_MOSI_Temp 		= 1'd0;
reg 			SPI_CS_Temp 		= 1'd1;							
reg			SPI_RESET_Temp		= 1'd1;
reg 			spi_trigger 		= 1'd1;							// Use this to Control SPI Operation (On/Off)

/* SPI State Definition */
// Define state encoding using localparams
localparam RESET        						= 5'd0;
localparam IDLE        							= 5'd1;
localparam SETUP       							= 5'd2;
localparam WAIT_TRANSACTION					= 5'd3;
localparam WAIT_RESET							= 5'd4;
localparam WAIT_CS								= 5'd5;
localparam TRANSACTION_IN_PROGRESS 			= 5'd6;
localparam TRANSACTION_END 					= 5'd7;
localparam TRANSACTION_IN_PROGRESS_0655 	= 5'd8;
localparam TRANSACTION_END_0655				= 5'd9;
localparam TRANSACTION_IN_PROGRESS_0555 	= 5'd10;
localparam TRANSACTION_END_0555				= 5'd11;

// Current and Next States 
reg [4:0] current_state					 		= 5'd0;
reg [4:0] next_state 							= 5'd0;

// Local Registers and Counters
wire				SPI_SCLK_internal_use;
reg	[4:0]		state_tracker							= 5'd0;
reg	[7:0] 	adc_reset_count						= 8'd0;		// Counter for ADC Reset (Single Use)	
reg	[31:0]	delay_counter_transition_logic	= 32'd0;		// Counter for tracking 50ns delay in Setting Up ADC

/* Clock Synthesizer for SPI with CS Consideration */
spi_sclk_generator spi_sclk_generator_uut(
	 .system_clock(system_clock),							// 50 Mhz system clock
	 .SPI_SCLK(SPI_SCLK_Temp),								// SPI_SCLK for output to ADC
	 .SPI_SCLK_internal_use(SPI_SCLK_internal_use), 
	 .CLOCK_CYCLES(count_cs_tracker),					// SPI_SCLK Clock Cycle Count
	 .state_machine(current_state)						// Stimulus to Start and Stop the Clock
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
			WAIT_TRANSACTION:											// State 4: If spi_trigger == 1 -> next_state = WAIT_TRANSACTION
				begin
					if(spi_trigger)
						next_state	= WAIT_CS;
					else
						next_state	= WAIT_TRANSACTION;
				end
			WAIT_CS:														// State 5: The purpose of this state is to wait for the td (cssc) min 16ns 
				begin
					next_state	= TRANSACTION_IN_PROGRESS;
				end
			TRANSACTION_IN_PROGRESS:								// State 6: Sends 0x0000 to ADC, expects 0xff04
				begin
					if(count_cs_tracker == 'd64) 
						begin
							next_state = TRANSACTION_END;
						end
					else
						next_state = TRANSACTION_IN_PROGRESS;
				end
			TRANSACTION_END:											// State 7: Delay of 50ns
				begin
					if(delay_counter_transition_logic == 250_000)
						next_state = WAIT_TRANSACTION;
					else
						next_state = TRANSACTION_END;
				end
				/*
			TRANSACTION_IN_PROGRESS_0655:							// State 8:
				begin
					if(count_cs_tracker == 32) 
						begin
							next_state = TRANSACTION_END_0655;
						end
					else
						next_state = TRANSACTION_IN_PROGRESS_0655;
				end
			TRANSACTION_END_0655:									// State 9:
				begin
					next_state = TRANSACTION_IN_PROGRESS_0555;
				end
			TRANSACTION_IN_PROGRESS_0555:							// State 10:
				begin
					if(count_cs_tracker == 32) 
						begin
							next_state = TRANSACTION_END_0555;
						end
					else
						next_state = TRANSACTION_IN_PROGRESS_0555;
				end	
			TRANSACTION_END_0555:									// State 11:
				begin
					next_state = WAIT_TRANSACTION;
				end*/
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
			begin
				SPI_CS_Temp <= 1;
				if(delay_counter_transition_logic == 250_000)
					delay_counter_transition_logic <= 0;
				else
					delay_counter_transition_logic <= delay_counter_transition_logic + 'd1;
			end
		TRANSACTION_IN_PROGRESS_0655: 
				SPI_CS_Temp <= 0;
		TRANSACTION_END_0655: 
				SPI_CS_Temp <= 1;
		TRANSACTION_IN_PROGRESS_0555: 
				SPI_CS_Temp <= 0;
		TRANSACTION_END_0555: 
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
clock_synthesizer #(.COUNTER_LIMIT(3))
clock_synthesizer_uut
(
	 .input_clock(system_clock), 										// input clock  - 50 Mhz
	 .clock_pol(synthesized_clock_4_167Mhz)						// output clock - 4.167Mhz
);

/* SPI MOSI Handler */
// This block handles SPI MOSI Signals
reg [7:0]	spi_mosi_bit_count 	= 'd0;
reg 			spi_mosi_byte_count	= 'd1;

always @ (*) //(posedge SPI_SCLK_internal_use)
begin
	if(current_state == TRANSACTION_IN_PROGRESS)
		begin
			case(spi_mosi_byte_count)
				0:
					case(count_cs_tracker)
						0:  SPI_MOSI_Temp = 1;  // preamble (before bit 0)
						1:  SPI_MOSI_Temp = 0;  // bit 0
						2:  SPI_MOSI_Temp = 0;
						3:  SPI_MOSI_Temp = 0;  // bit 1
						4:  SPI_MOSI_Temp = 0;
						5:  SPI_MOSI_Temp = 0;  // bit 2
						6:  SPI_MOSI_Temp = 0;
						7:  SPI_MOSI_Temp = 0;  // bit 3
						8:  SPI_MOSI_Temp = 0;
						9:  SPI_MOSI_Temp = 0;  // bit 4
						10: SPI_MOSI_Temp = 0;
						11: SPI_MOSI_Temp = 0;  // bit 5
						12: SPI_MOSI_Temp = 0;
						13: SPI_MOSI_Temp = 0;  // bit 6
						14: SPI_MOSI_Temp = 0;
						15: SPI_MOSI_Temp = 0;  // bit 7
						16: SPI_MOSI_Temp = 0;
						17: SPI_MOSI_Temp = 0;  // bit 8
						18: SPI_MOSI_Temp = 0;
						19: SPI_MOSI_Temp = 0;  // bit 9
						20: SPI_MOSI_Temp = 0;
						21: SPI_MOSI_Temp = 0;  // bit 10
						22: SPI_MOSI_Temp = 0;
						23: SPI_MOSI_Temp = 0;  // bit 11
						24: SPI_MOSI_Temp = 0;
						25: SPI_MOSI_Temp = 0;  // bit 12
						26: SPI_MOSI_Temp = 0;
						27: SPI_MOSI_Temp = 0;  // bit 13
						28: SPI_MOSI_Temp = 0;
						29: SPI_MOSI_Temp = 0;  // bit 14
						30: SPI_MOSI_Temp = 0;
						31: SPI_MOSI_Temp = 0;  // bit 15
						32: SPI_MOSI_Temp = 0;  // between bit 15 and 16 (optional transition or sync)
						33: SPI_MOSI_Temp = 0;  // bit 16
						34: SPI_MOSI_Temp = 0;
						35: SPI_MOSI_Temp = 0;  // bit 17
						36: SPI_MOSI_Temp = 0;
						37: SPI_MOSI_Temp = 0;  // bit 18
						38: SPI_MOSI_Temp = 0;
						39: SPI_MOSI_Temp = 0;  // bit 19
						40: SPI_MOSI_Temp = 0;
						41: SPI_MOSI_Temp = 0;  // bit 20
						42: SPI_MOSI_Temp = 0;
						43: SPI_MOSI_Temp = 0;  // bit 21
						44: SPI_MOSI_Temp = 0;
						45: SPI_MOSI_Temp = 0;  // bit 22
						46: SPI_MOSI_Temp = 0;
						47: SPI_MOSI_Temp = 0;  // bit 23
						48: SPI_MOSI_Temp = 0;
						49: SPI_MOSI_Temp = 0;  // bit 24
						50: SPI_MOSI_Temp = 0;
						51: SPI_MOSI_Temp = 0;  // bit 25
						52: SPI_MOSI_Temp = 0;
						53: SPI_MOSI_Temp = 0;  // bit 26
						54: SPI_MOSI_Temp = 0;
						55: SPI_MOSI_Temp = 0;  // bit 27
						56: SPI_MOSI_Temp = 0;
						57: SPI_MOSI_Temp = 0;  // bit 28
						58: SPI_MOSI_Temp = 0;
						59: SPI_MOSI_Temp = 0;  // bit 29
						60: SPI_MOSI_Temp = 0;
						61: SPI_MOSI_Temp = 0;  // bit 30
						62: SPI_MOSI_Temp = 0;
						63: SPI_MOSI_Temp = 0;  // bit 31
						64: SPI_MOSI_Temp = 0;  // end pulse or final transition
						default: SPI_MOSI_Temp = 1;
					endcase
		
				1:
					case(count_cs_tracker)
						0:  SPI_MOSI_Temp = 1;  // preamble (before bit 0)
						1:  SPI_MOSI_Temp = 0;  // bit 0
						2:  SPI_MOSI_Temp = 0;
						3:  SPI_MOSI_Temp = 0;  // bit 1
						4:  SPI_MOSI_Temp = 0;
						5:  SPI_MOSI_Temp = 0;  // bit 2
						6:  SPI_MOSI_Temp = 0;
						7:  SPI_MOSI_Temp = 0;  // bit 3
						8:  SPI_MOSI_Temp = 0;
						9:  SPI_MOSI_Temp = 0;  // bit 4
						10: SPI_MOSI_Temp = 0;
						11: SPI_MOSI_Temp = 1;  // bit 5
						12: SPI_MOSI_Temp = 1;
						13: SPI_MOSI_Temp = 1;  // bit 6
						14: SPI_MOSI_Temp = 1;
						15: SPI_MOSI_Temp = 0;  // bit 7
						16: SPI_MOSI_Temp = 0;
						17: SPI_MOSI_Temp = 0;  // bit 8
						18: SPI_MOSI_Temp = 0;
						19: SPI_MOSI_Temp = 1;  // bit 9
						20: SPI_MOSI_Temp = 1;
						21: SPI_MOSI_Temp = 0;  // bit 10
						22: SPI_MOSI_Temp = 0;
						23: SPI_MOSI_Temp = 1;  // bit 11
						24: SPI_MOSI_Temp = 1;
						25: SPI_MOSI_Temp = 0;  // bit 12
						26: SPI_MOSI_Temp = 0;
						27: SPI_MOSI_Temp = 1;  // bit 13
						28: SPI_MOSI_Temp = 1;
						29: SPI_MOSI_Temp = 0;  // bit 14
						30: SPI_MOSI_Temp = 0;
						31: SPI_MOSI_Temp = 1;  // bit 15
						32: SPI_MOSI_Temp = 1;  
						33: SPI_MOSI_Temp = 0;  // bit 16
						34: SPI_MOSI_Temp = 0;
						35: SPI_MOSI_Temp = 0;  // bit 17
						36: SPI_MOSI_Temp = 0;
						37: SPI_MOSI_Temp = 0;  // bit 18
						38: SPI_MOSI_Temp = 0;
						39: SPI_MOSI_Temp = 0;  // bit 19
						40: SPI_MOSI_Temp = 0;
						41: SPI_MOSI_Temp = 0;  // bit 20
						42: SPI_MOSI_Temp = 0;
						43: SPI_MOSI_Temp = 0;  // bit 21
						44: SPI_MOSI_Temp = 0;
						45: SPI_MOSI_Temp = 0;  // bit 22
						46: SPI_MOSI_Temp = 0;
						47: SPI_MOSI_Temp = 0;  // bit 23
						48: SPI_MOSI_Temp = 0;
						49: SPI_MOSI_Temp = 0;  // bit 24
						50: SPI_MOSI_Temp = 0;
						51: SPI_MOSI_Temp = 0;  // bit 25
						52: SPI_MOSI_Temp = 0;
						53: SPI_MOSI_Temp = 0;  // bit 26
						54: SPI_MOSI_Temp = 0;
						55: SPI_MOSI_Temp = 0;  // bit 27
						56: SPI_MOSI_Temp = 0;
						57: SPI_MOSI_Temp = 0;  // bit 28
						58: SPI_MOSI_Temp = 0;
						59: SPI_MOSI_Temp = 0;  // bit 29
						60: SPI_MOSI_Temp = 0;
						61: SPI_MOSI_Temp = 0;  // bit 30
						62: SPI_MOSI_Temp = 0;
						63: SPI_MOSI_Temp = 0;  // bit 31
						64: SPI_MOSI_Temp = 0;  // end pulse or final transition
						default: SPI_MOSI_Temp = 1;
					endcase
			endcase
		end
end

	// Core Signals 
	assign SPI_CS							= SPI_CS_Temp;
	assign SPI_MOSI 						= SPI_MOSI_Temp;
	assign SPI_RESET						= SPI_RESET_Temp;
	
	// Debug by Dennis
	assign clock_4_167Mhz_debug		= SPI_SCLK_internal_use; //synthesized_clock_4_167Mhz;
	assign state 							= current_state;
	assign count_cs 						= count_cs_tracker;
	assign state_tracker_output 		= state_tracker;
	assign spi_miso_data_cc_output 	= spi_mosi_bit_count;
endmodule 
