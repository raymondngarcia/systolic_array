`ifndef __SA_ENV_SV__
`define __SA_ENV_SV__

class sa_env extends uvm_env;

  `uvm_component_utils(sa_env)

  sa_env_cfg                               m_env_cfg_h;
  sa_agent#(sa_pkg::DIN_WIDTH, sa_pkg::N)  m_sa_agt;

  function new(string name = "cva6v_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    `uvm_info("build_phase", "Entered...", UVM_LOW)

    super.build_phase(phase);

    if (m_env_cfg_h == null) begin
      `uvm_fatal(get_name(), "Unable to find environment configuration object in the uvm_config_db");
    end

    m_sa_agt = sa_agent#(sa_pkg::DIN_WIDTH, sa_pkg::N)::type_id::create("sa_agent", this);
    m_sa_agt.cfg_h = m_env_cfg_h.m_sa_cfg;

    `uvm_info(get_name(), "Exiting build_phase...", UVM_LOW)
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    `uvm_info("connect_phase", "Entered...", UVM_LOW)

    super.connect_phase(phase);
    //m_sa_agt.mon.sa_port.connect(/*connect here*/);

    `uvm_info(get_name(), "Exiting connect_phase...", UVM_LOW)
  endfunction : connect_phase
endclass

`endif  // __SA_ENV_SV__
