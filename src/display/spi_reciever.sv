module spi (
    input  logic sclk,
    input  logic cs,
    input  logic pico,

    output logic        data_stream = 0,  // 1 bit per pixel
    output logic        we = 0,
    output logic [9:0]  waddr = 0         // 0-509
);

    always_ff @(posedge sclk) begin
        if (!cs) begin
            data_stream <= pico;
            we <= 1;
            waddr <= (waddr > 542) ? 9'd0 : waddr + 1;
        end else begin
            we <= 0;
            waddr <= 0;
        end
    end

endmodule