module audio #(parameter int clkdivider = 100000000/440/2)(
    input logic clk,
    output logic speaker
);


logic [16:0] counter;
always_ff @(posedge clk) begin
    if(counter==0) begin
        counter <= clkdivider-1; 
    end
    else begin
        counter <= counter-1;
    end
end

always_ff @(posedge clk) begin
    if (counter==0) begin
        speaker <= ~speaker;
    end
end
 
endmodule