`timescale 1ns / 1ps

`include "src/top.sv"

module tb_top;

    // -------------------------------------------------------------------------
    // 1. Clock and Signal Definitions
    // -------------------------------------------------------------------------
    reg clk_25m = 0;
    
    // SDRAM Signals
    wire        sdram_clk;
    wire        sdram_cke;
    wire        sdram_cs_n;
    wire        sdram_ras_n;
    wire        sdram_cas_n;
    wire        sdram_we_n;
    wire [1:0]  sdram_ba;
    wire [12:0] sdram_a;
    wire [1:0]  sdram_dqm;
    wire [15:0] sdram_dq; // Bi-directional in real life, wire here

    // LCD Signals (Can be left floating or monitored)
    wire        lcd_clk, lcd_hsync, lcd_vsync, lcd_de;
    wire [4:0]  lcd_r, lcd_b;
    wire [5:0]  lcd_g;

    // SPI Signals (Driven by our tasks)
    reg         sclk = 1;
    reg         pico = 0;
    reg         cs_n = 1;
    reg         data_cmd = 0;

    // Clock Generator (25 MHz)
    always #20 clk_25m = ~clk_25m;

    // -------------------------------------------------------------------------
    // 2. Unit Under Test (UUT)
    // -------------------------------------------------------------------------
    top uut (
        .clk_25m     (clk_25m),
        .sdram_clk   (sdram_clk),
        .sdram_cke   (sdram_cke),
        .sdram_cs_n  (sdram_cs_n),
        .sdram_ras_n (sdram_ras_n),
        .sdram_cas_n (sdram_cas_n),
        .sdram_we_n  (sdram_we_n),
        .sdram_ba    (sdram_ba),
        .sdram_a     (sdram_a),
        .sdram_dqm   (sdram_dqm),
        .sdram_dq    (sdram_dq),
        .lcd_clk     (lcd_clk),
        .lcd_hsync   (lcd_hsync),
        .lcd_vsync   (lcd_vsync),
        .lcd_de      (lcd_de),
        .lcd_r       (lcd_r),
        .lcd_g       (lcd_g),
        .lcd_b       (lcd_b),
        .sclk        (sclk),
        .pico        (pico),
        .cs_n        (cs_n),
        .data_cmd    (data_cmd)
    );

    // -------------------------------------------------------------------------
    // 3. Behavioral SDRAM Memory Model
    // -------------------------------------------------------------------------
    // Replace this with the actual vendor simulation model (e.g., mt48lc16m16a2.v)
    // mapping pins one-to-one.
    is42s16160b_model sdram_mem_inst (
        .clk   (sdram_clk),
        .cke   (sdram_cke),
        .cs_n  (sdram_cs_n),
        .ras_n (sdram_ras_n),
        .cas_n (sdram_cas_n),
        .we_n  (sdram_we_n),
        .ba    (sdram_ba),
        .addr  (sdram_a),
        .dqm   (sdram_dqm),
        .dq    (sdram_dq)
    );

    // -------------------------------------------------------------------------
    // 4. SPI Driver Tasks (The "Better Way")
    // -------------------------------------------------------------------------
    
    // High-level task to send a single byte over SPI (Assuming SPI Mode 0 or 3)
    task send_spi_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                sclk = 0;
                pico = data[i];
                #100; // Adjust for your targeted SPI speed (e.g., 5MHz)
                sclk = 1;
                #100;
            end
        end
    endtask

    // Elegant task to send a whole pixel stream sequence
    task send_pixel_command(input [23:0] start_addr, input [7:0] payload[]);
        integer j;
        begin
            $display("[TX TIME: %0t] Starting SPI Packet Transmission...", $time);
            cs_n = 0;
            data_cmd = 0; // Command Mode
            
            // Example: Send 3 address bytes if your display controller expects it
            send_spi_byte(start_addr[23:16]);
            send_spi_byte(start_addr[15:8]);
            send_spi_byte(start_addr[7:0]);
            
            #500;
            data_cmd = 1; // Switch to Data Mode for pixels
            
            for (j = 0; j < payload.size(); j = j + 1) begin
                send_spi_byte(payload[j]);
            end
            
            #100;
            cs_n = 1; // End Packet
            pico = 0;
        end
    endtask

    // -------------------------------------------------------------------------
    // 5. Test Vectors & Assertions
    // -------------------------------------------------------------------------
    initial begin
        // Define test payload data
        // For a 16-bit word, we need 2 bytes (Even index, then Odd index)
        bit [7:0] test_frame[4] = {8'hAA, 8'hBB, 8'hCC, 8'hDD};
        
        // Wait for PLL locked & SDRAM initialization sequence to finish
        wait(uut.locked == 1);
        #50000; // SDRAM usually requires ~100-200us initial delay
        
        // Run the SPI command
        send_pixel_command(24'h000000, test_frame);
        
        // Allow time for the final aggregated 16-bit word to clear 
        // the pixel aggregator and settle into SDRAM
        #10000;

        // --- THE SCOREBOARD VERIFICATION ---
        // Peek directly inside your SDRAM vendor model to see if data landed correctly!
        // Note: Update hierarchical path matching your vendor model's internal array names.
        if (sdram_mem_inst.memory_array[0] === 16'hBBAA && 
            sdram_mem_inst.memory_array[1] === 16'hDDCC) begin
            $display("[PASSED] SPI to SDRAM Controller Datapath working perfectly!");
        end else begin
            $display("[FAILED] Data Mismatch! Expected BBAA, Got %h", sdram_mem_inst.memory_array[0]);
        end

        $finish;
    end

endmodule
