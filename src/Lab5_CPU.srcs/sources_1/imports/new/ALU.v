`timescale 1ns / 1ps

module ALU (
	input signed [31:0] A,
	input signed [31:0] B,
	output reg signed [31:0] S,
	input [3:0] op,
	output [2:0] nzp
);
	
	wire unsigned [31:0] Au,Bu;

	assign Au=$unsigned(A);
	assign Bu=$unsigned(B);

	wire [4:0] shift;

	assign shift=A[4:0];

	// ALU op 码
	parameter
		ALU_OP_ADD=1,
		ALU_OP_SUB=2,
		ALU_OP_SLT=5,
		ALU_OP_SLTU=6,
		ALU_OP_SLL=7,
		ALU_OP_SRL=8,
		ALU_OP_SRA=9,
		ALU_OP_AND=10,
		ALU_OP_OR=11,
		ALU_OP_XOR=12,
		ALU_OP_NOR=13;

	always @(*) begin
		case (op)
			ALU_OP_ADD: S = A + B;
			ALU_OP_SUB: S = A - B;
			ALU_OP_SLT: S = A < B ? 1 : 0;
			ALU_OP_SLTU: S = Au < Bu ? 1 : 0;
			ALU_OP_SLL: S = B << shift;
			ALU_OP_SRL: S = B >> shift;
			ALU_OP_SRA: S = B >>> shift;
			ALU_OP_AND: S = A & B;
			ALU_OP_OR: S = A | B;
			ALU_OP_XOR: S = A ^ B;
			ALU_OP_NOR: S = ~(A | B);
			default: S=0;
		endcase
	end

	assign nzp = { S<0, S==0, S>0 };

endmodule