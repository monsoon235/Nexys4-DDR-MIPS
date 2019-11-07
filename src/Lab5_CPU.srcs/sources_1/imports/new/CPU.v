`timescale 1ns / 1ps

module CPU(
	input clk,
	input rst,

	// 内存接口
	output [31:0] mem_addr,
	output [31:0] mem_wd,
	input [31:0] mem_rd,
	output mem_we,

	output reg [31:0] PC,
	input [4:0] DDU_reg_addr,
	output [31:0] DDU_reg_data,
	output DDU_in_IF
    );

	reg [31:0] IR, MDR, ALUOut;
	wire [2:0] nzp;

	wire [1:0] PCSrc;
	wire PCWrite;

	wire MASrc, MemWrite, IRWrite, MDRWrite;

	assign mem_addr = MASrc ? ALUOut : PC;
	assign mem_we = MemWrite;
	assign mem_wd = rt_d;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			PC <= 0;
			IR <= 0;
			MDR <= 0;
		end
		else begin
			if(PCWrite) begin
				case (PCSrc)
					0: PC <= S;
					1: PC <= rs_d;
					2: begin
						PC[27:2] <= IR[25:0];
						PC[1:0] <= 'b00;
					end
					default: PC <= S;
				endcase
			end
			if(IRWrite) begin
				IR <= mem_rd;
			end
			if(MDRWrite) begin
				MDR <= mem_rd;
			end
		end
	end

	wire [1:0] RegWASrc, RegWDSrc;
	wire RegRead, RegWrite;

	wire [1:0] ALUSrcA;
	wire [2:0] ALUSrcB;
	wire [3:0] ALUOp;
	wire ALUOutWrite;

	Control control(
		.clk(clk),
		.rst(rst),
		.inst(IR),
		.nzp(nzp),

		.PCSrc(PCSrc),
		.PCWrite(PCWrite),

		.MASrc(MASrc),
		.MemWrite(MemWrite),
		.IRWrite(IRWrite),
		.MDRWrite(MDRWrite),

		.RegWASrc(RegWASrc),
		.RegWDSrc(RegWDSrc),
		.RegRead(RegRead),
		.RegWrite(RegWrite),

		.ALUSrcA(ALUSrcA),
		.ALUSrcB(ALUSrcB),
		.ALUOp(ALUOp),
		.ALUOutWrite(ALUOutWrite),
		// .NZPWrite(NZPWrite),

		.DDU_in_IF(DDU_in_IF)
		);

	wire [4:0] rs_a, rt_a, rd_a;
	wire [31:0] rs_d, rt_d;

	assign rs_a = IR[25:21];
	assign rt_a = IR[20:16];
	assign rd_a = IR[15:11];

	reg [4:0] wa;
	reg [31:0] wd;

	always @(*) begin
		case (RegWASrc)
			0: wa = rd_a;
			1: wa = rt_a;
			2: wa = 31;
			default: wa = 0;
		endcase
		case (RegWDSrc)
			0: wd = ALUOut;
			1: wd = MDR;
			2: wd = PC;
			default : wd = ALUOut;
		endcase
	end

	Registers register(
		.clk(clk),
		.rst(rst),
		.re(RegRead),
		.we(RegWrite),
		.ra1(rs_a),
		.ra2(rt_a),
		.wa(wa),
		.rd1(rs_d),
		.rd2(rt_d),
		.wd(wd),
		// DDU
		.ra3(DDU_reg_addr),
		.rd3(DDU_reg_data)
		);

	reg [31:0] A, B;

	wire [15:0] imm16;
	assign imm16 = IR[15:0];

	always @(*) begin
		case (ALUSrcA)
			0: A = rs_d;
			1: A = PC;
			2: begin
				A[31:5] = 0;
				A[4:0] = IR[10:6];
			end
			default: A = 0;
		endcase
		case (ALUSrcB)
			0: B = rt_d;
			1: begin
				B[31:16] = {16{imm16[15]}};
				B[15:0] = imm16;
			end
			2: begin
				B[31:18] = {14{imm16[15]}};
				B[17:2] = imm16;
				B[1:0] = 'b00;
			end
			3:begin
				B[31:16] = 0;
				B[15:0] = imm16;
			end
			4: B = 4;
			5: B = 0;
			default : B = 0;
		endcase
	end

	// wire [2:0] nzp_out;
	wire [31:0] S;

	always @(posedge clk or posedge rst) begin
		if(rst) begin
			ALUOut <= 0;
			// nzp <= 0;
		end
		else begin
			// if(NZPWrite) begin
			// 	nzp <= nzp_out;
			// end
			if(ALUOutWrite) begin
				ALUOut <= S;
			end
		end
	end

	ALU alu(
		.A(A),
		.B(B),
		.S(S),
		.op(ALUOp),
		.nzp(nzp)
		);
endmodule
