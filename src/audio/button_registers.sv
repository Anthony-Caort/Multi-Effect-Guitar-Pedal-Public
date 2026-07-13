module button_registers(
    input  logic clk,
    input  logic button_press,
    output logic enable = 0
);

typedef enum logic [1:0] {OFF, HELD} button_state_t;

logic [16:0] count = 0;
button_state_t state = OFF;
button_state_t next_state = OFF;
logic button_n;

//change state
always_ff @(posedge clk) begin
    state <= next_state;
    button_n <= ~button_press;

    if (button_n) begin
        if (count < 12000)
            count <= count + 1;
    end else begin
        count <= 0;
    end

    if (state == HELD && !button_n) begin // releasing da button
        enable <= ~enable;
    end
end 

//state transition
always_comb begin
    next_state = state;
    
    case (state)
        OFF: begin
            if (button_n && count >= 12000)
                next_state = HELD;
        end

        HELD: begin
            if (!button_n) begin
                next_state = OFF;
            end
        end
    endcase
end

endmodule