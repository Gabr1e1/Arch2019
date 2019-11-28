`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2019 01:20:44 PM
// Design Name: 
// Module Name: if_stage
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


module if_stage(
    input wire rst,
    input wire clk,
    input wire [`AddrLen - 1 : 0] pc,
    output reg [`AddrLen - 1 : 0] pc_o,
    output reg [`InstLen - 1 : 0] inst,
    
    output reg [`InstLen - 1 : 0] addr_to_mem,
    output reg rw,  
    input wire [`AddrLen - 1 : 0] data_from_mem,
    input wire [1:0] mem_status,
//Cache 
    input wire cacheHit,
    input wire [`RegLen - 1 : 0] cacheVal,
    
    input wire [`PipelineDepth - 1 : 0] stall,
    input wire enable_pc,
    output reg stallreq,

    output wire [`AddrLen - 1 : 0] prediction,
    output wire pred_enable
    );
    
    wire [`OpLen - 1 : 0] opcode;
    assign opcode = inst[`OpLen - 1 : 0];
    assign pred_enable = ((opcode == `JAL) || (opcode == `BRANCH));
    assign isBranch = (opcode == `BRANCH);
    assign isLoad = (opcode == `LOAD);
    assign prediction = pc + 4;//(isBranch ? (pc_o + { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 })
//                                 : (pc_o + { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 }));
    
//    integer count;
    
always @ (*) begin
    if (rst == `ResetEnable) begin
        rw <= 1'b0;
        addr_to_mem <= `ZERO_WORD;
        stallreq <= `StallDisable;
//        count = 0;
    end
    else begin
        if (mem_status == `DONE) begin
            inst <= data_from_mem;
            stallreq <= `StallDisable;
            rw <= 1'b0;
        end
        else if (mem_status == `IDLE && enable_pc) begin
            addr_to_mem = pc;
            pc_o = pc;
            if ((!cacheHit) || isLoad) begin
                rw <= 1'b1;
                stallreq <= `StallEnable;
//                if (isLoad)
//                    count = count + 1;
            end
            else begin
                inst <= cacheVal;
                stallreq <= `StallDisable;
                rw <= 1'b0;
            end
        end
    end
end

endmodule
