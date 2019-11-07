`timescale 1ns / 1ps

module Registers(
    input clk,
    input rst,
    input re,
    input we,
    input [4:0] ra1,
    input [4:0] ra2,
    input [4:0] ra3,
    input [4:0] wa,
    input [31:0] wd,
    output reg [31:0] rd1,
    output reg [31:0] rd2,
    output [31:0] rd3
    );

	reg [31:0] store [31:1];

	// assign rd1=store[ra1];
	// assign rd2=store[ra2];
	assign rd3 = store[ra3];

	integer i;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			for (i = 1; i < 32; i = i + 1) begin
				store[i] <= 0;
			end
			rd1 <= 0;
			rd2 <= 0;
		end
		else begin
			if(we) begin
				store[wa] <= wd;
			end
			if(re) begin
				rd1 <= ra1==0 ? 0 : store[ra1];
				rd2 <= ra2==0 ? 0 : store[ra2];
			end
		end
		// else if(we) begin
		// 	store[wa]<=wd;
		// end
	end

endmodule
