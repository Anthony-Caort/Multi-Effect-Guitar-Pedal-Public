#include "demo_world.h"
#include "include/lvgl/lvgl.h"

namespace screen_display{

    demo_world::demo_world(SPIDisplay* spi_disp, 
                           lv_display_flush_cb_t fcallback, 
                           lv_tick_get_cb_t tcallback) :
        ScreenApp(spi_disp, fcallback, tcallback){
            init();
        }
            
    void demo_world::init() { // copied from the lvgl getting started example
        /*Change the active screen's background color*/
        lv_obj_set_style_bg_color(lv_screen_active(), lv_color_hex(0x003a57), LV_PART_MAIN);
        /*Create a white label, set its text and align it to the center*/
        lv_obj_t * label = lv_label_create(lv_screen_active());
        lv_label_set_text(label, "Hello world");
        lv_obj_set_style_text_color(lv_screen_active(), lv_color_hex(0xffffff), LV_PART_MAIN);
        lv_obj_align(label, LV_ALIGN_CENTER, 0, 0);
    }

    uint32_t demo_world::run() {
        init();
        return loop();
    }
}