#include "hardware/spi.h"
#include "hardware/gpio.h"
#include "pico/stdlib.h"
#include <stdio.h>
#include <pico/stdlib.h>
#include "screen_data.h"

#define NUM_TASKS 1

// SPI Defines
// We are going to use SPI 0, and allocate it to the following GPIO pins
// Pins can be changed, see the GPIO function select table in the datasheet for information on GPIO assignments
#define SPI_PORT spi0
#define PIN_MISO 4
#define PIN_CS   5
#define PIN_SCK  2
#define PIN_MOSI 3

// note for myself, when sending spi commands, we should use 2 bytes of data to send
// save myself the trouble for later

typedef struct _task{
	int state; 		//Task's current state
	unsigned long period; 		//Task period
	unsigned long elapsedTime; 	//Time elapsed since last task tick
	int (*TickFct)(int); 		//Task tick function
} task;

// buffer for spi data first one is original data just to keep for now
// padding the last two bits with 0s
// 1 -> white
// 0 -> black
uint16_t nothing_buf[17][2] = { // left side is letters and the colon, while the right side is x or o
     {0xF800, 0x4200},
     {0x8440, 0x2400},
     {0x8400, 0x1800},
     {0x8400, 0x1800},
     {0x8440, 0x2400},
     {0xF800, 0x4200}, // This and above creates D : X
     {0x0000, 0x0000}, // This and two below are empty space
     {0x0000, 0x0000}, // empty
     {0x0000, 0x0000}, // empty
     {0x2000, 0x4200}, 
     {0x2040, 0x2400},
     {0x7000, 0x1800},
     {0x2000, 0x1800},
     {0x2040, 0x2400},
     {0x2000, 0x4200},
     {0x1800, 0x0000}, // this and above creates t : X
     {0x0000, 0x000}   // empty
};

const unsigned long TASK_PERIOD = 1000;
const unsigned long GCD_PERIOD = TASK_PERIOD;

task tasks[NUM_TASKS];

enum spriteStates{D_off_T_off, D_on_T_off, D_off_T_on, D_on_T_on};

uint8_t spi_mask1;
uint8_t spi_mask2;
uint16_t curr;

int screenTick(int state){

    switch(state){ // transitions
        case D_off_T_off:
            // if (gpio_get(19)){
            //     state = D_on_T_off;
            // }
            // else if (gpio_get(20)){
            //     state = D_off_T_on;
            // }
            break;

        case D_on_T_off:
            if (gpio_get(20)){
                state = D_on_T_on;
            }
            else if (gpio_get(19)){
                state = D_off_T_off;
            }
            break;

        case D_off_T_on:
            if (gpio_get(20)){
                state = D_off_T_off;
            }
            else if (gpio_get(19)){
                state = D_on_T_off;
            }
            break;

        case D_on_T_on:
            if (gpio_get(20)){
                state = D_on_T_off;
            }
            else if (gpio_get(19)){
                state = D_off_T_on;
            }
            break;
    }

    switch(state){ // actions
        case D_off_T_off:
            // printf("starting the spi send\n");
            // gpio_put(PIN_CS, 0);
            // for (int i = 0; i < 17; i++){ // row
            //     for (int j = 0; j < 2; j++){ // column
            //         //spi_write16_blocking(SPI_PORT, &nothing_buf[i][j], 1);
            //         // spi_mask1  = nothing_buf[i][j] >> 8; // top half
            //         // spi_mask2  = nothing_buf[i][j] & 0x00FF; // bottom half

            //         spi_mask1 = 0xFFFF;
            //         spi_mask2 = 0xFFFF;
            //         spi_write_blocking(SPI_PORT, &spi_mask1, 1);
            //         spi_write_blocking(SPI_PORT, &spi_mask2, 1);
            //     }
            // }
            // gpio_put(PIN_CS, 1);
            // printf("finished the sending :D\n");
            break;

        case D_on_T_off:
            break;

        case D_off_T_on:
            break;

        case D_on_T_on:
            break;
    }
    return state;
}

bool TimerScheduler(){
    for ( unsigned int i = 0; i < NUM_TASKS; i++ ) {                   // Iterate through each task in the task array
		if ( tasks[i].elapsedTime == tasks[i].period ) {           // Check if the task is ready to tick
			tasks[i].state = tasks[i].TickFct(tasks[i].state); // Tick and set the next state for this task
			tasks[i].elapsedTime = 0;                          // Reset the elapsed time for the next tick
		}
		tasks[i].elapsedTime += GCD_PERIOD;                        // Increment the elapsed time by GCD_PERIOD
	}
    return true;
}

int main()
{
    // SPI initialisation. This example will use SPI at 1MHz.
    spi_init(SPI_PORT, 1000*1000);
    spi_set_format(SPI_PORT, 16, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);
    gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
    gpio_set_function(PIN_CS,   GPIO_FUNC_SIO);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    
    // Chip select is active-low, so we'll initialise it to a driven-high state
    gpio_set_dir(PIN_CS, GPIO_OUT);
    gpio_put(PIN_CS, 1);

    gpio_init(19); // distoertion button
    gpio_init(20); // tremolo button

    gpio_set_dir(19, GPIO_IN);
    gpio_set_dir(20, GPIO_IN);

    stdio_init_all();

    unsigned char i = 0;
    tasks[i].state = D_off_T_off;
    tasks[i].period = TASK_PERIOD;
    tasks[i].elapsedTime = tasks[i].period;
    tasks[i].TickFct = &screenTick;

    struct repeating_timer timer;
    add_repeating_timer_ms(-1000, TimerScheduler, NULL, &timer);

    gpio_put(PIN_CS, 0);
        for (int i = 0; i < 17; i++) {
            for (int j = 0; j < 2; j++) {
                curr = nothing_buf[i][j];
                spi_write16_blocking(SPI_PORT, &curr, 1);
            }
        }
        gpio_put(PIN_CS, 1);
        sleep_ms(100);  // refresh 10x per second, plenty for a static image

    printf("starting pico work and stuff :D\n");

    while (true) {
        gpio_put(PIN_CS, 0);
        for (int i = 0; i < 17; i++) {
            for (int j = 0; j < 2; j++) {
                curr = nothing_buf[i][j];
                spi_write16_blocking(SPI_PORT, &curr, 1);
            }
        }
        gpio_put(PIN_CS, 1);
        sleep_ms(100);  // refresh 10x per second, plenty for a static image
    }
}