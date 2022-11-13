`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/13 19:17:24
// Design Name: 
// Module Name: axi_stream_insert_header
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


module axi_stream_insert_header #(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD),
    parameter DATA_DEPTH = 32														
    ) (
    input clk,
    input rst_n,
    // AXI Stream input original data
    input valid_in,
    input [DATA_WD-1 : 0] data_in,
    input [DATA_BYTE_WD-1 : 0] keep_in,
    input last_in,
    output ready_in,
    // AXI Stream output with header inserted
    output valid_out,
    output [DATA_WD-1 : 0] data_out,
    output [DATA_BYTE_WD-1 : 0] keep_out,
    output last_out,
    input ready_out,
    // The header to be inserted to AXI Stream input
    input valid_insert,
    input [DATA_WD-1 : 0] header_insert,
    input [DATA_BYTE_WD-1 : 0] keep_insert,
    input [BYTE_CNT_WD-1 : 0] byte_insert_cnt,										
    output ready_insert
);
// Your code here

	//计数器代替状态机
	reg		  [2:0]  flag_reg_now = 0;		  										//0 idle ,1 READ_HEADER ,2 WAIT_AXIS ,3 READ_AXIS
																					//4 WAIT_INSERT ,5 WRITE_NEW_AXIS ,6 TO_IDLE
	reg		  [2:0]  flag_reg_next = 0;	

	
    //store data
    reg [7:0] data_mem [0:DATA_DEPTH-1];											//32个字节形式即8bits的存储器
    reg [$clog2(DATA_DEPTH):0] front, rear;										
																					//front是用来除去开头无效的字节
																					//rear是用来记录存储器有效的末尾位置
    // output reg
    reg [DATA_WD-1 : 0]      data_out_reg;			
    reg [DATA_BYTE_WD-1 : 0] keep_out_reg;

    assign data_out     = data_out_reg;
    assign keep_out     = keep_out_reg;

    assign ready_insert = flag_reg_now == 3'd0 ? 1 : 0;
    assign ready_in     = flag_reg_now == 3'd3 ? 1 : 0;
    assign valid_out    = flag_reg_now == 3'd5 ? 1 : 0;
	assign last_out     = flag_reg_now == 3'd5 && front >= rear ? 1 : 0; 

	
	//模拟状态切换
	always @ (*)
		begin
			if ( flag_reg_now == 0 )	  											// 0 idle
				begin
					if( valid_insert == 1'b1 && ready_insert == 1'b1 )
						flag_reg_next = 3'd3;
					else
						flag_reg_next = 3'd0;
				end
			else if ( flag_reg_now == 3'd3 )	  									// 3 READ_AXIS
				begin
					if( last_in == 1'b1 )
						flag_reg_next = 3'd5;
					else
						flag_reg_next = 3'd3;
				end
			else if ( flag_reg_now == 3'd5 )	  									// 5 WRITE_NEW_AXIS
				begin
					if( last_out == 1'b1 )
						flag_reg_next = 3'd6;
					else
						flag_reg_next = 3'd5;
				end
			else if ( flag_reg_now == 3'd6 )	  									// 6 TO_IDLE
				begin
						flag_reg_next = 3'd0;
				end
			else 
						flag_reg_next = 3'd0;
		end

	always @(posedge clk or negedge rst_n) begin
		if ( rst_n == 1'b0 ) flag_reg_next <= 3'd0;
		else flag_reg_now <= flag_reg_next;        
	end


    // calculate the 1's number
    function [DATA_WD:0]swar;
        input [DATA_WD:0] data_in;
        reg [DATA_WD:0] i;
        begin
            i = data_in;
            i = (i & 32'h55555555) + ({0, i[DATA_WD:1]} & 32'h55555555);
            i = (i & 32'h33333333) + ({0, i[DATA_WD:2]} & 32'h33333333);
            i = (i & 32'h0F0F0F0F) + ({0, i[DATA_WD:4]} & 32'h0F0F0F0F);
            i = i * (32'h01010101);
            swar = i[31:24];    
        end        
    endfunction

	
	// data_mem initial
	genvar j;
    generate for (j = 5'd0; j < DATA_DEPTH; j=j+1) begin
        always @(posedge clk or negedge rst_n) begin
            if ( flag_reg_now == 3'd0 && flag_reg_next == 3'd0 )
                data_mem[j] <= 0;
            else if ( flag_reg_now == 3'd0 && j >= rear && j < rear + DATA_BYTE_WD )
                data_mem[j] <= header_insert[DATA_WD - 1 - (j-rear) * 8 -: 8];		//将插入的帧头加入存储器
            else if ( flag_reg_now == 3'd3 && ready_in == 1'b1 && valid_in == 1'b1 && j >= rear && j < rear + DATA_BYTE_WD)                
                data_mem[j] <= data_in[DATA_WD - 1 -(j-rear) * 8 -: 8];				//将输入data_in数据加入存储器
            else
                data_mem[j] <= data_mem[j];
        end
    end
    endgenerate


	//front	有效字节开始位置
	always @(posedge clk or negedge rst_n) begin
		if ( flag_reg_now == 3'd0 && flag_reg_next == 3'd0 )
            front <= 0;
        else if ( flag_reg_now == 3'd0 && flag_reg_next == 3'd3 )
            front <= front + DATA_BYTE_WD - swar(keep_insert);						//除去帧头无效的位，记录位置
        else if ( flag_reg_now == 3'd3 && flag_reg_next != 3'd3 && ready_out || flag_reg_now == 3'd5 )
            front <= front + DATA_BYTE_WD;											//读数据时，循环增加 DATA_BYTE_WD
        else 
            front <= front;
	end


	//rear	有效字节结束位置
	always @(posedge clk or negedge rst_n) begin
		if (  flag_reg_now == 3'd0 && flag_reg_next == 3'd0 )
            rear <= 0;
        else if ( flag_reg_now == 3'd0 && flag_reg_next == 3'd3 )
            rear <= rear + DATA_BYTE_WD;											//记录存储器存储的字节个数
        else if ( flag_reg_now == 3'd3 )            
            rear <= rear + swar(keep_in);											//最后一个data_in有无效字节，需要特殊计算
        else
            rear <= rear;         
	end

	
	//读取数据
	genvar i;
    generate for (i = 2'd0; i < DATA_BYTE_WD; i=i+1) begin
        always @(posedge clk or negedge rst_n) begin
            if ( flag_reg_now == 3'd0 )
                data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8] <= 0;
            else if ( flag_reg_next == 3'd5 )
                data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8] <= data_mem[front+i];       
            else
                data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8] <= data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8];       
        end
    end
    endgenerate

	
	//输出数据的有效位
	generate for (i = 2'd0; i < DATA_BYTE_WD; i=i+1) begin
        always @(posedge clk or negedge rst_n) begin
            if ( flag_reg_now == 3'd0 )
                keep_out_reg[i] <= 0;
            else if ( flag_reg_next == 3'd5 )
                keep_out_reg[DATA_BYTE_WD-i-1] <= front + i < rear ? 1 : 0;       
            else
                keep_out_reg[i] <= keep_out_reg[i];     
        end
    end
    endgenerate

endmodule
