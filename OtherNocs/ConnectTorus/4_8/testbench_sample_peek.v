/*
 * These source files contain a hardware description of a network
 * automatically generated by CONNECT (CONfigurable NEtwork Creation Tool).
 *
 * This product includes a hardware design developed by Carnegie Mellon
 * University.
 *
 * Copyright (c) 2012 by Michael K. Papamichael, Carnegie Mellon University
 *
 * For more information, see the CONNECT project website at:
 *   http://www.ece.cmu.edu/~mpapamic/connect
 *
 * This design is provided for internal, non-commercial research use only, 
 * cannot be used for, or in support of, goods or services, and is not for
 * redistribution, with or without modifications.
 * 
 * You may not use the name "Carnegie Mellon University" or derivations
 * thereof to endorse or promote products derived from this software.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY WARRANTY OF ANY KIND, EITHER
 * EXPRESS, IMPLIED OR STATUTORY, INCLUDING BUT NOT LIMITED TO ANY WARRANTY
 * THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS OR BE ERROR-FREE AND ANY
 * IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 * TITLE, OR NON-INFRINGEMENT.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
 * BE LIABLE FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT,
 * SPECIAL OR CONSEQUENTIAL DAMAGES, ARISING OUT OF, RESULTING FROM, OR IN
 * ANY WAY CONNECTED WITH THIS SOFTWARE (WHETHER OR NOT BASED UPON WARRANTY,
 * CONTRACT, TORT OR OTHERWISE).
 *
 */


/* =========================================================================
 * 
 * Filename:            testbench_sample.v
 * Date created:        05-28-2012
 * Last modified:       11-30-2012
 * Authors:		Michael Papamichael <papamixATcs.cmu.edu>
 *
 * Description:
 * Minimal testbench sample for CONNECT networks with Peek flow control
 * 
 * =========================================================================
 */

`ifndef XST_SYNTH

`timescale 1ps / 1ps

`include "connect_parameters.v"
`define NUMPE 32
`define PktLmit 65
`define expectedPkts `NUMPE*`PktLmit

module CONNECT_testbench_sample_peek();
  parameter HalfClkPeriod = 3546;
  localparam ClkPeriod = 2*HalfClkPeriod;

  // non-VC routers still reeserve 1 dummy bit for VC.
  localparam vc_bits = (`NUM_VCS > 1) ? $clog2(`NUM_VCS) : 1;
  localparam dest_bits = $clog2(`NUM_USER_RECV_PORTS);
  localparam flit_port_width = 2 /*valid and tail bits*/+ `FLIT_DATA_WIDTH + dest_bits + vc_bits;
  //localparam credit_port_width = 1 + vc_bits; // 1 valid bit
  localparam credit_port_width = `NUM_VCS; // 1 valid bit
  localparam test_cycles = 20;

  reg Clk;
  reg Rst_n;

  // input regs
  wire send_flit [0:`NUM_USER_SEND_PORTS-1]; // enable sending flits
  wire [flit_port_width-1:0] flit_in [0:`NUM_USER_SEND_PORTS-1]; // send port inputs

  reg send_credit [0:`NUM_USER_RECV_PORTS-1]; // enable sending credits
  reg [credit_port_width-1:0] credit_in [0:`NUM_USER_RECV_PORTS-1]; //recv port credits

  // output wires
  wire [credit_port_width-1:0] credit_out [0:`NUM_USER_SEND_PORTS-1];
  wire [flit_port_width-1:0] flit_out [0:`NUM_USER_RECV_PORTS-1];

  reg [31:0] cycle;
  integer i;

  // packet fields
  reg is_valid;
  reg is_tail;
  reg [dest_bits-1:0] dest;
  reg [vc_bits-1:0]   vc;
  reg [`FLIT_DATA_WIDTH-1:0] data;
  
  reg done = 0;
  reg [31:0] receivedPkts=0;
  integer receive_log_file;
  
  integer start,stop,delay;
  reg   [100*8:0]       receive_log_file_name = "receive_log.csv";

  // Generate Clock
  initial Clk = 0;
  always #(HalfClkPeriod) Clk = ~Clk;

  // Run simulation 
  initial begin 
    receive_log_file = $fopen(receive_log_file_name,"w");
    cycle = 0;
    $display("---- Performing Reset ----");
    Rst_n = 1; // perform reset (active low) 
    #(5*ClkPeriod+HalfClkPeriod); 
    Rst_n = 0; 
    wait(send_flit[0]);
    start = $time;
  end


  // Monitor arriving flits
  always @ (posedge Clk) begin
    cycle <= cycle + 1;
    for(i = 0; i < `NUM_USER_RECV_PORTS; i = i + 1) begin
      if(flit_out[i][flit_port_width-1]) begin // valid flit
        //$display("@%3d: Ejecting flit %x at receive port %0d", cycle, flit_out[i], i);
        receivedPkts = receivedPkts + 1;
      end

    // terminate simulation
        if(receivedPkts == `expectedPkts)
        begin
            done = 1;
            stop = $time;
            $display("Start time %d Stop time %d",start,stop);
            $display("Throughput : %f",`expectedPkts*1.0*1000000/((stop-start)));
            #1000;
            $stop;
        end
    end
  end

  // Add your code to handle flow control here (sending receiving credits)

  // Instantiate CONNECT network
  mkNetworkSimple dut
  (.CLK(Clk)
   ,.RST_N(!Rst_n)

   ,.send_ports_0_putFlit_flit_in(flit_in[0])
   ,.EN_send_ports_0_putFlit(send_flit[0])

   ,.EN_send_ports_0_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_0_getNonFullVCs(credit_out[0])

   ,.send_ports_1_putFlit_flit_in(flit_in[1])
   ,.EN_send_ports_1_putFlit(send_flit[1])

   ,.EN_send_ports_1_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_1_getNonFullVCs(credit_out[1])
   
   ,.send_ports_2_putFlit_flit_in(flit_in[2])
   ,.EN_send_ports_2_putFlit(send_flit[2])

   ,.EN_send_ports_2_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_2_getNonFullVCs(credit_out[2])
   
   ,.send_ports_3_putFlit_flit_in(flit_in[3])
   ,.EN_send_ports_3_putFlit(send_flit[3])

   ,.EN_send_ports_3_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_3_getNonFullVCs(credit_out[3])   
   
   ,.send_ports_4_putFlit_flit_in(flit_in[4])
   ,.EN_send_ports_4_putFlit(send_flit[4])

   ,.EN_send_ports_4_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_4_getNonFullVCs(credit_out[4])

   ,.send_ports_5_putFlit_flit_in(flit_in[5])
   ,.EN_send_ports_5_putFlit(send_flit[5])

   ,.EN_send_ports_5_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_5_getNonFullVCs(credit_out[5])
   
   ,.send_ports_6_putFlit_flit_in(flit_in[6])
   ,.EN_send_ports_6_putFlit(send_flit[6])

   ,.EN_send_ports_6_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_6_getNonFullVCs(credit_out[6])   
   
   ,.send_ports_7_putFlit_flit_in(flit_in[7])
   ,.EN_send_ports_7_putFlit(send_flit[7])

   ,.EN_send_ports_7_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_7_getNonFullVCs(credit_out[7])   
   
   ,.send_ports_8_putFlit_flit_in(flit_in[8])
   ,.EN_send_ports_8_putFlit(send_flit[8])

   ,.EN_send_ports_8_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_8_getNonFullVCs(credit_out[8])

   ,.send_ports_9_putFlit_flit_in(flit_in[9])
   ,.EN_send_ports_9_putFlit(send_flit[9])

   ,.EN_send_ports_9_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_9_getNonFullVCs(credit_out[9])
   
   ,.send_ports_10_putFlit_flit_in(flit_in[10])
   ,.EN_send_ports_10_putFlit(send_flit[10])

   ,.EN_send_ports_10_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_10_getNonFullVCs(credit_out[10])
   
   ,.send_ports_11_putFlit_flit_in(flit_in[11])
   ,.EN_send_ports_11_putFlit(send_flit[11])

   ,.EN_send_ports_11_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_11_getNonFullVCs(credit_out[11])   
   
   ,.send_ports_12_putFlit_flit_in(flit_in[12])
   ,.EN_send_ports_12_putFlit(send_flit[12])

   ,.EN_send_ports_12_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_12_getNonFullVCs(credit_out[12])

   ,.send_ports_13_putFlit_flit_in(flit_in[13])
   ,.EN_send_ports_13_putFlit(send_flit[13])

   ,.EN_send_ports_13_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_13_getNonFullVCs(credit_out[13])
   
   ,.send_ports_14_putFlit_flit_in(flit_in[14])
   ,.EN_send_ports_14_putFlit(send_flit[14])

   ,.EN_send_ports_14_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_14_getNonFullVCs(credit_out[14])   
   
   ,.send_ports_15_putFlit_flit_in(flit_in[15])
   ,.EN_send_ports_15_putFlit(send_flit[15])

   ,.EN_send_ports_15_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_15_getNonFullVCs(credit_out[15])


   ,.send_ports_16_putFlit_flit_in(flit_in[16])
   ,.EN_send_ports_16_putFlit(send_flit[16])

   ,.EN_send_ports_16_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_16_getNonFullVCs(credit_out[16])

   ,.send_ports_17_putFlit_flit_in(flit_in[17])
   ,.EN_send_ports_17_putFlit(send_flit[17])

   ,.EN_send_ports_17_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_17_getNonFullVCs(credit_out[17])
   
   ,.send_ports_18_putFlit_flit_in(flit_in[18])
   ,.EN_send_ports_18_putFlit(send_flit[18])

   ,.EN_send_ports_18_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_18_getNonFullVCs(credit_out[18])
   
   ,.send_ports_19_putFlit_flit_in(flit_in[19])
   ,.EN_send_ports_19_putFlit(send_flit[19])

   ,.EN_send_ports_19_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_19_getNonFullVCs(credit_out[19])   
   
   ,.send_ports_20_putFlit_flit_in(flit_in[20])
   ,.EN_send_ports_20_putFlit(send_flit[20])

   ,.EN_send_ports_20_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_20_getNonFullVCs(credit_out[20])

   ,.send_ports_21_putFlit_flit_in(flit_in[21])
   ,.EN_send_ports_21_putFlit(send_flit[21])

   ,.EN_send_ports_21_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_21_getNonFullVCs(credit_out[21])
   
   ,.send_ports_22_putFlit_flit_in(flit_in[22])
   ,.EN_send_ports_22_putFlit(send_flit[22])

   ,.EN_send_ports_22_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_22_getNonFullVCs(credit_out[22])   
   
   ,.send_ports_23_putFlit_flit_in(flit_in[23])
   ,.EN_send_ports_23_putFlit(send_flit[23])

   ,.EN_send_ports_23_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_23_getNonFullVCs(credit_out[23])   
   
   ,.send_ports_24_putFlit_flit_in(flit_in[24])
   ,.EN_send_ports_24_putFlit(send_flit[24])

   ,.EN_send_ports_24_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_24_getNonFullVCs(credit_out[24])

   ,.send_ports_25_putFlit_flit_in(flit_in[25])
   ,.EN_send_ports_25_putFlit(send_flit[25])

   ,.EN_send_ports_25_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_25_getNonFullVCs(credit_out[25])
   
   ,.send_ports_26_putFlit_flit_in(flit_in[26])
   ,.EN_send_ports_26_putFlit(send_flit[26])

   ,.EN_send_ports_26_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_26_getNonFullVCs(credit_out[26])
   
   ,.send_ports_27_putFlit_flit_in(flit_in[27])
   ,.EN_send_ports_27_putFlit(send_flit[27])

   ,.EN_send_ports_27_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_27_getNonFullVCs(credit_out[27])   
   
   ,.send_ports_28_putFlit_flit_in(flit_in[28])
   ,.EN_send_ports_28_putFlit(send_flit[28])

   ,.EN_send_ports_28_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_28_getNonFullVCs(credit_out[28])

   ,.send_ports_29_putFlit_flit_in(flit_in[29])
   ,.EN_send_ports_29_putFlit(send_flit[29])

   ,.EN_send_ports_29_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_29_getNonFullVCs(credit_out[29])
   
   ,.send_ports_30_putFlit_flit_in(flit_in[30])
   ,.EN_send_ports_30_putFlit(send_flit[30])

   ,.EN_send_ports_30_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_30_getNonFullVCs(credit_out[30])   
   
   ,.send_ports_31_putFlit_flit_in(flit_in[31])
   ,.EN_send_ports_31_putFlit(send_flit[31])

   ,.EN_send_ports_31_getNonFullVCs(1'b1) // drain credits
   ,.send_ports_31_getNonFullVCs(credit_out[31])


   // add rest of send ports here
   //

   ,.EN_recv_ports_0_getFlit(1'b1) // drain flits
   ,.recv_ports_0_getFlit(flit_out[0])

   ,.recv_ports_0_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_0_putNonFullVCs(1'b1)

   ,.EN_recv_ports_1_getFlit(1'b1) // drain flits
   ,.recv_ports_1_getFlit(flit_out[1])

   ,.recv_ports_1_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_1_putNonFullVCs(1'b1)

   ,.EN_recv_ports_2_getFlit(1'b1) // drain flits
   ,.recv_ports_2_getFlit(flit_out[2])

   ,.recv_ports_2_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_2_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_3_getFlit(1'b1) // drain flits
   ,.recv_ports_3_getFlit(flit_out[3])

   ,.recv_ports_3_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_3_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_4_getFlit(1'b1) // drain flits
   ,.recv_ports_4_getFlit(flit_out[4])

   ,.recv_ports_4_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_4_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_5_getFlit(1'b1) // drain flits
   ,.recv_ports_5_getFlit(flit_out[5])

   ,.recv_ports_5_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_5_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_6_getFlit(1'b1) // drain flits
   ,.recv_ports_6_getFlit(flit_out[6])

   ,.recv_ports_6_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_6_putNonFullVCs(1'b1)
   
   
   ,.EN_recv_ports_7_getFlit(1'b1) // drain flits
   ,.recv_ports_7_getFlit(flit_out[7])

   ,.recv_ports_7_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_7_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_8_getFlit(1'b1) // drain flits
   ,.recv_ports_8_getFlit(flit_out[8])

   ,.recv_ports_8_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_8_putNonFullVCs(1'b1)

   ,.EN_recv_ports_9_getFlit(1'b1) // drain flits
   ,.recv_ports_9_getFlit(flit_out[9])

   ,.recv_ports_9_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_9_putNonFullVCs(1'b1)

   // add rest of receive ports here
   // 
   ,.EN_recv_ports_10_getFlit(1'b1) // drain flits
   ,.recv_ports_10_getFlit(flit_out[10])

   ,.recv_ports_10_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_10_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_11_getFlit(1'b1) // drain flits
   ,.recv_ports_11_getFlit(flit_out[11])

   ,.recv_ports_11_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_11_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_12_getFlit(1'b1) // drain flits
   ,.recv_ports_12_getFlit(flit_out[12])

   ,.recv_ports_12_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_12_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_13_getFlit(1'b1) // drain flits
   ,.recv_ports_13_getFlit(flit_out[13])

   ,.recv_ports_13_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_13_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_14_getFlit(1'b1) // drain flits
   ,.recv_ports_14_getFlit(flit_out[14])

   ,.recv_ports_14_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_14_putNonFullVCs(1'b1)
   
   
   ,.EN_recv_ports_15_getFlit(1'b1) // drain flits
   ,.recv_ports_15_getFlit(flit_out[15])

   ,.recv_ports_15_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_15_putNonFullVCs(1'b1)

   ,.EN_recv_ports_16_getFlit(1'b1) // drain flits
   ,.recv_ports_16_getFlit(flit_out[16])

   ,.recv_ports_16_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_16_putNonFullVCs(1'b1)

   ,.EN_recv_ports_17_getFlit(1'b1) // drain flits
   ,.recv_ports_17_getFlit(flit_out[17])

   ,.recv_ports_17_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_17_putNonFullVCs(1'b1)

   ,.EN_recv_ports_18_getFlit(1'b1) // drain flits
   ,.recv_ports_18_getFlit(flit_out[18])

   ,.recv_ports_18_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_18_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_19_getFlit(1'b1) // drain flits
   ,.recv_ports_19_getFlit(flit_out[19])

   ,.recv_ports_19_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_19_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_20_getFlit(1'b1) // drain flits
   ,.recv_ports_20_getFlit(flit_out[20])

   ,.recv_ports_20_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_20_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_21_getFlit(1'b1) // drain flits
   ,.recv_ports_21_getFlit(flit_out[21])

   ,.recv_ports_21_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_21_putNonFullVCs(1'b1)
   
   
   ,.EN_recv_ports_22_getFlit(1'b1) // drain flits
   ,.recv_ports_22_getFlit(flit_out[22])

   ,.recv_ports_22_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_22_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_23_getFlit(1'b1) // drain flits
   ,.recv_ports_23_getFlit(flit_out[23])

   ,.recv_ports_23_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_23_putNonFullVCs(1'b1)

   ,.EN_recv_ports_24_getFlit(1'b1) // drain flits
   ,.recv_ports_24_getFlit(flit_out[24])

   ,.recv_ports_24_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_24_putNonFullVCs(1'b1)

   // add rest of receive ports here
   // 
   ,.EN_recv_ports_25_getFlit(1'b1) // drain flits
   ,.recv_ports_25_getFlit(flit_out[25])

   ,.recv_ports_25_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_25_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_26_getFlit(1'b1) // drain flits
   ,.recv_ports_26_getFlit(flit_out[26])

   ,.recv_ports_26_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_26_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_27_getFlit(1'b1) // drain flits
   ,.recv_ports_27_getFlit(flit_out[27])

   ,.recv_ports_27_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_27_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_28_getFlit(1'b1) // drain flits
   ,.recv_ports_28_getFlit(flit_out[28])

   ,.recv_ports_28_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_28_putNonFullVCs(1'b1)
   
   ,.EN_recv_ports_29_getFlit(1'b1) // drain flits
   ,.recv_ports_29_getFlit(flit_out[29])

   ,.recv_ports_29_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_29_putNonFullVCs(1'b1)
   
   
   ,.EN_recv_ports_30_getFlit(1'b1) // drain flits
   ,.recv_ports_30_getFlit(flit_out[30])

   ,.recv_ports_30_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_30_putNonFullVCs(1'b1)

   ,.EN_recv_ports_31_getFlit(1'b1) // drain flits
   ,.recv_ports_31_getFlit(flit_out[31])

   ,.recv_ports_31_putNonFullVCs_nonFullVCs(2'b11)
   ,.EN_recv_ports_31_putNonFullVCs(1'b1)
   );

   
   
   
pe #(.address(0),.PktLmit(`PktLmit))pe0(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[0]),
    .i_data_valid(flit_out[0][39]),
    .o_data_ready(o_pe0_data_ready),
    .o_data(flit_in[0]),
    .o_data_valid(send_flit[0]),
    .i_data_ready(credit_out[0]),
    .done(done)
);

pe #(.address(1),.PktLmit(`PktLmit))pe1(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[1]),
    .i_data_valid(flit_out[1][39]),
    .o_data_ready(o_pe1_data_ready),
    .o_data(flit_in[1]),
    .o_data_valid(send_flit[1]),
    .i_data_ready(credit_out[1]),
    .done(done)
);

pe #(.address(2),.PktLmit(`PktLmit))pe2(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[2]),
    .i_data_valid(flit_out[2][39]),
    .o_data_ready(o_pe2_data_ready),
    .o_data(flit_in[2]),
    .o_data_valid(send_flit[2]),
    .i_data_ready(credit_out[2]),
    .done(done)
);

pe #(.address(3),.PktLmit(`PktLmit))pe3(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[3]),
    .i_data_valid(flit_out[3][39]),
    .o_data_ready(o_pe3_data_ready),
    .o_data(flit_in[3]),
    .o_data_valid(send_flit[3]),
    .i_data_ready(credit_out[3]),
    .done(done)
);

pe #(.address(4),.PktLmit(`PktLmit))pe4(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[4]),
    .i_data_valid(flit_out[4][39]),
    .o_data_ready(o_pe4_data_ready),
    .o_data(flit_in[4]),
    .o_data_valid(send_flit[4]),
    .i_data_ready(credit_out[4]),
    .done(done)
);

pe #(.address(5),.PktLmit(`PktLmit))pe5(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[5]),
    .i_data_valid(flit_out[5][39]),
    .o_data_ready(o_pe5_data_ready),
    .o_data(flit_in[5]),
    .o_data_valid(send_flit[5]),
    .i_data_ready(credit_out[5]),
    .done(done)
);

pe #(.address(6),.PktLmit(`PktLmit))pe6(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[6]),
    .i_data_valid(flit_out[6][39]),
    .o_data_ready(o_pe6_data_ready),
    .o_data(flit_in[6]),
    .o_data_valid(send_flit[6]),
    .i_data_ready(credit_out[6]),
    .done(done)
);

pe #(.address(7),.PktLmit(`PktLmit))pe7(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[7]),
    .i_data_valid(flit_out[7][39]),
    .o_data_ready(o_pe7_data_ready),
    .o_data(flit_in[7]),
    .o_data_valid(send_flit[7]),
    .i_data_ready(credit_out[7]),
    .done(done)
);

pe #(.address(8),.PktLmit(`PktLmit))pe8(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[8]),
    .i_data_valid(flit_out[8][39]),
    .o_data_ready(o_pe8_data_ready),
    .o_data(flit_in[8]),
    .o_data_valid(send_flit[8]),
    .i_data_ready(credit_out[8]),
    .done(done)
);

pe #(.address(9),.PktLmit(`PktLmit))pe9(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[9]),
    .i_data_valid(flit_out[9][39]),
    .o_data_ready(o_pe9_data_ready),
    .o_data(flit_in[9]),
    .o_data_valid(send_flit[9]),
    .i_data_ready(credit_out[9]),
    .done(done)
);

pe #(.address(10),.PktLmit(`PktLmit))pe10(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[10]),
    .i_data_valid(flit_out[10][39]),
    .o_data_ready(o_pe10_data_ready),
    .o_data(flit_in[10]),
    .o_data_valid(send_flit[10]),
    .i_data_ready(credit_out[10]),
    .done(done)
);

pe #(.address(11),.PktLmit(`PktLmit))pe11(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[11]),
    .i_data_valid(flit_out[11][39]),
    .o_data_ready(o_pe11_data_ready),
    .o_data(flit_in[11]),
    .o_data_valid(send_flit[11]),
    .i_data_ready(credit_out[11]),
    .done(done)
);


pe #(.address(12),.PktLmit(`PktLmit))pe12(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[12]),
    .i_data_valid(flit_out[12][39]),
    .o_data_ready(o_pe12_data_ready),
    .o_data(flit_in[12]),
    .o_data_valid(send_flit[12]),
    .i_data_ready(credit_out[12]),
    .done(done)
);


pe #(.address(13),.PktLmit(`PktLmit))pe13(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[13]),
    .i_data_valid(flit_out[13][39]),
    .o_data_ready(o_pe13_data_ready),
    .o_data(flit_in[13]),
    .o_data_valid(send_flit[13]),
    .i_data_ready(credit_out[13]),
    .done(done)
);


pe #(.address(14),.PktLmit(`PktLmit))pe14(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[14]),
    .i_data_valid(flit_out[14][39]),
    .o_data_ready(o_pe14_data_ready),
    .o_data(flit_in[14]),
    .o_data_valid(send_flit[14]),
    .i_data_ready(credit_out[14]),
    .done(done)
);

pe #(.address(15),.PktLmit(`PktLmit))pe15(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[15]),
    .i_data_valid(flit_out[15][39]),
    .o_data_ready(o_pe11_data_ready),
    .o_data(flit_in[15]),
    .o_data_valid(send_flit[15]),
    .i_data_ready(credit_out[15]),
    .done(done)
);



   
pe #(.address(16),.PktLmit(`PktLmit))pe16(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[16]),
    .i_data_valid(flit_out[16][39]),
    .o_data_ready(o_pe16_data_ready),
    .o_data(flit_in[16]),
    .o_data_valid(send_flit[16]),
    .i_data_ready(credit_out[16]),
    .done(done)
);

pe #(.address(17),.PktLmit(`PktLmit))pe17(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[17]),
    .i_data_valid(flit_out[17][39]),
    .o_data_ready(o_pe17_data_ready),
    .o_data(flit_in[17]),
    .o_data_valid(send_flit[17]),
    .i_data_ready(credit_out[17]),
    .done(done)
);

pe #(.address(18),.PktLmit(`PktLmit))pe18(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[18]),
    .i_data_valid(flit_out[18][39]),
    .o_data_ready(o_pe18_data_ready),
    .o_data(flit_in[18]),
    .o_data_valid(send_flit[18]),
    .i_data_ready(credit_out[18]),
    .done(done)
);

pe #(.address(19),.PktLmit(`PktLmit))pe19(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[19]),
    .i_data_valid(flit_out[19][39]),
    .o_data_ready(o_pe19_data_ready),
    .o_data(flit_in[19]),
    .o_data_valid(send_flit[19]),
    .i_data_ready(credit_out[19]),
    .done(done)
);

pe #(.address(20),.PktLmit(`PktLmit))pe20(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[20]),
    .i_data_valid(flit_out[20][39]),
    .o_data_ready(o_pe20_data_ready),
    .o_data(flit_in[20]),
    .o_data_valid(send_flit[20]),
    .i_data_ready(credit_out[20]),
    .done(done)
);

pe #(.address(21),.PktLmit(`PktLmit))pe21(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[21]),
    .i_data_valid(flit_out[21][39]),
    .o_data_ready(o_pe21_data_ready),
    .o_data(flit_in[21]),
    .o_data_valid(send_flit[21]),
    .i_data_ready(credit_out[21]),
    .done(done)
);

pe #(.address(22),.PktLmit(`PktLmit))pe22(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[22]),
    .i_data_valid(flit_out[22][39]),
    .o_data_ready(o_pe22_data_ready),
    .o_data(flit_in[22]),
    .o_data_valid(send_flit[22]),
    .i_data_ready(credit_out[22]),
    .done(done)
);

pe #(.address(23),.PktLmit(`PktLmit))pe23(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[23]),
    .i_data_valid(flit_out[23][39]),
    .o_data_ready(o_pe23_data_ready),
    .o_data(flit_in[23]),
    .o_data_valid(send_flit[23]),
    .i_data_ready(credit_out[23]),
    .done(done)
);

pe #(.address(24),.PktLmit(`PktLmit))pe24(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[24]),
    .i_data_valid(flit_out[24][39]),
    .o_data_ready(o_pe24_data_ready),
    .o_data(flit_in[24]),
    .o_data_valid(send_flit[24]),
    .i_data_ready(credit_out[24]),
    .done(done)
);

pe #(.address(25),.PktLmit(`PktLmit))pe25(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[25]),
    .i_data_valid(flit_out[25][39]),
    .o_data_ready(o_pe25_data_ready),
    .o_data(flit_in[25]),
    .o_data_valid(send_flit[25]),
    .i_data_ready(credit_out[25]),
    .done(done)
);

pe #(.address(26),.PktLmit(`PktLmit))pe26(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[26]),
    .i_data_valid(flit_out[26][39]),
    .o_data_ready(o_pe26_data_ready),
    .o_data(flit_in[26]),
    .o_data_valid(send_flit[26]),
    .i_data_ready(credit_out[26]),
    .done(done)
);

pe #(.address(27),.PktLmit(`PktLmit))pe27(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[27]),
    .i_data_valid(flit_out[27][39]),
    .o_data_ready(o_pe27_data_ready),
    .o_data(flit_in[27]),
    .o_data_valid(send_flit[27]),
    .i_data_ready(credit_out[27]),
    .done(done)
);


pe #(.address(28),.PktLmit(`PktLmit))pe28(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[28]),
    .i_data_valid(flit_out[28][39]),
    .o_data_ready(o_pe28_data_ready),
    .o_data(flit_in[28]),
    .o_data_valid(send_flit[28]),
    .i_data_ready(credit_out[28]),
    .done(done)
);


pe #(.address(29),.PktLmit(`PktLmit))pe29(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[29]),
    .i_data_valid(flit_out[29][39]),
    .o_data_ready(o_pe29_data_ready),
    .o_data(flit_in[29]),
    .o_data_valid(send_flit[29]),
    .i_data_ready(credit_out[29]),
    .done(done)
);


pe #(.address(30),.PktLmit(`PktLmit))pe30(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[30]),
    .i_data_valid(flit_out[30][39]),
    .o_data_ready(o_pe30_data_ready),
    .o_data(flit_in[30]),
    .o_data_valid(send_flit[30]),
    .i_data_ready(credit_out[30]),
    .done(done)
);

pe #(.address(31),.PktLmit(`PktLmit))pe31(
    .clk(Clk),
    .rst(!Rst_n),
    .i_data(flit_out[31]),
    .i_data_valid(flit_out[31][39]),
    .o_data_ready(o_pe31_data_ready),
    .o_data(flit_in[31]),
    .o_data_valid(send_flit[31]),
    .i_data_ready(credit_out[31]),
    .done(done)
);


endmodule

`endif