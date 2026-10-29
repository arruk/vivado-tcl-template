`timescale 1ns / 1ps
`default_nettype none

// AX7350B: clock PL de 50 MHz; quatro LEDs ativos em nivel alto.
module top (
    input  wire       sys_clk,
    output reg  [3:0] led = 4'b0000
);
    // Valores iniciais sao implementados pelo Vivado na configuracao da FPGA.
    reg [25:0] counter = 26'd0;

    always @(posedge sys_clk) begin
        if (counter == 26'd49_999_999) begin
            counter <= 26'd0;
            led <= ~led;
        end else begin
            counter <= counter + 26'd1;
        end
    end
endmodule

`default_nettype wire
