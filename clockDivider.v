`timescale 1ns / 1ps
//------------------------------------------------------------------
// clockDivider : 100 MHz board clock -> 10 MHz processor clock
//   DIV = 10  ->  toggles every DIV/2 = 5 input cycles
//   f_out = 100 MHz / 10 = 10 MHz   (50 % duty cycle)
//   USE_BUFG = 1 : route the divided clock on a global clock buffer
//------------------------------------------------------------------
module clockDivider #(
    parameter DIV      = 10,
    parameter USE_BUFG = 1
)(
    input  clk_in,
    output clk_out
);
    reg [7:0] cnt   = 8'd0;
    reg       clk_r = 1'b0;

    always @(posedge clk_in) begin
        if (cnt == (DIV/2 - 1)) begin
            cnt   <= 8'd0;
            clk_r <= ~clk_r;
        end else begin
            cnt   <= cnt + 8'd1;
        end
    end

    generate
        if (USE_BUFG) begin : g_bufg
            BUFG u_bufg (.I(clk_r), .O(clk_out));
        end else begin : g_nobufg
            assign clk_out = clk_r;
        end
    endgenerate
endmodule
