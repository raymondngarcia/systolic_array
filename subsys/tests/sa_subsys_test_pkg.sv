`ifndef __SA_SUBSYS_TEST_PKG_SV__
`define __SA_SUBSYS_TEST_PKG_SV__

package sa_subsys_test_pkg;

  timeunit 1ns;
  timeprecision 1ns;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import sa_subsys_pkg::*; // contains RTL parameters
  import sa_agent_pkg::*;
  import sa_env_pkg::*;
  import sa_seq_pkg::*;

  parameter int unsigned NUM_SA = sa_subsys_pkg::NUM_SA;

  `include "sa_subsys_base_test.sv"
  `include "sa_subsys_sanity_test.sv"
endpackage : sa_subsys_test_pkg
`endif
