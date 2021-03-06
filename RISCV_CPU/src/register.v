`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2019 04:52:34 PM
// Design Name: 
// Module Name: register
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: supports 2 simultaneous read & 1 write
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



 module register(
    input wire clk,
    input wire rst,
    //write
    input wire write_enable,
    input wire [`RegAddrLen - 1 : 0] write_addr,
    input wire [`RegLen - 1 : 0] write_data,
    //read 1
    input wire read_enable1,   
    input wire [`RegAddrLen - 1 : 0] read_addr1,
    output reg [`RegLen - 1 : 0] read_data1,
    //read 2
    input wire read_enable2,   
    input wire [`RegAddrLen - 1 : 0] read_addr2,
    output reg [`RegLen - 1 : 0] read_data2
    );
    
    reg[`RegLen - 1 : 0] regs[`RegNum - 1 : 0];
    integer i;

//write 1
always @ (posedge clk) begin
    if (rst == `ResetEnable) begin
        for (i = 0; i < `RegNum; i = i + 1)
            regs[i] <= `ZERO_WORD;     
    end 
    else if (write_enable == `WriteEnable) begin
        if (write_addr != `RegAddrLen'b00000) begin //not zero register
            regs[write_addr] <= write_data;
//            $display("write reg %d %h",write_addr, write_data);
        end
    end
end

//read 1
always @ (*) begin
    if (rst == `ResetDisable && read_enable1 == `ReadEnable) begin
        if (read_addr1 == 0)
            read_data1 = `ZERO_WORD;
        else if (read_addr1 == write_addr && write_enable == `WriteEnable) //support "first half write, second half read"
            read_data1 = write_data;
        else
            read_data1 = regs[read_addr1];
    end
    else begin
        read_data1 = `ZERO_WORD;
    end
end

//read 2
always @ (*) begin
    if (rst == `ResetDisable && read_enable2 == `ReadEnable) begin
        if (read_addr2 == 0)
            read_data2 = `ZERO_WORD;
        else if (read_addr2 == write_addr && write_enable == `WriteEnable) //support "first half write, second half read"
            read_data2 = write_data;
        else
            read_data2 = regs[read_addr2];
    end
    else begin
        read_data2 = `ZERO_WORD;
    end
end

endmodule
