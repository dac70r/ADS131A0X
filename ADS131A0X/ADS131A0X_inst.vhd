	component ADS131A0X is
		port (
			clk_clk                         : in  std_logic                    := 'X'; -- clk
			gpio_external_connection_export : out std_logic_vector(1 downto 0);        -- export
			reset_reset_n                   : in  std_logic                    := 'X'; -- reset_n
			spi_external_MISO               : in  std_logic                    := 'X'; -- MISO
			spi_external_MOSI               : out std_logic;                           -- MOSI
			spi_external_SCLK               : out std_logic;                           -- SCLK
			spi_external_SS_n               : out std_logic                            -- SS_n
		);
	end component ADS131A0X;

	u0 : component ADS131A0X
		port map (
			clk_clk                         => CONNECTED_TO_clk_clk,                         --                      clk.clk
			gpio_external_connection_export => CONNECTED_TO_gpio_external_connection_export, -- gpio_external_connection.export
			reset_reset_n                   => CONNECTED_TO_reset_reset_n,                   --                    reset.reset_n
			spi_external_MISO               => CONNECTED_TO_spi_external_MISO,               --             spi_external.MISO
			spi_external_MOSI               => CONNECTED_TO_spi_external_MOSI,               --                         .MOSI
			spi_external_SCLK               => CONNECTED_TO_spi_external_SCLK,               --                         .SCLK
			spi_external_SS_n               => CONNECTED_TO_spi_external_SS_n                --                         .SS_n
		);

