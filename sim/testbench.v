`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/13 19:00:55
// Design Name: 
// Module Name: testbench
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

module tb_axi_stream_insert_header; parameter PERIOD = 10 ; parameter DATA_WD = 32 ; parameter DATA_BYTE_WD = DATA_WD / 8 ; parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);
    				    parameter tb_datain_depth = 4;			
    reg   clk                                = 0 ;
    reg   rst_n                              = 0 ;
    // axi_stream_insert_header_1 Inputs
    reg   valid_in_1                           = 0 ;
    reg   [DATA_WD-1 : 0]  data_in_1           = 0 ;
    reg   [DATA_BYTE_WD-1 : 0]  keep_in_1      = 0 ;
    // reg   ready_out                         = 1 ;
    reg   valid_insert_1                       = 0 ;
    reg   [DATA_WD-1 : 0]  header_insert_1     = 0 ;
    reg   [DATA_BYTE_WD-1 : 0]  keep_insert_1  = 0 ;
    reg   [BYTE_CNT_WD : 0]  byte_insert_cnt_1 = 0 ;
    
    // axi_stream_insert_header_1 Outputs
    wire  ready_in_1                             ;
    wire  valid_out_1                            ;
    wire  [DATA_WD-1 : 0]  data_out_1            ;
    wire  [DATA_BYTE_WD-1 : 0]  keep_out_1       ;
    wire  last_out_1                             ;
    wire  ready_insert_1                         ;
    wire  last_in_1                              ;
 
    // axi_stream_insert_header_2 Inputs
    //reg   valid_in_2                         = 0 ;
    //reg   [DATA_WD-1 : 0]  data_in_2         = 0 ;
    //reg   [DATA_BYTE_WD-1 : 0]  keep_in_2    = 0 ;
    reg   ready_out_2                          = 1 ;
    reg   valid_insert_2                       = 0 ;
    reg   [DATA_WD-1 : 0]  header_insert_2     = 0 ;
    reg   [DATA_BYTE_WD-1 : 0]  keep_insert_2  = 0 ;
    reg   [BYTE_CNT_WD : 0]  byte_insert_cnt_2 = 0 ;
    
    // axi_stream_insert_header_2 Outputs
    wire  ready_in_2                             ;
    wire  valid_out_2                            ;
    wire  [DATA_WD-1 : 0]  data_out_2            ;
    wire  [DATA_BYTE_WD-1 : 0]  keep_out_2       ;
    wire  last_out_2                             ;
    wire  ready_insert_2                         ;
    //wire  last_in_2                            ;
	
	integer seed;
	
	initial
	begin
		seed = 2;
	end
    
	initial
    begin
        forever #(PERIOD/2)  clk = ~clk;
    end
    
    initial
    begin
        #(PERIOD*2) rst_n = 1;
    end
    
    axi_stream_insert_header #(
    .DATA_WD      (DATA_WD),
    .DATA_BYTE_WD (DATA_BYTE_WD),
    .BYTE_CNT_WD  (BYTE_CNT_WD))
    u_axi_stream_insert_header_1 (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .valid_in                (valid_in_1),
    .data_in                 (data_in_1          [DATA_WD-1 : 0]),
    .keep_in                 (keep_in_1          [DATA_BYTE_WD-1 : 0]),
    .last_in                 (last_in_1),
    .ready_out               (ready_in_2),
    .valid_insert            (valid_insert_1),
    .header_insert           (header_insert_1    [DATA_WD-1 : 0]),
    .keep_insert             (keep_insert_1      [DATA_BYTE_WD-1 : 0]),
    .byte_insert_cnt         (byte_insert_cnt_1  [BYTE_CNT_WD : 0]),
    
    .ready_in                (ready_in_1),
    .valid_out               (valid_out_1),
    .data_out                (data_out_1         [DATA_WD-1 : 0]),
    .keep_out                (keep_out_1         [DATA_BYTE_WD-1 : 0]),
    .last_out                (last_out_1),
    .ready_insert            (ready_insert_1)
    );
    
    axi_stream_insert_header #(
    .DATA_WD      (DATA_WD),
    .DATA_BYTE_WD (DATA_BYTE_WD),
    .BYTE_CNT_WD  (BYTE_CNT_WD))
    u_axi_stream_insert_header_2 (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .valid_in                (valid_out_1),
    .data_in                 (data_out_1          [DATA_WD-1 : 0]),
    .keep_in                 (keep_out_1          [DATA_BYTE_WD-1 : 0]),
    .last_in                 (last_out_1),
    .ready_out               (ready_out_2),
    .valid_insert            (valid_insert_2),
    .header_insert           (header_insert_2    [DATA_WD-1 : 0]),
    .keep_insert             (keep_insert_2      [DATA_BYTE_WD-1 : 0]),
    .byte_insert_cnt         (byte_insert_cnt_2  [BYTE_CNT_WD : 0]),
    
    .ready_in                (ready_in_2),
    .valid_out               (valid_out_2),
    .data_out                (data_out_2         [DATA_WD-1 : 0]),
    .keep_out                (keep_out_2         [DATA_BYTE_WD-1 : 0]),
    .last_out                (last_out_2),
    .ready_insert            (ready_insert_2)
    );
	
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
		begin
			valid_insert_1            <= 0;
			valid_insert_2            <= 0;
		end
        else
		begin
		 	valid_insert_1 <= { $random(seed) } % 2;
			valid_insert_2 <= { $random(seed) } % 2;
		end
     end
    
    always @(posedge clk or negedge rst_n) begin
            if (!rst_n) ready_out_2            <= 0;
            else ready_out_2 <= { $random(seed) } % 2;
    end
    
    reg [3:0] cnt = 0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_in_1 <= 32'h0;
        else if (ready_in)
        case(cnt)
            0: data_in_1       <= $random(seed);
            1: data_in_1       <= $random(seed);
            2: data_in_1       <= $random(seed);
            3: data_in_1       <= $random(seed);
            4: data_in_1       <= $random(seed);
            default: data_in_1 <= 0;
        endcase
        else data_in_1 <= data_in_1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) keep_in_1 <= 0;
        else if (ready_in_1)
        case(cnt)
            0: keep_in_1       <= 4'b1111;
            1: keep_in_1       <= 4'b1111;
            2: keep_in_1       <= 4'b1111;
            3: keep_in_1       <= 4'b1111;
            4: keep_in_1       <= {$random(seed)}%2?({$random(seed)}%2?4'b1111:4'b1110):({$random(seed)}%2?4'b1100:4'b1000);
            default: keep_in_1 <= 0;
        endcase
        else keep_in_1 <= keep_in_1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_in_1 <= 0;
        else if (ready_in_1)
        case(cnt)
            0: valid_in_1       <= 1;
            1: valid_in_1       <= 1;
            2: valid_in_1       <= 1;
            3: valid_in_1       <= 1;
            4: valid_in_1       <= 1;
            default: valid_in_1 <= 0;
        endcase
        else valid_in_1 <= valid_in_1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 0;
	else if (ready_in_1 && cnt == 0)          cnt <= cnt + 1;
	else if (ready_in_1 && valid_in_1)        cnt <= cnt + 1;
	else if ( cnt == (tb_datain_depth + 1))   cnt <= 0      ;
        else                                      cnt <= cnt    ;
    end
    
    assign last_in = cnt == tb_datain_depth ? 1 : 0;
    
    initial
    begin
        header_insert   = $random(seed);
        keep_insert     = {$random(seed)}%2?({$random(seed)}%2?4'b0001:4'b0011):({$random(seed)}%2?4'b0111:4'b1111);
        #(PERIOD*200)
        $finish;
    end
    
endmodule
