#ifndef _DEMO_WORLD_H
#define _DEMO_WORLD_H

#include "screen_app.h"

namespace screen_display {

    class demo_world : public ScreenApp {
        public:
            demo_world(SPIDisplay* spi_disp, lv_display_flush_cb_t fcallback, lv_tick_get_cb_t tcallback);

            void init();

            uint32_t run();
    };

}

#endif