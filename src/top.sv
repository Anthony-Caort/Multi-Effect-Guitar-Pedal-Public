`include "src/display/dp_buffer.sv"
`include "src/display/lcd_bare.sv"
`include "src/display/spi_reciever.sv"

`include "src/audio/audio_input.sv"
`include "src/audio/axis_i2s2.sv"
`include "src/audio/ecppll.sv"
`include "src/audio/distortion_mod.sv"
`include "src/audio/tail_end.sv"
`include "src/audio/tremolo_mod.sv"
`include "src/audio/lfo_triangle.sv"
`include "src/audio/button_registers.sv"

module top (
    // ------------------------------- iCESugar-Pro 25MHz onboard clock (Pin P6)
    input  wire        clk_25m,       

    // ------------------------------- RGB LCD Interface (480x272)
    output wire        lcd_clk,
    output wire        lcd_de,
    output wire [4:0]  lcd_r,
    output wire [5:0]  lcd_g,
    output wire [4:0]  lcd_b,

    // ------------------------------- SPI Interface 
    input wire         sclk,
    input wire         pico,
    input wire         cs,

    //-------------------------------- Audio Interface

    output wire tx_mclk, // DA MCLK
    output wire tx_lrck, // DA LRCK
    output wire tx_sclk, // DA SCLK
    output wire tx_data, // DA SDIN
    output wire rx_mclk, // AD MCLK
    output wire rx_lrck, // AD LRCK
    output wire rx_sclk, // AD SCLK
    input  wire rx_data, // AD SDOUT

    input  wire [3:0] depth_switches,
    input  wire distortion_button,
    input  wire tremolo_button
);

    /*
----------------------------------------------------------------------------
        LCD related modules
----------------------------------------------------------------------------
    */

    assign lcd_clk = clk_25m;

    logic resetLCD = 0;

    logic [9:0]  pixel_address;
    logic        pixel;
    logic        data_stream;

    logic        spi_we;
    logic [9:0]  spi_waddr;

    spi spiReciever(
        // inputs
        .sclk(sclk),
        .cs(cs),
        .pico(pico),

        // outputs
        .data_stream(data_stream), // goes into wdata
        .we(spi_we),
        .waddr(spi_waddr)
    );

    dp_buffer dp1(
        .clk(clk_25m),

        //write
        .we(spi_we),
        .waddr(spi_waddr),
        .wdata(data_stream),

        //read
        .raddr(pixel_address),
        .rdata(pixel)
    );

    lcd_bare display(
        .rst(resetLCD),
        .pclk(clk_25m),
        .LCD_DE(lcd_de),

        .pixel_address(pixel_address),
        .pixel(pixel),

        .LCD_B(lcd_b),
        .LCD_G(lcd_g),
        .LCD_R(lcd_r)
    );


    /*
------------------------------------------------------------------------------
        Audio related modules
------------------------------------------------------------------------------
    */

    wire axis_clk;

    wire [31:0] axis_tx_data;
    wire axis_tx_valid;
    wire axis_tx_ready;
    wire axis_tx_last;
    
    wire [31:0] axis_rx_data;
    wire axis_rx_valid;
    wire axis_rx_ready;
    wire axis_rx_last;

    /*
        Huge main idea on how the audio processing works is through a digital daisy chain.
        The controller works in isolation but also kinda sets up the chain and ends the chain?
        If it works it works
    */

    logic locked_axis;

    pll_2 axis_clk_m (
        .clkin(clk_25m),
        .clkout0(axis_clk),
        .locked(locked_axis)
    );

    wire resetn;
    
    // this should make at least one cycle where everything resets
    assign resetn = locked_axis; // = (reset == 0) ? 1'b0 : 1'b1;

    // rx -> distortion 
    wire [31:0] distortion_m_data;
    wire        distortion_m_valid;
    wire        distortion_m_ready;
    wire        distortion_m_last;

    wire        distortion_enable;

    // distortion -> tremolo
    wire [31:0] tremolo_m_data;
    wire        tremolo_m_valid;
    wire        tremolo_m_ready;
    wire        tremolo_m_last;

    wire        tremolo_enable;

    /* 
        Even though the controller is at the very start, it is the only module that will
        change the output for the tx variables wired at the very start of the top module,
        the daisy chain of effects will only effect the string of bits the tx wires read
        from. :D 
    */

    button_registers distortion_register(
        .clk(clk_25m),
        .button_press(distortion_button),
        .enable(distortion_enable)
    );

    button_registers tremolo_register(
        .clk(clk_25m),
        .button_press(tremolo_button),
        .enable(tremolo_enable)
    );

    axis_i2s2 m_i2s2 (  // i2s2 controller
        .axis_clk(axis_clk),
        .axis_resetn(resetn),
    
        .tx_axis_s_data(axis_tx_data),
        .tx_axis_s_valid(axis_tx_valid),
        .tx_axis_s_ready(axis_tx_ready),
        .tx_axis_s_last(axis_tx_last),
    
        .rx_axis_m_data(axis_rx_data),
        .rx_axis_m_valid(axis_rx_valid),
        .rx_axis_m_ready(axis_rx_ready),
        .rx_axis_m_last(axis_rx_last),
        
        .tx_mclk(tx_mclk),
        .tx_lrck(tx_lrck),
        .tx_sclk(tx_sclk),
        .tx_sdout(tx_data),
        .rx_mclk(rx_mclk),
        .rx_lrck(rx_lrck),
        .rx_sclk(rx_sclk),
        .rx_sdin(rx_data)
    );

    distortion_mod dist_controller( // distortion effect
        .clk(axis_clk),
        .d_enable(distortion_enable),
        .resetn(resetn),

        .s_data(axis_rx_data),
        .s_valid(axis_rx_valid),
        .s_ready(axis_rx_ready),
        .s_last(axis_rx_last),

        .m_data(distortion_m_data),
        .m_valid(distortion_m_valid),
        .m_ready(distortion_m_ready),
        .m_last(distortion_m_last)
    );

    wire [3:0] temp_depth = 4'd10;

    tremolo_mod tremolo_controller(
        .clk(axis_clk),
        .t_enable(tremolo_enable),
        .resetn(resetn),

        .depth(temp_depth),

        .s_data(distortion_m_data),
        .s_valid(distortion_m_valid),
        .s_ready(distortion_m_ready),
        .s_last(distortion_m_last),

        .m_data(tremolo_m_data),
        .m_valid(tremolo_m_valid),
        .m_ready(tremolo_m_ready),
        .m_last(tremolo_m_last)
    );

    // I kept forgetting to reassign values so sound can get through the DAC so this module does that for me
    // tail -> last chain inputs
    // end -> outputs (always will be axis_tx_x)
    tail_end tail_ending(
        .tail_data(tremolo_m_data),
        .tail_valid(tremolo_m_valid),
        .tail_ready(tremolo_m_ready),
        .tail_last(tremolo_m_last),

        .end_data(axis_tx_data),
        .end_valid(axis_tx_valid),
        .end_ready(axis_tx_ready),
        .end_last(axis_tx_last)
    );

    // assign axis_tx_data  = distortion_m_data;
    // assign axis_tx_valid = distortion_m_valid;
    // assign axis_tx_last  = distortion_m_last;
    // assign distortion_m_ready = axis_tx_ready;

endmodule