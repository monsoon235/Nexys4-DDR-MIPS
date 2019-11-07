`timescale 1ns / 1ps

module Control (
	input clk,
	input rst,
	input [31:0] inst,
	input [2:0] nzp,	// 用于分支

	// PC 相关
	output reg [1:0] PCSrc,
	output PCWrite,

	// Mem 相关
	output MASrc,
	output MemWrite,
	output IRWrite,
	output MDRWrite,

	// reg 相关
	output reg [1:0] RegWASrc,
	output RegRead,
	output RegWrite,
	output reg [1:0] RegWDSrc,

	// ALU 相关
	output reg [1:0] ALUSrcA,
	output reg [2:0] ALUSrcB,
	output reg [3:0] ALUOp,
	output ALUOutWrite,
	// output NZPWrite,

	// DDU
	output DDU_in_IF
);

	assign DDU_in_IF = state==IF;

	wire [5:0] op,funct;
	wire [4:0] spec;

	assign op = inst[31:26];
	assign funct = inst[5:0];
	assign spec = inst[20:16];

	parameter
		OP_LW='h23,
		OP_SW='h2B,

		OP_R='h0,

		OP_ADDI='h8,
		OP_ANDI='hC,
		OP_ORI='hD,
		OP_XORI='hE,
		OP_SLTI='hA,
		OP_SLTIU='hB,

		OP_BEQ='h4,
		OP_BNE='h5,
		OP_BLEZ='h6,
		OP_BGTZ='h7,

		OP_BLTZ_BGEZ='h1,
		SPEC_BLTZ='h0,
		SPEC_BGEZ='h1,

		OP_J='h2,
		OP_JAL='h3,
		OP_JR_JALR='h0,
		FUNCT_JR='h8,
		FUNCT_JALR='h9,

		FUNCT_ADD='h20,
		FUNCT_SUB='h22,
		FUNCT_SLT='h2A,
		FUNCT_SLTU='h2B,
		FUNCT_SLL='h0,
		FUNCT_SRL='h2,
		FUNCT_SRA='h3,
		FUNCT_SLLV='h4,
		FUNCT_SRLV='h6,
		FUNCT_SRAV='h7,
		FUNCT_AND='h24,
		FUNCT_OR='h25,
		FUNCT_XOR='h26,
		FUNCT_NOR='h27;

	reg [4:0] state;

	parameter
		IF=1,		// inst fetch
		ID=2,		// inst decode

		R_R=3,		// R_R inst ALU
		R_I=4,		// R_I inst ALU
		R_R_WB=5,
		R_I_WB=6,

		J=7,
		JR=8,
		JAL=9,
		JALR=10,

		B=11,
		BZ=12,
		B_PC=13,

		LW_SW=14,
		MEM_READ=15,
		MEM_WRITE=16,
		LW_WB=17,
		ERROR=0;

	// 状态转换
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			state <= IF;
		end
		else begin
			case (state)
				IF: state <= ID;
				ID: begin
					// 根据 op 和 funct 更改
					case (op)
						OP_LW: state <= LW_SW;
						OP_SW: state <= LW_SW;
						OP_R: state <= R_R;
						OP_ADDI: state <= R_I;
						OP_ANDI: state <= R_I;
						OP_ORI: state <= R_I;
						OP_XORI: state <= R_I;
						OP_SLTI: state <= R_I;
						OP_SLTIU: state <= R_I;
						OP_BEQ: state <= B;
						OP_BNE: state <= B;
						OP_BLEZ: state <= BZ;
						OP_BGTZ: state <= BZ;
						OP_BLTZ_BGEZ: state <= BZ;
						OP_J: state <= J;
						OP_JAL: state <= JAL;
						OP_JR_JALR: begin
							case (funct)
								FUNCT_JR: state <= JR;
								FUNCT_JALR: state <= JALR;
								default: state <= ERROR;
							endcase
						end
						default: state <= ERROR;
					endcase
				end
				R_R: state <= R_R_WB;
				R_I: state <= R_I_WB;
				R_R_WB: state <= IF;
				R_I_WB: state <= IF;
				J: state <= IF;
				JR: state <= IF;
				JAL: state <= IF;
				JALR: state <= IF;
				B: begin
					// 根据判断结果
					case (op)
						OP_BEQ: state <= nzp[1] ? B_PC : IF;
						OP_BNE: state <= (nzp[2]|nzp[0]) ? B_PC : IF;
						default: state <= ERROR;
					endcase
				end
				BZ: begin
					// 根据判断结果
					case (op)
						OP_BLEZ: state <= (nzp[2]|nzp[1]) ? B_PC : IF;
						OP_BGTZ: state <= nzp[0] ? B_PC : IF;
						OP_BLTZ_BGEZ: begin
							case (spec)
								SPEC_BLTZ: state <= nzp[2] ? B_PC : IF;
								SPEC_BGEZ: state <= (nzp[1]|nzp[0]) ? B_PC : IF;
								default: state <= ERROR;
							endcase
						end
						default: state <= ERROR;
					endcase
				end
				B_PC: state <= IF;
				LW_SW: begin
					// 根据 op 判断
					case (op)
						OP_LW: state <= MEM_READ;
						OP_SW: state <= MEM_WRITE;
						default: state <= ERROR;
					endcase
				end
				MEM_READ: state <= LW_WB;
				MEM_WRITE: state <= IF;
				LW_WB: state <= IF;
				default: state <= ERROR;
			endcase
		end
	end

	assign PCWrite = |{ state==IF, state==J, state==JR, state==JAL, state==JALR, state==B_PC};
	// PCSrc:
	// 0: S  1: rs  2: J_imm
	always @(*) begin
		case (state)
			IF: PCSrc = 0;
			B_PC: PCSrc = 0;
			J: PCSrc = 2;
			JR: PCSrc = 1;
			JAL: PCSrc = 2;
			JALR: PCSrc = 1;
			default: PCSrc = 0;
		endcase
	end

	// MASrc:
	// 0: PC  1: ALU
	assign MASrc = state==MEM_READ || state==MEM_WRITE;
	assign MemWrite = state==MEM_WRITE;
	assign IRWrite = state==IF;
	assign MDRWrite = state==MEM_READ;

	assign RegRead = state==ID;
	assign RegWrite = |{state==LW_WB, state==R_R_WB, state==R_I_WB, state==JAL, state==JALR};
	// RegWASrc:
	// 0: rd  1: rt  2:31
	always @(*) begin
		case (state)
			R_R_WB: RegWASrc = 0;
			R_I_WB: RegWASrc =1;
			LW_WB: RegWASrc = 1;
			JAL: RegWASrc = 2;
			JALR: RegWASrc = 0;
			default: RegWASrc = 0;
		endcase
	end
	// RegWDSrc:
	// 0: ALU  1: MDR  2: PC
	always @(*) begin
		case (state)
			R_R_WB: RegWDSrc = 0;
			R_I_WB: RegWDSrc = 0;
			LW_WB: RegWDSrc = 1;
			JAL: RegWDSrc =2;
			JALR: RegWDSrc =2;
			default: RegWDSrc = 0;
		endcase
	end
	
	// ALUSrcA
	// 0: rs  1:PC  2:shift
	always @(*) begin
		case (state)
			IF: ALUSrcA = 1;
			// 移位指令特殊处理
			R_R: ALUSrcA = |{funct==FUNCT_SLL, funct==FUNCT_SRL, funct==FUNCT_SRA} ? 2 : 0;
			R_I: ALUSrcA = 0;
			B: ALUSrcA = 0;
			BZ: ALUSrcA = 0;
			B_PC: ALUSrcA = 1;
			LW_SW: ALUSrcA = 0;
			default: ALUSrcA = 0;
		endcase
	end

	// ALUSrcB
	// 0:rt  1: sext(imm16)  2: sext(imm16)<<2
	// 3:zext(imm16)  4:4  5:0
	always @(*) begin
		case (state)
			IF: ALUSrcB = 4;
			R_R: ALUSrcB = 0;
			// ANDI ORI XORI 需要 zimm
			R_I: ALUSrcB = |{op==OP_ANDI, op==OP_ORI, op==OP_XORI} ? 3 : 1;
			B: ALUSrcB = 0;
			BZ: ALUSrcB = 5;
			B_PC: ALUSrcB = 2;
			LW_SW: ALUSrcB = 1;
			default: ALUSrcB = 0;
		endcase
	end

	assign ALUOutWrite = |{state==R_R, state==R_I, state==LW_SW};
	// assign NZPWrite = state==B || state==BZ;

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

	// ALUOp
	always @(*) begin
		case (state)
			IF: ALUOp = ALU_OP_ADD;
			R_R: begin
				case (funct)
					FUNCT_ADD: ALUOp = ALU_OP_ADD;
					FUNCT_SUB: ALUOp = ALU_OP_SUB;
					FUNCT_SLT: ALUOp = ALU_OP_SLT;
					FUNCT_SLTU: ALUOp = ALU_OP_SLTU;
					FUNCT_SLL: ALUOp = ALU_OP_SLL;
					FUNCT_SRL: ALUOp = ALU_OP_SRL;
					FUNCT_SRA: ALUOp = ALU_OP_SRA;
					FUNCT_SLLV: ALUOp = ALU_OP_SLL;
					FUNCT_SRLV: ALUOp = ALU_OP_SRL;
					FUNCT_SRAV: ALUOp = ALU_OP_SRA;
					FUNCT_AND: ALUOp = ALU_OP_AND;
					FUNCT_OR: ALUOp = ALU_OP_OR;
					FUNCT_XOR: ALUOp = ALU_OP_XOR;
					FUNCT_NOR: ALUOp = ALU_OP_NOR;
					default : ALUOp = 0;
				endcase
			end
			R_I: begin
				case (op)
					OP_ADDI: ALUOp = ALU_OP_ADD;
					OP_ANDI: ALUOp = ALU_OP_AND;
					OP_ORI: ALUOp = ALU_OP_OR;
					OP_XORI: ALUOp = ALU_OP_XOR;
					OP_SLTI: ALUOp = ALU_OP_SLT;
					OP_SLTIU: ALUOp = ALU_OP_SLTU;
					default: ALUOp = 0;
				endcase
			end
			B: ALUOp = ALU_OP_SUB; 
			BZ: ALUOp = ALU_OP_SUB;
			B_PC: ALUOp = ALU_OP_ADD;
			LW_SW: ALUOp = ALU_OP_ADD;
			default: ALUOp = 0;
		endcase
	end

endmodule
