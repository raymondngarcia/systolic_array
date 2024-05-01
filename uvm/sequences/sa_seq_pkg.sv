`ifndef __SA_SEQ_PKG_SV__
`define __SA_SEQ_PKG_SV__

package sa_seq_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import sa_agent_pkg::*;
  import sa_env_pkg::*;

  // Sequences
  `include "sa_seq.sv"
  // add more here
endpackage
`endif