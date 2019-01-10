/****************************************************************

Copyright (c) #YEAR# #LICENSOR#. All rights reserved.

The information and source code contained herein is the 
property of #LICENSOR#, and may not be disclosed or
reproduced in whole or in part without explicit written 
authorization from #LICENSOR#. Contact #EMAIL# for details.

* Filename   : tx_driver.sv
* Author     : Byongchan Lim (bclim@stanford.edu)
* Description: Tx driver 

* Note       :

* Revision   :
  - 7/26/2016: First release

****************************************************************/


module tx_driver_pwm1_pe #(
  //parameter real tr=0, // transition time
  //parameter real dc=0,  // output dc value
  //parameter real amp=1.0,   // amplitude
  //parameter real wtap0 = 1.0,
  //parameter real wtap1 = 1.0
  parameter real Tunit = 20e-12,
  parameter real Tpe = 80e-12,
  parameter integer Nadd =3
) (
  input in,       // TX data
  input clk,      // TX clock
  `output_pwl out,
  output clk_div,
  output clk_div2,
  output logic [3:0]DTC
);

//localparam real wtap[] = '{wtap0,wtap1};

`get_timeunit
PWLMethod pm=new;

logic [3:0]sr;
logic [3:0]ph;
logic vout;
logic [9:0] clk_div_d;
logic gate;
logic main_cur;

logic vout_tx, vout_tx_d, vout_tx_2d;
logic vout_pe_LR, vout_pe_RR, vout_pe_LF, vout_pe_RF;
real t_start, t_stop, t_diff;

divider #(.Ndiv(4)) idiv(.cki(clk), .cko(clk_div));

initial begin
sr ='0;
vout=0;
ph=0;
clk_div_d='0;
DTC ='0;
main_cur =0;
end

always @(posedge clk) begin
sr[0] <= in;
sr[1] <= sr[0];
sr[2] <= sr[1];
sr[3] <= sr[2];
end



divider #(.Ndiv(50)) idiv2(.cki(clk_div), .cko(clk_div2));

always @(posedge clk_div) begin
clk_div_d[0] <= clk_div2;
clk_div_d[1] <= clk_div_d[0];
clk_div_d[2] <= clk_div_d[1];
clk_div_d[3] <= clk_div_d[2];
clk_div_d[4] <= clk_div_d[3];
clk_div_d[5] <= clk_div_d[4];
clk_div_d[6] <= clk_div_d[5];
clk_div_d[7] <= clk_div_d[6];
clk_div_d[8] <= clk_div_d[7];
clk_div_d[9] <= clk_div_d[8];
end


//pulse #( .b0(1'b0), .td(100e-9), .tw(250e-12), .tp(100e-9) ) igate (.out(gate) ); // bypass DFE (act. Hi)
assign gate = clk_div2&~clk_div_d[9];
assign vout_tx = vout&gate; 
//assign vout_tx = vout; 

always @(posedge clk_div2) begin
main_cur<=1;
ph=ph+1;
end

//always @(posedge clk_div2) DTC <= DTC+1;


always @(posedge clk_div) begin
DTC <=sr;
vout <= #((7*Tunit)*1s) 1;
end

always @(negedge clk_div) begin
	if (main_cur) begin
	vout <= #((ph*Tunit)*1s) 0;
	main_cur<=0;
	end
	else vout <= #((DTC*Tunit)*1s) 0;
end

always @(posedge vout_tx) begin
t_start = $realtime*1e-15;
end
always @(negedge vout_tx) begin
t_stop = $realtime*1e-15;
t_diff = t_stop-t_start;
end

always @(vout_tx) begin
vout_tx_d <= #(Tpe*1s) vout_tx;
vout_tx_2d <= #(2*Tpe*1s) vout_tx;
end

assign vout_pe_LR = ~( vout_tx & ~ vout_tx_d );
assign vout_pe_RR = vout_tx_d & ~ vout_tx_2d;
assign vout_pe_LF = ~ vout_tx & vout_tx_d;
assign vout_pe_RF = ~( ~vout_tx_d &  vout_tx_2d);

pwl _pe[Nadd];
real _k_scale[Nadd] = '{{Nadd}{1.0}};

//bit2pwl #( .vh(0.25), .vl(-0.25), .tr(10e-12), .tf(10e-12) ) iB2P0 ( .in(vout_tx_d), .out(_pe[0]) );
//bit2pwl #( .vh(0), .vl(-0.4), .tr(10e-12), .tf(10e-12) ) iB2P1 ( .in(vout_pe_LR), .out(_pe[1]) );
//bit2pwl #( .vh(0.25), .vl(0), .tr(10e-12), .tf(10e-12) ) iB2P2 ( .in(vout_pe_RR), .out(_pe[1]) );
//bit2pwl #( .vh(0.4), .vl(0), .tr(10e-12), .tf(10e-12) ) iB2P3 ( .in(vout_pe_LF), .out(_pe[3]) );
//bit2pwl #( .vh(0), .vl(-0.25), .tr(10e-12), .tf(10e-12) ) iB2P4 ( .in(vout_pe_RF), .out(_pe[2]) );
//pwl_add #( .no_sig(Nadd) ) iADD_PP ( .scale(_k_scale), .in(_pe), .out(out) ); // add partial products

bit2pwl #( .vh(0.5), .vl(-0.5), .tr(10e-12), .tf(10e-12) ) iB2P0 ( .in(vout_tx), .out(out) );
//fir_ntap_filter #( .Ntap(2), .dc(0.0), .amp(amp), .wtap(wtap), .tr(10e-12) ) iPREEMPHASIS ( .clk(clk), .in(in), .out(out) );

endmodule
