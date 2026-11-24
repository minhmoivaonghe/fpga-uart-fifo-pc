module top(
    output wire tx,
    input  wire clk,
    input  wire rst,
    output reg [7:0] led,
    input  wire rx
);
reg r;
wire[7:0] dt;
wire fifo_empty;
reg [8:0]  data;
wire[7:0]  datacontrol;
reg [3:0]  state = 4'd0;
reg [2:0]  step = 3'd0;
reg [4:0]  s = 0, n = 0, i = 0;
wire tick;
reg tx_ena = 0;
reg tx_out = 1'bz;
localparam [3:0]
    ide  = 4'd0,
    start= 4'd1,
    stop = 4'd2;
control uut (.clk(clk), .rst(rst), .rx(rx), .w(w), .data(datacontrol), .tick(tick));
fifo dut (.clk(clk), .rst(rst), .data(datacontrol), .w(w), .dt(dt), .r(r), .fifo_empty(fifo_empty));
assign tx = (tx_ena == 1) ? tx_out : 1'bz;
always @(posedge clk or posedge rst) begin
        if (rst) begin 
            s <= 0;
            n <= 0;
            state <= 4'd0;
            step <= 3'd0;
            tx_ena <= 0;
            tx_out <= 1'bz;
        end
        else  begin 
            case(step)
                3'd0 : begin 
                    r <= 0;
                    if (!fifo_empty) begin
                        r <= 1;
                        step <= 3'd1;
                    end
                end
                3'd1 : begin
                    r <= 0;
                    step <= 3'd2;
                end
                3'd2 : begin
                    led <= dt;
                    case(state)
                            ide : begin 
                                if (tick == 1) begin
                                    if (s <= 15) begin
                                        tx_ena <= 1;
                                        tx_out <= 0;
                                        s <= s + 1;
                                    end
                                    else begin
                                        tx_ena <= 0;
                                        state <= start;
                                        s <= 0;                                                    
                                    end                    
                                end
                            end
                            start : begin 
                                if (n < 8) begin
                                    if (tick == 1) begin
                                        if (s < 15) begin
                                            s <= s + 1;
                                            tx_ena <= 1;
                                            tx_out <= dt[n];   
                                        end
                                        else begin                 
                                            s <= 0;
                                            n <= n + 1;     
                                            tx_ena <= 0;   
                                        end
                                    end
                                end
                                else begin 
                                    state <= stop;
                                    n <= 0;
                                    s <= 0;
                                end
                            end
                            stop : begin
                                if (tick == 1) begin 
                                    if (s < 15) begin
                                        s <= s + 1;
                                        tx_ena <= 1;
                                        tx_out <= 1;
                                    end
                                    else begin
                                        tx_ena <= 0; 
                                        state <= ide;
                                        s <= 0;
                                        step <= 3'd0;
                                    end
                                end
                            end
                    endcase   
                end     
            endcase
        end
    end
endmodule