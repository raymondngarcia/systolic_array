`ifndef __SA_TEST_PKG_SV__
`define __SA_TEST_PKG_SV__

package sa_test_pkg;

  timeunit 1ns;
  timeprecision 1ns;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import sa_pkg::*; // contains RTL parameters
  import sa_agent_pkg::*;
  import sa_env_pkg::*;
  import sa_seq_pkg::*;

  `include "sa_base_test.sv"
  `include "sa_sanity_test.sv"
endpackage : sa_test_pkg
`endif
