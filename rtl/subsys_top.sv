// By using defines, we can change the values of sr_clk and sys_clk.
// The defines could be controlled by using different files to include.
// However, it is always better to have a simple clock generator.
// Clock
`define  SR_CLK_PERIOD       0.625ns  // 1.6GHz
`define  SR_SYS_CLK_FACTOR   2.0      // for sys_clk in relation to SR_CLK

module hdl_top;
  // Time unit and precision
  timeunit 1ps; timeprecision 1ps;

  import uvm_pkg::*;
  import sa_subsys_pkg::*;
  import sa_subsys_test_pkg::*;
  `include "uvm_macros.svh"

  typedef virtual sa_if  #(sa_subsys_pkg::DIN_WIDTH_0, sa_subsys_pkg::N_0, sa_subsys_pkg::M_0) sa_vif_0_t;
  typedef virtual sa_if  #(sa_subsys_pkg::DIN_WIDTH_1, sa_subsys_pkg::N_1, sa_subsys_pkg::M_1) sa_vif_1_t;

  // Clock
  parameter realtime SR_CLK_PERIOD      = `SR_CLK_PERIOD;
  parameter real     SR_SYS_CLK_FACTOR  = `SR_SYS_CLK_FACTOR;

  logic                                 rst_n;
  logic                                 sys_clk;
  logic                                 sr_clk;
  logic[7:0]                            M_minus_one;
  logic[sa_subsys_pkg::BUS_WIDTH_0-1:0] din;
  logic                                 wr_fifo;
  logic                                 rd_fifo;
  logic                                 in_fifo_full;
  logic[sa_subsys_pkg::BUS_WIDTH_0-1:0] dout;
  logic                                 out_fifo_empty;

  sa_if #(sa_subsys_pkg::DIN_WIDTH_0, sa_subsys_pkg::N_0, sa_subsys_pkg::M_0)  i_sa_if_0();
  sa_if #(sa_subsys_pkg::DIN_WIDTH_1, sa_subsys_pkg::N_1, sa_subsys_pkg::M_1)  i_sa_if_1();

  assign i_sa_if_0.rst_n = rst_n;
  assign i_sa_if_1.rst_n = rst_n;
  assign i_sa_if_0.clk   = sr_clk;
  assign i_sa_if_1.clk   = sr_clk;

  //DUT, just 1 instance for simplicity. 2 instances of sa_if is just for exampled
  // that the SA UVM env can scale to different parameters
  subsys #(
    .DIN_WIDTH            (sa_subsys_pkg::DIN_WIDTH_0),
    .N                    (sa_subsys_pkg::N_0),
    .BUS_WIDTH            (sa_subsys_pkg::BUS_WIDTH_0)
  ) dut (.*);

  // Interface drives all the signals including DUT output since out DUT is an empty module
  assign M_minus_one                                                    = (sa_subsys_pkg::M_0 -1'b1);
  assign din[(sa_subsys_pkg::BUS_WIDTH_0/2)-1:0]                        = i_sa_if_0.a_din;
  assign din[sa_subsys_pkg::BUS_WIDTH_0-1:sa_subsys_pkg::BUS_WIDTH_0/2] = i_sa_if_0.b_din;
  assign wr_fifo                                                        = i_sa_if_0.in_valid;  // write to Input FIFO when data is valid
  assign rd_fifo                                                        = i_sa_if_0.out_valid; // read from Output FIFO when data is valid

  // We can loopback CIN to COUT but keep in mind with NO actual DUT, the driver cannot
  // drive COUT correctly. This will be fiuture enhancements
  // assign i_sa_if_0.c_din = i_sa_if_0.c_dout;

  // should be assigning i_sa_if_0.c_dout = dout but we do not have DUT
  assign dout                                                           = i_sa_if_0.c_dout;

  initial begin
    uvm_config_db#(sa_vif_0_t)::set(.cntxt(null), .inst_name("uvm_test_top.m_env_0.m_sa_agt"),  .field_name("vif"),  .value(i_sa_if_0));
    uvm_config_db#(sa_vif_1_t)::set(.cntxt(null), .inst_name("uvm_test_top.m_env_1.m_sa_agt"),  .field_name("vif"),  .value(i_sa_if_1));
  end

  always begin
    sys_clk <= 1;
    #((SR_CLK_PERIOD*SR_SYS_CLK_FACTOR) / 2);
    sys_clk <= 0;
    #((SR_CLK_PERIOD*SR_SYS_CLK_FACTOR) / 2);
  end

  always begin
    sr_clk <= 1;
    #(SR_CLK_PERIOD / 2);
    sr_clk <= 0;
    #(SR_CLK_PERIOD / 2);
  end

  initial begin
    rst_n = 0;
    #((SR_CLK_PERIOD*SR_SYS_CLK_FACTOR) /2);
    rst_n = 1;
  end

  initial begin
    $timeformat(-9, 3, " ns", 10);
    run_test(); // run uvm
  end

endmodule : hdl_top
