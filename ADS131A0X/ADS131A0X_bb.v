
module ADS131A0X (
	clk_clk,
	gpio_external_connection_export,
	reset_reset_n,
	spi_external_MISO,
	spi_external_MOSI,
	spi_external_SCLK,
	spi_external_SS_n);	

	input		clk_clk;
	output	[1:0]	gpio_external_connection_export;
	input		reset_reset_n;
	input		spi_external_MISO;
	output		spi_external_MOSI;
	output		spi_external_SCLK;
	output		spi_external_SS_n;
endmodule
