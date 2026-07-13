#include "hardware/spi.h"
#include "hardware/gpio.h"
#include "pico/stdlib.h"
#include <stdio.h>
#include <pico/stdlib.h>

#ifndef SCREEN_HELPER_H
#define SCREEN_HELPER_H

#define COLUMN_COUNT 17
#define ROW_COUNT 2

void setupFrame(){

}

void changeFrame(){

}

void sendImage(const char CS_PIN, spi_inst_t* PORT_SPI, uint16_t* curr_frame){
    uint16_t curr; // using the spi functions are kinda jank or im dumb, or both
    gpio_put(CS_PIN, 0);
    for (int i = 0; i < COLUMN_COUNT; i++) {
        for (int j = 0; j < ROW_COUNT; j++) {
            curr = curr_frame[i][j];
            spi_write16_blocking(PORT_SPI, &curr, 1);
        }
    }
    gpio_put(CS_PIN, 1);
    //sleep_ms(100);  // stalling just in case
}



#endif 