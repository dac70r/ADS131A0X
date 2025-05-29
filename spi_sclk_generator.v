
/* SPI Clock Generator with CS Consideration */

module spi_sclk_generator (
    input  				CLK_4_167,      							// System clock - 4.167Mhz
    input  				SPI_CS,       							// Chip Select (Active LOW)
	 output 				SPI_SCLK,
	 output reg [3:0] count_cs = 4'b0000				// Counter for data of size 8
);

reg SPI_SCLK_Temp = 1'b0;

/* Generates the SPI_SCLK from a regular clock */ 
 always @ (*)
 begin
	if(SPI_CS == 0)
		SPI_SCLK_Temp = CLK_4_167;
	else
		SPI_SCLK_Temp = 0;
 end
 
 /* Counts the number of cycles of SCLK */
 /*
 always @ (posedge CLK_4_167)
 begin
		if(SPI_CS == 1)
			count_cs <= 4'd0;
		else begin
				if(count_cs == 7) 
					count_cs <= 1'b0; 
				else
					count_cs <= count_cs + 1'b1;  
			end
 end
 */
 //assign sclk = (cs != 1) ? clk : 0;
 
 assign SPI_SCLK = SPI_SCLK_Temp;
 
endmodule