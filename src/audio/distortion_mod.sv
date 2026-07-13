module distortion_mod(
    /* Inputs */
    input wire clk,
    input wire d_enable,  // for testing this will be manually set in top, but later on will have a button
    input wire resetn, 

    input  wire [31:0] s_data,
    input  wire        s_valid,
    output logic       s_ready, // for when the output data is a new slave input
    input  wire        s_last,

    /* Outputs */
    output logic [31:0] m_data,
    output logic       m_valid,
    input  wire        m_ready,   // for the previous data to tell this module that it's ready 
    output logic       m_last
);

    localparam signed [23:0] UPPER_THRESHOLD =  24'h40000;
    localparam signed [23:0] LOWER_THRESHOLD = -24'h40000;

    logic signed [23:0] initial_audio;
    assign initial_audio = $signed(s_data[23:0]);

    assign s_ready = m_ready && resetn;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            m_data  <= 0;
            m_valid <= 0;
            m_last  <= 0;
        end else begin
            // checks to see if we want to even do any distortion
            if (s_valid && s_ready) begin
                if (d_enable) begin
                    if (initial_audio > UPPER_THRESHOLD) begin
                        m_data <= {s_data[31:24], UPPER_THRESHOLD}; 
                    end
                    else if (initial_audio < LOWER_THRESHOLD) begin
                        m_data <= {s_data[31:24], LOWER_THRESHOLD};
                    end else begin
                        m_data <= s_data;
                    end
                end else begin
                    m_data <= s_data; // just ignore everything else in the module and move on if no distortion
                end

                m_valid    <= 1;
                m_last     <= s_last;
            end else if (m_valid && m_ready) begin
                m_valid <= 0;
            end
        end
    end

endmodule