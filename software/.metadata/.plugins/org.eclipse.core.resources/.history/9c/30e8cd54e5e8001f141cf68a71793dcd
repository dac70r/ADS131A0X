/* 
 * "Small Hello World" example. 
 * 
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example 
 * designs. It requires a STDOUT  device in your system's hardware. 
 *
 * The purpose of this example is to demonstrate the smallest possible Hello 
 * World application, using the Nios II HAL library.  The memory footprint
 * of this hosted application is ~332 bytes by default using the standard 
 * reference design.  For a more fully featured Hello World application
 * example, see the example titled "Hello World".
 *
 * The memory footprint of this example has been reduced by making the
 * following changes to the normal "Hello World" example.
 * Check in the Nios II Software Developers Manual for a more complete 
 * description.
 * 
 * In the SW Application project (small_hello_world):
 *
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 * In System Library project (small_hello_world_syslib):
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 *    - Define the preprocessor option ALT_NO_INSTRUCTION_EMULATION 
 *      This removes software exception handling, which means that you cannot 
 *      run code compiled for Nios II cpu with a hardware multiplier on a core 
 *      without a the multiply unit. Check the Nios II Software Developers 
 *      Manual for more details.
 *
 *  - In the System Library page:
 *    - Set Periodic system timer and Timestamp timer to none
 *      This prevents the automatic inclusion of the timer driver.
 *
 *    - Set Max file descriptors to 4
 *      This reduces the size of the file handle pool.
 *
 *    - Check Main function does not exit
 *    - Uncheck Clean exit (flush buffers)
 *      This removes the unneeded call to exit when main returns, since it
 *      won't.
 *
 *    - Check Don't use C++
 *      This builds without the C++ support code.
 *
 *    - Check Small C library
 *      This uses a reduced functionality C library, which lacks  
 *      support for buffering, file IO, floating point and getch(), etc. 
 *      Check the Nios II Software Developers Manual for a complete list.
 *
 *    - Check Reduced device drivers
 *      This uses reduced functionality drivers if they're available. For the
 *      standard design this means you get polled UART and JTAG UART drivers,
 *      no support for the LCD driver and you lose the ability to program 
 *      CFI compliant flash devices.
 *
 *    - Check Access device drivers directly
 *      This bypasses the device file system to access device drivers directly.
 *      This eliminates the space required for the device file system services.
 *      It also provides a HAL version of libc services that access the drivers
 *      directly, further reducing space. Only a limited number of libc
 *      functions are available in this configuration.
 *
 *    - Use ALT versions of stdio routines:
 *
 *           Function                  Description
 *        ===============  =====================================
 *        alt_printf       Only supports %s, %x, and %c ( < 1 Kbyte)
 *        alt_putstr       Smaller overhead than puts with direct drivers
 *                         Note this function doesn't add a newline.
 *        alt_putchar      Smaller overhead than putchar with direct drivers
 *        alt_getchar      Smaller overhead than getchar with direct drivers
 *
 */

#include "sys/alt_stdio.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_timer_regs.h"
#include "sys/alt_irq.h"
#include "altera_avalon_spi.h"
#include <unistd.h>

// timer ISR - Triggers every period of the timer
void timer_isr(void *context) {
    static int led_state = 0;

    // Toggle LED state
    led_state = !led_state;
    IOWR_ALTERA_AVALON_PIO_DATA(GPIO_BASE, led_state);

    // Clear the timer interrupt
    IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_BASE, 0);

    // Prints the message on Console (UART to Console is established through a USB Blaster)
    // Such that the message appears in synchronous with the LED
    if(led_state==0){
    	alt_putstr("Hello from Nios II!\n");
    }
}

// Initializes and Starts the Timer
void init_timer (void) {
	IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_BASE,
									 ALTERA_AVALON_TIMER_CONTROL_START_MSK |	//starts the timer
									 ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |		//timer will restart after reaching the period value
									 ALTERA_AVALON_TIMER_CONTROL_ITO_MSK);		//timer generates an interrupt when reaching timeout value

	// Register the ISR
	alt_ic_isr_register(TIMER_IRQ_INTERRUPT_CONTROLLER_ID,
						TIMER_IRQ,
						timer_isr,
						NULL,
						NULL);
}

// Initializes the SPI Peripheral
void spi_command (const alt_u8 * write_data, alt_u32 read_length,
		alt_u8 * read_data ) {

	int spi_check = alt_avalon_spi_command(SPI_0_BASE,
							0,					// number of slaves
							sizeof(write_data),		// number of bytes to send to SPI Slave, '0' if only reading
							write_data,			// A pointer to the data buffer that contains the data to be written, 'NULL' if N/A
							read_length,		// The number of bytes to read from the SPI slave, '0' if only writing
							read_data,			// A pointer to the buffer where the received (read) data will be stored, 'NULL' if N/A
							0					// Special control flags for the SPI command
							);
	if(spi_check == 0){
		alt_putstr("SPI Transmit Error!\n");
	}
}

// Delay function
void delay_ms(int milliseconds) {
    usleep(milliseconds * 1000);  // Convert to microseconds
}


int main()
{
	alt_u32 status;
	alt_u8 tx_data[] = {0xA5, 0x5A};
	alt_u8 rx_data[2];

	//init_timer();
	int spi_check = -1;

	/* Event loop never exits. */
	while (1){
		spi_check = alt_avalon_spi_command(SPI_0_BASE,
											0,					// number of slaves
											sizeof(tx_data),		// number of bytes to send to SPI Slave, '0' if only reading
											tx_data,			// A pointer to the data buffer that contains the data to be written, 'NULL' if N/A
											0,		// The number of bytes to read from the SPI slave, '0' if only writing
											NULL,			// A pointer to the buffer where the received (read) data will be stored, 'NULL' if N/A
											0					// Special control flags for the SPI command
											);

		if(spi_check == 0){
			alt_putstr("SPI Ok!\n");
			}
		else
			alt_putstr("SPI Fault!\n");
		}


		delay_ms(1000);
  return 0;
}

// This is incorrect, counting 250,000,00 will take more than 0.5s because this is not RTL
// clk is 50,000,000
// so every 0.5 seconds the counter will be overfilled
/*
if(count<=25000000){
	  count++;
}
else{
	  IOWR_ALTERA_AVALON_PIO_DATA(GPIO_BASE, ~(delay));
	  alt_putstr("Hello from Nios II!\n");
	  delay = (delay + 1)%2;
	  count = 0;
}*/
