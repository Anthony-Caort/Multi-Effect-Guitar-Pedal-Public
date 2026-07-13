#ifndef _SCREEN_APP_H_
#define _SCREEN_APP_H_

#include "lv_conf.h"
#include <lvgl/lvgl.h>

namespace screen_display{

    class SPIDisplay;

    class ScreenApp{ // will be the main abstract 
        public:
            // initialization function
            ScreenApp(SPIDisplay* spi_disp, lv_display_flush_cb_t fcallback, lv_tick_get_cb_t tcallback);
            virtual uint32_t run() = 0;

        private:
            SPIDisplay* spi_display;
            uint8_t* framebuffer;
            lv_display_t* display;
            lv_display_flush_cb_t flush_callback;
            lv_tick_get_cb_t tick_callback;
            bool running;

        protected:
            uint32_t loop();
    };
}

#endif