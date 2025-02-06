
/* Clock Synthesizer Module */
// The default synthesized clock is 1hz

module clock_synthesizer #(parameter COUNTER_LIMIT = 24_999_999)
(
    input 				input_clock, 			// input clock  - 50 Mhz
	 output 				clock_pol				// output clock - 4.167Mhz 
);

// Change this parameter to achieve desired SPI clock
// eg. 50Mhz/ (6*2) = 4.167Mhz
// localparam [31:0] counter_limit = 6;

reg [31:0] counter = 32'b0;
reg clock_state = 1'b0;

always @ (posedge input_clock)
begin 
	if(counter == COUNTER_LIMIT) begin counter <= 0; clock_state <= ~clock_state; end
	else
		begin counter <= counter + 1; end

end

assign clock_pol = clock_state;

endmodule