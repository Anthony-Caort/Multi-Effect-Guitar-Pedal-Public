module triangle_generator(
    /* Inputs */
    input wire clk,
    input wire resetn,
    input wire [15:0] clk_div,

    /* Outputs */
    output logic [7:0] tri_out
);

    localparam signed MAX_UPPER_VALUE =  8'd255;

    logic [7:0] counter   = 0; 
    logic [15:0] prescaler = 0; // its bigger size than clk_div because im scared of overloading it somehow


    logic direction = 0; // have to take accouont of the shape of a triangle going both down and up
    // 0 -> up, 1-> down

    always_ff @(posedge clk) begin
        if (!resetn) begin // start by going up
            counter   <= 0; // dead center :P
            direction <= 0;
            tri_out   <= 0;
            prescaler <= 0;
        end else begin
            if (prescaler < clk_div - 1) begin // sampling at about 86 hz (f_lfo)
                prescaler <= prescaler + 1;
            end else begin
                prescaler <= 0;

                if (!direction) begin // going up
                    if (counter < MAX_UPPER_VALUE) begin
                        counter <= counter + 1;
                    end else begin
                        direction <= 1;
                        counter <= counter - 1;
                    end
                end else begin // going down
                    if (counter > 0) begin
                        counter <= counter - 1;
                    end else begin
                        direction <= 0;
                        counter <= counter + 1;
                    end
                end

                tri_out <= counter;
            end
        end
    end



endmodule