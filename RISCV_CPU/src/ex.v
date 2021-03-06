`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2019 06:12:53 PM
// Design Name: 
// Module Name: ex
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ex(
    input wire rst,
    input wire clk,
    input wire [`AddrLen - 1 : 0] pc,
    input wire [`AddrLen - 1 : 0] npc,

    input wire [`RegLen - 1 : 0] reg1,
    input wire [`RegLen - 1 : 0] reg2,
    input wire [`RegLen - 1 : 0] Imm,
    input wire [`RegLen - 1 : 0] rd,
    input wire rd_enable,
    input wire [`OpCodeLen - 1 : 0] aluop,
    input wire [`OpSelLen - 1 : 0] alusel,
    input wire [`CtrlLen - 1 : 0] ctrlsel,
    input wire [3:0] width_i,
    
    output reg [`RegLen - 1 : 0] rd_data_o,
    output reg [`RegAddrLen - 1 : 0] rd_addr,
    output reg [`AddrLen - 1 : 0] mem_addr,

    output reg rd_enable_o,
    output reg [3:0] width_o,

//Branch related
    input wire [`AddrLen - 1 : 0] jmp_addr,
    input wire [`AddrLen - 1 : 0] prediction,
    output reg jmp_enable,
    output reg [`AddrLen - 1 : 0] jmp_target,
    //Branch Prediction
    output reg btb_change_enable,

//Flush
    output reg id_flushed
    );
    
    reg [`RegLen - 1 : 0] res;

    wire beq = reg1 == reg2;
    wire bne = reg1 != reg2;
    wire blt = $signed(reg1) < $signed(reg2);
    wire bltu = $unsigned(reg1) < $unsigned(reg2);
    wire bge = $signed(reg1) >= $signed(reg2);
    wire bgeu = $unsigned(reg1) >= $unsigned(reg2);

//Do the calculation
always @ (*) begin
    if (rst == `ResetEnable) begin
        res = `ZERO_WORD;
        id_flushed = 1'b0;
    end
    else begin
        id_flushed = 1'b0;
        case (aluop)
            `OP_AUIPC:
                res = pc + Imm;
            `OP_ADD:
                res = reg1 + reg2;
            `OP_ADD2:
                res = reg1 + Imm;
            `OP_SUB:
                res = reg1 - reg2;
            `OP_SLL:
                res = reg1 << reg2[4:0];
            `OP_SLT:
                res = { {31{1'b0}}, $signed(reg1) < $signed(reg2) };
            `OP_SLTU:
                res = { {31{1'b0}}, reg1 < reg2 };
            `OP_XOR:
                res = reg1 ^ reg2;
            `OP_SRL:
                res = reg1 >> reg2[4:0];
            `OP_SRA:
                res = reg1 >>> reg2[4:0];
            `OP_OR:
                res = reg1 | reg2;
            `OP_AND:
                res = reg1 & reg2;
            `FlushOp: begin
                id_flushed = 1'b1;
                res = `ZERO_WORD;
            end
            default: 
                res = `ZERO_WORD;
        endcase
    end
end

//Determine the output
always @ (*) begin
    if (rst == `ResetEnable) begin
        rd_addr = `ZERO_WORD;
        width_o = 4'b0000;
        rd_enable_o = `WriteDisable;
        rd_data_o = `ZERO_WORD;
        mem_addr = `ZERO_WORD;
    end
    else begin 
        rd_addr = rd;
        rd_enable_o = rd_enable;
        width_o = 4'b0000;
        mem_addr = `ZERO_WORD;
        
        case (alusel)
            `Arith_OP: 
                rd_data_o = res;
            `LUI_OP:
                rd_data_o = Imm;
            `AUIPC_OP:
                rd_data_o = res;
            `LOAD_OP: begin
                width_o = width_i; 
                rd_data_o = res;
            end
            `STORE_OP: begin
                rd_enable_o = `WriteDisable;
                width_o = width_i;
                rd_data_o = reg2;
                mem_addr = res;
            end
            `JAL_OP: begin
                rd_data_o = reg2;
            end
            default: 
                rd_data_o = `ZERO_WORD;
        endcase
    end
end

//reg _jmp_enable;

//always @ (posedge clk) begin
//    _jmp_enable <= jmp_enable;
//end

always @ (*) begin
    if (rst == `ResetEnable) begin
        jmp_enable = `JumpDisable;
        jmp_target = 0;
        btb_change_enable = 1'b0;
    end
    else begin
        case (ctrlsel)
            `Ctrl_JAL: begin
                jmp_enable = prediction != jmp_addr;
                jmp_target = jmp_addr;
                btb_change_enable = 1'b0;
            end
            `Ctrl_BEQ: begin
                jmp_enable = beq ^ (prediction == jmp_addr);
//                jmp_enable = prediction != (beq ? jmp_addr : npc);
                jmp_target = beq ? jmp_addr : npc;
                btb_change_enable = beq;
            end
            `Ctrl_BNE: begin
                jmp_enable = bne ^ (prediction == jmp_addr);
//                jmp_enable = prediction != (bne ? jmp_addr : npc);
                jmp_target = bne ? jmp_addr : npc;
                btb_change_enable = bne;
            end
            `Ctrl_BLT: begin
                jmp_enable = blt ^ (prediction == jmp_addr);
//                jmp_enable = prediction != (blt ? jmp_addr : npc);
                jmp_target = blt ? jmp_addr : npc;
                btb_change_enable = blt;                                
            end
            `Ctrl_BGE: begin
                jmp_enable = bge ^ (prediction == jmp_addr);
//                jmp_enable = prediction != (bge ? jmp_addr : npc);
                jmp_target = bge ? jmp_addr : npc;
                btb_change_enable = bge;                               
            end
            `Ctrl_BLTU: begin
                jmp_enable = bltu ^ (prediction == jmp_addr);
//                jmp_enable = prediction != (bltu ? jmp_addr : npc);
                jmp_target = bltu ? jmp_addr : npc;
                btb_change_enable = bltu;                                
            end
            `Ctrl_BGEU: begin
                jmp_enable = bgeu ^ (prediction == jmp_addr);
//                jmp_enable = prediction != (bgeu ? jmp_addr : npc);
                jmp_target = bgeu ? jmp_addr : npc;
                btb_change_enable = bgeu;               
            end
            `Ctrl_Flush: begin
                jmp_enable = `JumpDisable;
                jmp_target = `ZERO_WORD;
                btb_change_enable = 1'b0;
            end
            default: begin
                jmp_target = `ZERO_WORD;
                jmp_enable = 0;
                btb_change_enable = 1'b0;
            end
        endcase
    end
end

endmodule
