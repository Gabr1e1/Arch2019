`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2019 06:19:09 PM
// Design Name: 
// Module Name: id
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


module id(
    input wire rst,
    input wire [`AddrLen - 1 : 0] pc,
    input wire [`InstLen - 1 : 0] inst,
    input wire [`RegLen - 1 : 0] reg1_data_i,
    input wire [`RegLen - 1 : 0] reg2_data_i,

//Forwarding result from EX
    input wire ex_reg_i,
    input wire [`RegAddrLen - 1 : 0] ex_reg_addr,
    input wire [`RegLen - 1 : 0] ex_reg_data,

//Forwarding result from MEM
    input wire mem_reg_i,
    input wire [`RegAddrLen - 1 : 0] mem_reg_addr,
    input wire [`RegLen - 1 : 0] mem_reg_data,

//To Register
    output reg [`RegAddrLen - 1 : 0] reg1_addr_o,
    output reg [`RegLen - 1 : 0] reg1_read_enable,
    output reg [`RegAddrLen - 1 : 0] reg2_addr_o,
    output reg [`RegLen - 1 : 0] reg2_read_enable,

//To next stage
    output reg [`RegLen - 1 : 0] reg1,
    output reg [`RegLen - 1 : 0] reg2,
    output reg [`RegLen - 1 : 0] Imm,
    output reg [`RegLen - 1 : 0] rd,
    output reg rd_enable,
    output reg [`OpCodeLen - 1 : 0] aluop,
    output reg [`OpSelLen - 1 : 0] alusel,
    output reg [3:0] width,
    );

    wire [`OpLen - 1 : 0] opcode = inst[`OpLen - 1 : 0];
    wire [`Funct3Len - 1 : 0] funct3 = inst[`Funct3];
    wire [`Funct7Len - 1 : 0] funct7 = inst[`Funct7];

//Decode: Get opcode, imm, rd, and the addr of rs1&rs2
always @ (*) begin
    if (rst == `ResetEnable) begin
        //TODO: RESET
    end
    else begin
        reg1_addr_o <= inst[19 : 15];
        reg2_addr_o <= inst[24 : 20];
    end

    case (opcode)
        `INTCOM_LUI: begin
            Imm <= { inst[31:12], {12{1'b0}} };
            rd <= inst[11 : 7];
            rd_enable <= `WriteEnable;
            aluop <= `OP_LUI;
            alusel <= `LUI_OP;
        end
        `INTCOM_AUIPC: begin
            Imm <= { inst[31:12], {12{1'b0}} };
            rd <= inst[11 : 7];
            rd_enable <= `WriteEnable;
            aluop <= `OP_LUI;
            alusel <= `LUI_OP;
        end
        `INTCOM_REG: begin
            Imm <= { {20{inst[31]}} ,inst[31:20] };
            reg1_read_enable <= `ReadEnable;
            reg2_read_enable <= `ReadDisable;
            rd <= inst[11 : 7];
            rd_enable <= `WriteEnable;
            alusel <= `Arith_OP;
            case (funct3)
                `ADDI:
                    aluop <= `OP_ADD;
                `SLLI: begin
                    aluop <= `OP_SLL;
                    Imm <= { {27{1'b0}}, inst[24:20] };
                end
                `SLTI:
                    aluop <= `OP_SLT;
                `SLTIU:
                    aluop <= `OP_SLTU;
                `XORI:
                    aluop <= `OP_XOR;
                `SRXI: begin
                    Imm <= { {27{1'b0}}, inst[24:20] };
                    case (funct7)
                        `SRLI:
                            aluop <= `OP_SRL;
                        `SRAI:
                            aluop <= `OP_SRA;                     
                        default: ;
                    endcase
                end
                `ORI:
                    aluop <= `OP_OR;
                `ANDI:
                    aluop <= `OP_AND;     
                default: ;
            endcase
        end
        `INTCOM_REGREG: begin
            reg1_read_enable <= `ReadEnable;
            reg2_read_enable <= `ReadEnable;
            rd <= inst[11 : 7];
            rd_enable <= `WriteEnable;
            aluop <= `Arith_OP;
            case (funct3)
                `ADDSUB: begin
                    case (funct7)
                        `ADD:
                            aluop <= `OP_ADD;
                        `SUB:
                            aluop <= `OP_SUB;
                        default: ;
                    endcase
                end
                `SLL:
                    aluop <= `OP_SLL;
                `SLT:
                    aluop <= `OP_SLT;
                `SLTIU:
                    aluop <= `OP_SLTU;
                `XOR:
                    aluop <= `OP_XOR;
                `SRX: begin
                    case (funct7)
                        `SRL:
                            aluop <= `OP_SRL;
                        `SRA:
                            aluop <= `OP_SRA;
                        default: ;
                    endcase
                end
                `OR:
                    aluop <= `OP_OR;
                `AND:
                    aluop <= `OP_AND;
                default: ;
            endcase
        end
        `LOAD: begin
            Imm <= { {20{inst[31]}} ,inst[31:20] };
            reg1_read_enable <= `ReadEnable;
            reg2_read_enable <= `ReadDisable;
            rd <= inst[11 : 7];
            rd_enable <= `WriteEnable;
            aluop <= `OP_ADD;
            alusel <= `LOAD_OP;
            case (funct3)
                `LB:
                    width <= 4'b0001;
                `LH:
                    width <= 4'b0010;
                `LW:
                    width <= 4'b0100;
                `LBU:
                    width <= 4'b0101;
                `LHU:
                    width <= 4'b0110;
                default: ;
            endcase
        end
        `SAVE: begin
            Imm <= { {20{inst[31]}} ,inst[31:25], inst[11:7] };
            reg1_read_enable <= `ReadEnable;
            reg2_read_enable <= `ReadDisable;
            rd <= inst[24 : 20];
            rd_enable <= `WriteEnable;
            aluop <= `OP_ADD;
            alusel <= `SAVE_OP;
            case (funct3)
                `SB:
                    width <= 4'b1001;
                `SH:
                    width <= 4'b1010;
                `SW:
                    width <= 4'b1100;
            endcase
        end

        default: begin
            rd_enable <= `WriteDisable;
            reg1_read_enable <= `ReadDisable;
            reg2_read_enable <= `ReadDisable;
        end 
    endcase
end

//Get rs1
always @ (*) begin
    if (rst == `ResetEnable) begin
        reg1 <= `ZERO_WORD;
    end
    else if (reg1_read_enable == `ReadDisable) begin
        reg1 <= `ZERO_WORD;
    end
    else if (reg1_read_enable == `ReadEnable) begin
        if (ex_reg_i == `ForwardEnable && ex_reg_addr == reg1_addr_o)
            reg1 <= ex_reg_data; 
        else if (mem_reg_i == `ForwardEnable && mem_reg_addr == reg1_addr_o)
            reg1 <= mem_reg_data;
        else reg1 <= reg1_data_i;
    end
end

//Get rs2
always @ (*) begin
    if (rst == `ResetEnable) begin
        reg2 <= `ZERO_WORD;
    end
    else if (reg2_read_enable == `ReadDisable) begin
        reg2 <= Imm;
    end
    else if (reg2_read_enable == `ReadEnable) begin
        if (ex_reg_i == `ForwardEnable && ex_reg_addr == reg2_addr_o)
            reg2 <= ex_reg_data; 
        else if (mem_reg_i == `ForwardEnable && mem_reg_addr == reg2_addr_o)
            reg2 <= mem_reg_data;
        else reg2 <= reg2_data_i;
    end
end

endmodule
