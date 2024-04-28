`ifndef __SA_ENV_CFG_SV__
`define __SA_ENV_CFG_SV__

// AI CORE LS environment configuration class
class sa_env_cfg extends uvm_object;

  `uvm_object_utils(sa_env_cfg)

  rand sa_cfg       m_sa_cfg;

  rand bit          m_sb_en;
  rand bit          m_sa_agt_active;

  function new(string name = "sa_env_cfg");
    super.new(name);
    m_sa_cfg = sa_cfg::type_id::create("m_sa_cfg");
  endfunction : new

endclass : sa_env_cfg

`endif  // __SA_ENV_CFG_SV__
