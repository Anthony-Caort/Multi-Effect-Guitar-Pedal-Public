module lcd_bare
(
    input  logic rst,
    input  logic pclk,  
    output logic LCD_DE,      // Display Enable

    output logic [9:0] pixel_address,
    input  logic pixel,

    output wire [4:0] LCD_B, // 5-bit blue color data
    output wire [5:0] LCD_G , // 6-bit green color data
    output wire [4:0] LCD_R  // 5-bit red color data
);

logic [9:0] x_coord = 10'b0000000000;
logic [9:0] y_coord = 10'b0000000000;

// coordinate logic

always_ff @(posedge pclk) begin 
    if (x_coord < 524) begin
        x_coord <= x_coord + 1;
    end else begin
        x_coord <= 0;
        if (y_coord < 284) begin
            y_coord <= y_coord + 1;
        end else begin
            y_coord <= 0;
        end
    end
end

assign LCD_DE = ((x_coord < 480) && (y_coord < 272));

always_comb begin
    if (LCD_DE) begin
        if (pixel) begin // if the pixel is a white pixel
            LCD_B = 5'b11111;
            LCD_G = 6'b111111;
            LCD_R = 5'b11111;
        end else begin   // if the pixel is a black pixel
            LCD_B = 5'b0;
            LCD_G = 6'b0;
            LCD_R = 5'b0;
        end
    end else begin
        LCD_B = 5'b0;
        LCD_G = 6'b0;
        LCD_R = 5'b0;
    end
end

//assign pixel_address = (y_coord >> 4) * 9'd32 + (x_coord >> 4);

always_ff @(posedge pclk) begin
    if (LCD_DE) begin
        pixel_address <= (y_coord >> 4) * 9'd32 + (x_coord >> 4);
    end
end
/* 

    yeah this code above truncates at the 10th bit 
    but for the bare bones version this is a non issue 
    it will never reach that high anyways for the need of 10 bits

*/

endmodule
