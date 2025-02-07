
/* SPI Clock Generator with CS Consideration */

module spi_sclk_generator (
    input  		clk,      // System clock - 50Mhz
    input  		cs,       // Chip Select (Active LOW)
    output reg sclk      // SPI Clock output
);

localparam counter_limit = 32'd6;   // Clock divider (System Clock / DIV = SCLK frequency)
reg [31:0] counter = 0; // Counter for clock division

 always @(posedge clk) begin
	  if (cs) begin
			sclk <= 0;  // Stop clock toggling when CS is HIGH
			counter <= 0; // Reset counter
	  end 
	  
	  else 
		begin
			if (counter == counter_limit) 
				begin
					sclk <= ~sclk; // Toggle SCLK
					counter <= 0;
				end 
			else 
			begin
				 counter <= counter + 1;
			end
		end
 end
 
endmodule