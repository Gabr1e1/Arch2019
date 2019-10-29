// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low
  input  wire [ 7:0]          mem_din,		// data input bus

  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	output wire [31:0]			dbgreg_dout		  // cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

//PC -> IF/ID
wire [`AddrLen - 1 : 0] pc;

//IF/ID -> ID
wire [`AddrLen - 1 : 0] id_pc_i;
wire [`InstLen - 1 : 0] id_inst_i;

//Register -> ID
wire [`RegLen - 1 : 0] reg1_data;
wire [`RegLen - 1 : 0] reg2_data;

//ID -> Register
wire [`RegAddrLen - 1 : 0] reg1_addr;
wire [`RegLen - 1 : 0] reg1_read_enable;
wire [`RegAddrLen - 1 : 0] reg2_addr;
wire [`RegLen - 1 : 0] reg2_read_enable;

//ID -> ID/EX
wire [`OpCodeLen - 1 : 0] id_aluop;
wire [`OpSelLen - 1 : 0] id_alusel;
wire [`RegLen - 1 : 0] id_reg1, id_reg2, id_Imm, id_rd;
wire id_rd_enable;

//ID/EX -> EX
wire [`OpCodeLen - 1 : 0] ex_aluop;
wire [`OpSelLen - 1 : 0] ex_alusel;
wire [`RegLen - 1 : 0] ex_reg1, ex_reg2, ex_Imm, ex_rd;
wire ex_rd_enable;

//EX -> EX/MEM
wire [`RegLen - 1 : 0] ex_rd_data;
wire [`RegAddrLen - 1 : 0] ex_rd_addr;
wire ex_rd_enable;

//EX/MEM -> MEM
wire [`RegLen - 1 : 0] mem_rd_data_i;
wire [`RegAddrLen - 1 : 0] mem_rd_addr_i;
wire mem_rd_enable_i;

//MEM -> MEM/WB
wire [`RegLen - 1 : 0] mem_rd_data_o;
wire [`RegAddrLen - 1 : 0] mem_rd_addr_o;
wire mem_rd_enable_o;

//MEM/WB -> Register
wire write_enable;
wire [`RegAddrLen - 1 : 0] write_addr;
wire [`RegLen - 1 : 0] write_data;

//Instantiation
pc_reg pc_reg0(.clk(clk_in), .rst(rst_in), .pc(pc), .chip_enable(???));
if_id if_id0(.clk(clk_in), .rst(rst_in), .if_pc(pc), .if_inst(???), .id_pc(id_pc_i), .id_inst(id_inst_i));
id id0(.rst(rst), .pc(id_pc_i), .inst(id_inst_i), .reg1_data_i(reg1_data), .reg2_data_i(reg2_data), 
      .reg1_addr_o(reg1_addr), .reg1_read_enable(reg1_read_enable), .reg2_addr_o(reg2_addr), .reg2_read_enable(reg2_read_enable),
      .reg1(id_reg1), .reg2(id_reg2), .Imm(id_Imm), .rd(id_rd), .rd_enable(id_rd_enable), .aluop(id_aluop, .alusel(.id_alusel)));
register register0(.clk(clk_in), .rst(rst_in), 
                  .write_enable(write_enable), .write_addr(write_addr), .write_data(write_data),
                  .read_enable1(reg1_read_enable), .read_addr1(reg1_addr), .read_data(reg1_data),
                  .read_enable2(reg2_read_enable), .read_addr2(reg2_addr), .read_data(reg2_data));
id_ex id_ex0(.clk(clk_in), .rst(rst_in),
            .id_reg1(id_reg1), .id_reg2(id_reg2), .id_Imm(id_Imm), .id_rd(id_rd), .id_rd_enable(id_rd_enable), .id_aluop(id_aluop), .id_alusel(id_alusel),
            .ex_reg1(ex_reg1), .ex_reg2(ex_reg2), .ex_Imm(ex_Imm), .ex_rd(ex_rd), .ex_rd_enable(ex_rd_enable), .ex_aluop(ex_aluop), .ex_alusel(ex_alusel),
)
ex ex0()

always @(posedge clk_in) begin
    if (!rdy_in) begin
      //pause cpu
    end
end

endmodule