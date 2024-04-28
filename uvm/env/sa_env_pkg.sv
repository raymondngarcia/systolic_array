`ifndef __SA_ENV_PKG_SV__
`define __SA_ENV_PKG_SV__

package sa_env_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import sa_pkg::*;
  import sa_agent_pkg::*;

  // Environment configuration and environment
  `include "sa_env_cfg.sv"
  `include "sa_env.sv"
endpackage : sa_env_pkg

`endif  // __SA_ENV_PKG_SV__
