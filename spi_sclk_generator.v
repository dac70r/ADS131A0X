
/* SPI Clock Generator with CS Consideration */
/*

	Working Principle: We use the State Machine to activate the counter mechanism in order to generate the SPI_SCLK

*/
module spi_sclk_generator (
	 input				system_clock,
	 output 				SPI_SCLK,
	 output		[4:0]	CLOCK_CYCLES,
	 input		[2:0]	state_machine					// State Machine
);


// This Block is triggered by the State Machine (TRANSACTION_IN_PROGRESS) State to generate SPI_SCLK
// If NOT, SPI_SCLK will be deasserted 
localparam TRANSACTION_IN_PROGRESS 		= 3'd6;
reg [31:0] 	spi_sclk_counter 				= 32'b0;
reg 			spi_sclk_clock_state 		= 1'b1;
reg [4:0]	CLOCK_CYCLES_Temp 			= 5'd0;
reg			spi_transaction_done_Temp	= 1'd0;

always @ (posedge system_clock)
begin
	if(state_machine == TRANSACTION_IN_PROGRESS) 
		begin
			if(spi_sclk_counter == 6) 		// Change the number to modify the frequency of SPI_SCLK
				begin 
					spi_sclk_counter 		<= 32'd0; 
					spi_sclk_clock_state <= ~spi_sclk_clock_state;
					CLOCK_CYCLES_Temp		<= CLOCK_CYCLES_Temp + 1'd1;
				end
			else
				begin spi_sclk_counter <= spi_sclk_counter + 1; end 
		end
	else 
		begin
			spi_sclk_counter 	<= 32'd0; 
			spi_sclk_clock_state <= 1'd0;
			CLOCK_CYCLES_Temp	<= 'd0;
		end
end
 
assign SPI_SCLK = spi_sclk_clock_state;
assign CLOCK_CYCLES = CLOCK_CYCLES_Temp;

 
endmodule


// This block keeps track of the number of clock cycles of SPI_SCLK 
// Clock: spi_sclk_clock_state (4.167Mhz)
//reg [3:0]	CLOCK_CYCLES_Temp = 'd0;
//reg			spi_transaction_done_Temp = 'd0;

/*
always @ (posedge spi_sclk_clock_state)	
	begin 
		if(CLOCK_CYCLES_Temp <'d8)
				CLOCK_CYCLES_Temp <= CLOCK_CYCLES_Temp + 'd1;
		else
			CLOCK_CYCLES_Temp <= 'd0;		// resets
	end

assign CLOCK_CYCLES = CLOCK_CYCLES_Temp;
*/

 //assign SPI_SCLK = (CS == 0 && CLOCK_CYCLES_Temp <8) ? system_clock : 0;
 //assign spi_transaction_done = spi_transaction_done_Temp;