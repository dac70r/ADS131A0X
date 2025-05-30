
/* SPI Clock Generator with CS Consideration */

module spi_sclk_generator (
	 input				system_clock,
    input  				CS,       							// Stimulus to Start and Stop the Clock
	 output 				SPI_SCLK,
	 output		[3:0]	CLOCK_CYCLES,
	 output				spi_transaction_done
);
reg [31:0] 	count 	= 32'd0;
reg [3:0]	CLOCK_CYCLES_Temp = 'd0;
reg			spi_transaction_done_Temp = 'd0;
reg SPI_SCLK_Temp			= 1'd1;

 /* Counts the number of cycles of SCLK */
	always @ (posedge system_clock)
	begin 
		if(CS==0)
			begin
				if(CLOCK_CYCLES_Temp <'d8)
					begin
						CLOCK_CYCLES_Temp <= CLOCK_CYCLES_Temp + 'd1;
					end
				else
					CLOCK_CYCLES_Temp <= 'd0;
			end
		else
			SPI_SCLK_Temp <= 1'd1;
			
	end
 
 assign SPI_SCLK = (CS == 0 && CLOCK_CYCLES_Temp <8) ? system_clock : 0;
 assign CLOCK_CYCLES = CLOCK_CYCLES_Temp;
 assign spi_transaction_done = spi_transaction_done_Temp;
endmodule