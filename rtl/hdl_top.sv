module hdl_top;
  // Time unit and precision
  timeunit 1ps; timeprecision 1ps;

  import sa_pkg::*;
  import uvm_pkg::*;
  import sa_test_pkg::*;
  `include "uvm_macros.svh"

  typedef virtual sa_if  #(sa_pkg::DIN_WIDTH, sa_pkg::N) sa_vif_t;

  realtime                        CLK_PERIOD = 0.625ns;  // 1.6GHz
  logic                           clk;
  logic                           rst_n;

  logic [2*sa_pkg::DIN_WIDTH-1:0] c_din[0:sa_pkg::N-1];
  logic [sa_pkg::DIN_WIDTH-1:0]   a_din[0:sa_pkg::N-1];
  logic [sa_pkg::DIN_WIDTH-1:0]   b_din[0:sa_pkg::N-1];
  logic                           in_valid;

  logic [2*sa_pkg::DIN_WIDTH-1:0] c_dout[sa_pkg::N-1:0];
  logic                           out_valid;


  sa_if  #(sa_pkg::DIN_WIDTH, sa_pkg::N)  i_sa_if ();


  //DUT
  sa #(
    .DIN_WIDTH            (sa_pkg::DIN_WIDTH),
    .N                    (sa_pkg::N)
  ) dut (.*);

  // DUT connections
  assign i_sa_if.clk   = clk;
  assign i_sa_if.rst_n = rst_n;

  for (genvar i = 0; i < sa_pkg::N; i++) begin : gen_sa_din
    assign c_din[i] = i_sa_if.c_din[i];
    assign a_din[i] = i_sa_if.a_din[i];
    assign b_din[i] = i_sa_if.b_din[i];

    assign i_sa_if.c_dout[i] = c_dout[i];
  end

  initial begin
    uvm_config_db#(sa_vif_t)::set(.cntxt(null), .inst_name("*"),  .field_name("vif"),  .value(i_sa_if));
  end

  always begin
    clk <= 1;
    #(CLK_PERIOD / 2);
    clk <= 0;
    #(CLK_PERIOD / 2);
  end

  initial begin
    rst_n = 0;
    #(CLK_PERIOD * 2);
    rst_n = 1;
  end

  initial begin
    $timeformat(-9, 3, " ns", 10);
    run_test(); // run uvm
  end

endmodule : hdl_top
