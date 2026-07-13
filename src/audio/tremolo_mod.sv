module tremolo_mod(
    /* Inputs */
    input  wire         clk,
    input  wire         t_enable,  // for testing this will be manually set in top, but later on will have a button
    input  wire         resetn, 

    input  wire [3:0]   depth,     // to dictate the strength of the tremolo effect

    input  wire [31:0]  s_data,
    input  wire         s_valid,
    output logic        s_ready,   // for when the output data is a new slave input
    input  wire         s_last,

    /* Outputs */
    output logic [31:0] m_data,
    output logic        m_valid,
    input  wire         m_ready,   // for the previous data to tell this module that it's ready 
    output logic        m_last
);
/*
                 [   Result 2   +    Result 1   ]
        [ Input         *      Result 3         ] 
   y(n) = x(n) * [(1.0 - Depth) + Depth * LFO(n)]    
*/

/*
    Explanation due to the slightly more complicated nature of tremolo compared to distortion:
    Tremolo is just the amplification modulator of the incoming signal, either using a triangle
    or sine wave to modulate the incoming wave, making kinda like a shaky sound with the volume
    periodocially getting quieter and louder

    For this implementation im usig a triangle wave because its a little easier computational
    wise to do so

    Also depth is how strong we want the effect to be, will use dip switches for dat
*/

/*
   Through massive debugging, tremolo only really works with 1-10 frequency so calculate f_lfo with one of those values)
   clk_div = (f_clk) / ((max_counter_val * 2) * f_lfo) -> clk_div = 512.33 -> 512
   For example with 7 = f_lfo:
   clk_div = (22,519,000) / ((255 * 2) * 7) = 6307.84 (ignoring decimals)
*/

localparam PERCENTAGE = 8'hFF;
localparam FIXED_POINT_SHIFT = 4'd8;

wire [15:0] clk_div = 16'd4415; 
wire signed [7:0] lfo_output;

triangle_generator LFO_sample( // i think its fine ????
    .clk(clk),
    .resetn(resetn),
    .clk_div(clk_div),
    .tri_out(lfo_output)
);

/*

   WE are doing fixed point arithmetic cause i said so, EVEYRHTING will be multiplied by 256 (2^8) (or shifting by 8 times to the left)
   the main reason why is because decimals are god awful and will replicate decimals up to the 8th place (i think), if you want to verify 
   my work you can search up fixed point arithmetic  
   1 -> 256

   Slightly more alive cookiesnc here, we also end the calculations by dividing (or shifting the results to the right) by 8 to get a semi rounded
   pretty close and pretty accurate way to allow for decimal calculations.

*/

logic [15:0] depth_count;
assign depth_count = (depth > 10) ? (4'd10) << FIXED_POINT_SHIFT : depth << FIXED_POINT_SHIFT;

wire signed [23:0] audio_in = $signed(s_data[23:0]);

wire [11:0] lfo_inv = 8'd255 - lfo_output;
wire [15:0] result_one = (depth * lfo_inv) >> 4; // Max depth is 15, so dividing by 16 fits perfectly
    
wire signed [8:0] result_two = $signed({1'b0, (8'd255 - result_one[7:0])}); //Range from 0 to 255

wire signed [32:0] mult_product = audio_in * result_two;

wire signed [23:0] audio_out = mult_product[31:8]; // ima be real, this the same as using (>> 8) but only splicing worked for some reason

assign s_ready = m_ready && resetn;

always_ff @(posedge clk) begin
    if (!resetn) begin
        m_data  <= 0;
        m_valid <= 0;
        m_last  <= 0;
    end else begin
        if (s_valid && s_ready) begin
            if (t_enable) begin
                m_data <= {s_data[31:24], audio_out}; 
            end else begin
                m_data <= s_data;
            end
            m_valid <= 1;
            m_last  <= s_last;
        end else if (m_valid && m_ready) begin
            m_valid <= 0;
        end
    end
end


endmodule