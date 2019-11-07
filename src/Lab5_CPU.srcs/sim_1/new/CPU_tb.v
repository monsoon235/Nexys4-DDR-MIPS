`timescale 1ns / 1ps

module CPU_tb;
	reg clk, rst;
	initial begin
		clk = 0;
		forever begin
			#1 clk = ~clk;
		end
	end

	wire [31:0] PC;

	integer i;
	initial begin
		for (i = 0; i < 256; i=i+1) begin
			mem[i]=0;
		end
		mem[0]='h20080001;
		mem[1]='h20090002;
		mem[2]='h01285020;
		mem[3]='h01495822;
		mem[4]='h012a6025;
		mem[5]='h012a6824;
		mem[6]='h012a7026;
		mem[7]='h012a7827;
		mem[8]='h012a882a;
		mem[9]='h29320000;
		mem[10]='h31530005;
		mem[11]='h35540005;
		mem[12]='h39550005;
		mem[13]='hac090100;
		mem[14]='h8c160100;
		mem[15]='h11090001;
		mem[16]='h20170001;
		mem[17]='h11a90001;
		mem[18]='h20170002;
		mem[19]='h15090001;
		mem[20]='h20170003;
		mem[21]='h15a90001;
		mem[22]='h20170004;
		mem[23]='h08100019;
		mem[24]='h20170005;
		mem[25]='h20000001;
		rst=1; #1 rst=0;
	end

	wire [31:0] mem_addr, mem_wd, mem_rd;
	wire mem_we;

	CPU cpu_dut(
		.clk(clk),
		.rst(rst),
		.mem_addr(mem_addr),
		.mem_wd(mem_wd),
		.mem_rd(mem_rd),
		.mem_we(mem_we),
		.PC(PC)
		);

	assign mem_rd=mem[mem_addr[9:2]];

	reg [31:0] mem [255:0];

	always @(posedge clk) begin
		if(mem_we) begin
			mem[mem_addr[9:2]]=mem_wd;
		end
	end

endmodule
