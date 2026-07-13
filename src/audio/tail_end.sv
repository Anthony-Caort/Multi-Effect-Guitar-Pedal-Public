module tail_end(

    /* Inputs */
    input wire [31:0] tail_data,
    input wire        tail_valid,
    input wire        end_ready,
    input wire        tail_last,

    /* Outputs */
    output wire [31:0] end_data,
    output wire        end_valid,
    output wire        tail_ready,
    output wire        end_last
);

    assign end_data   = tail_data;
    assign end_valid  = tail_valid;
    assign end_last   = tail_last;
    assign tail_ready = end_ready;

endmodule