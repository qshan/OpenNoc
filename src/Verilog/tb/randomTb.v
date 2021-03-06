//`include "include_file.v"
`timescale 1ps/1ps

`define X 8
`define Y 8
`define x_size $clog2(`X)
`define y_size $clog2(`Y)
`define data_width 32
`define total_width (`x_size+`y_size+`data_width)
`define numPackets 100
`define injectRate 1
`define pattern "RANDOM"
`define clkPeriod 2631


module randomTb();
reg  clk;
reg rst;
wire done;
wire [(`X*`Y)-1:0] r_valid_pe;
wire [(`total_width*`X*`Y)-1:0] r_data_pe;
wire [(`X*`Y)-1:0] r_ready_pe;
wire [(`X*`Y)-1:0] w_valid_pe;
wire [(`total_width*`X*`Y)-1:0] w_data_pe;
wire [(32*`X*`Y)-1:0] receiveCount;
integer startTime;
reg  start;
reg [(`X*`Y)-1:0] enableSend;
integer               receive_log_file;
reg   [100*8:0]       receive_log_file_name = "receive_log.csv";

integer               receive_log_file;
reg   [100*8:0]       receive_log_file_name = "receive_log.csv";

initial
begin
 clk = 1'b0;
 forever
 begin
    clk = ~clk;
	#(`clkPeriod/2);
 end
end

initial
begin
    receive_log_file = $fopen(receive_log_file_name,"w");
    $fwrite(receive_log_file,"%s,%s,%s,%s,%s\n","Source PE","Destination PE","Inject Time","Receive Time","Latency(clock cycles)");
    $fflush(receive_log_file);
    rst = 0;
    receive_log_file = $fopen(receive_log_file_name,"w");
    #10;
    rst = 1;
    enableSend = {(`X*`Y){1'b1}};
    start = 1'b1;
	startTime = $time;
end



openNocTop #(.X(`X),.Y(`Y),.data_width(`data_width), .x_size(`x_size),.y_size(`y_size))
ON
(
.clk(clk),
.rstn(rst),
.r_valid_pe(r_valid_pe),
.r_data_pe(r_data_pe),
.r_ready_pe(r_ready_pe),
.w_valid_pe(w_valid_pe),
.w_data_pe(w_data_pe)
);

randomPeTop #(.X(`X),.Y(`Y),.data_width(`data_width), .x_size(`x_size),.y_size(`y_size),.numPackets(`numPackets),.rate(`injectRate),.pat(`pattern)) 
rPeT(
.clk(clk),
.rstn(rst),
//PE interfaces
.r_valid_pe(r_valid_pe),
.r_data_pe(r_data_pe),
.r_ready_pe(r_ready_pe),
.w_valid_pe(w_valid_pe),
.w_data_pe(w_data_pe),
.done(done),
.start(start),
.enableSend(enableSend),
.receiveCount(receiveCount)
);

wire noReadOp;
wire noWriteOp;

assign noReadOp = ~(|r_valid_pe);
assign noWriteOp = ~(|w_valid_pe);

integer receivedPkts;
integer i;

always @(posedge clk)
begin
    receivedPkts = 0;
	for(i=0;i<`X*`Y;i=i+1)
    begin
        receivedPkts = receivedPkts+receiveCount[i*32+:32];
    end
end

initial
begin
    wait(!done);
	wait(done);
	//$display("Simulation finished at",,,,$time);
	wait(receivedPkts==`X*`Y*`numPackets);
	$display("------------------------------------------------------------");
	$display("Total Packets transmitted:\t%0d",`X*`Y*`numPackets);
	$display("Total Packets received:\t\t%0d",receivedPkts);
	$display("NoC configuration:\t\t %0dx%0d",`X,`Y);
	$display("Max Throughput:\t\t\t %f packets/cycle/pe",(1.0/`injectRate));
	$display("Achieved Throughput:\t %f Million packets/sec",(`X*`Y*`numPackets*1.0*1000000)/($time-startTime));
	$display("Efficiency:\t\t\t\t %f",((`numPackets*`X*`Y*100.0)/(($time-startTime)/`clkPeriod))/(`X*`Y*1.0/`injectRate));
	$display("------------------------------------------------------------");
	start = 0;
	#500;
	$fflush(receive_log_file);
	$fclose(receive_log_file);
	$stop;
end
 
 
endmodule

