
#include "include/spi_display.h"
#include "include/demo_world.h"

#include "lv_conf.h"
#include "include/lvgl/demos/widgets/lv_demo_widgets.h"

#include <include/lvgl/lvgl.h>

#include <stdio.h>
#include <pico/stdlib.h>
#include <pico/binary_info.h>
#include <pico/time.h>
#include <hardware/spi.h>

/*Return the elapsed milliseconds since startup.
 *It needs to be implemented by the user*/
uint32_t get_millis(void) {
    return to_ms_since_boot(get_absolute_time());
}

static uint8_t buffer[OLEDRGB_WIDTH * OLEDRGB_HEIGHT / 10];

/*Copy the rendered image to the screen. */
void flush_cb_direct(lv_display_t * disp, const lv_area_t * area, uint8_t * px_buf) {
    screen_display::SPIDisplay *spi_display = reinterpret_cast<screen_display::SPIDisplay *>(lv_display_get_user_data(disp));
	uint32_t i = 0;
	for (uint32_t y = area->y1; y <= area->y2; y++) {
		for(uint32_t x = area->x1; x <= area->x2; x++) {
			uint32_t px_buf_idx = x * 2 + y * (spi_display->getWidth() * 2);
		    buffer[i++] =  (px_buf[px_buf_idx+1] & 0xE0) | ((px_buf[px_buf_idx+1] & 0x7) << 2) | (px_buf[px_buf_idx] & 0x1f) >> 3;
		}
	}

    /*Show the rendered image on the display*/
    spi_display->drawBitmap(area->x1, area->y1, area->x2, area->y2, buffer);

    /*Indicate that the buffer is available.
     *If DMA were used, call in the DMA complete interrupt*/
    lv_display_flush_ready(disp);
}

/*It needs to be implemented by the user*/
void flush_cb_partial(lv_display_t * disp, const lv_area_t * area, uint8_t * px_buf) {
	uint32_t size = (area->x2 - area->x1 + 1) * (area->y2 - area->y1 + 1);

    /*Show the rendered image on the display*/
    screen_display::SPIDisplay *spi_display = reinterpret_cast<screen_display::SPIDisplay *>(lv_display_get_user_data(disp));
    spi_display->drawBitmap(2 * area->x1, area->y1, 2 * area->x2+1, area->y2, px_buf);

    printf("flushing :D \n");

    /*Indicate that the buffer is available.
     *If DMA were used, call in the DMA complete interrupt*/
    lv_display_flush_ready(disp);
}

int main(void) {
    // Init drivers
	stdio_init_all();

    char c = getchar(); // holds up the pico so i can actually use the serial monitor

    printf("starting initialization dblakfjio \n");

    /*                                       w,   h, baudrate, data_cmd (acts as a normal gpio pin i guess i dont make the rules) */
    screen_display::SPIDisplay spi_display(480, 272, 10000000, 9);

    printf("constructed the SPI code ....... \n");

	spi_display.begin();

    printf("udsed the begin function for the spi display yaaay \n");

	spi_display.clear();

    printf("starting program hopefully :D \n");

    screen_display::demo_world app(&spi_display, flush_cb_partial, get_millis);

    bool d = gpio_get(9);

    if (d) {printf("data cmd is on\n");}
    else {printf("data cmd is off\n");}

    printf("created the app, should run app now \n");

    app.run();

    printf("app is off i guess \n");
}