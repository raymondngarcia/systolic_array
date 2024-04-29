`ifndef __SA_ENV_SV__
`define __SA_ENV_SV__

class sa_env extends uvm_env;

  `uvm_component_utils(sa_env)

  sa_env_cfg                                             m_env_cfg_h;
  sa_agent#(sa_pkg::DIN_WIDTH, sa_pkg::N, sa_pkg::M)     m_sa_agt;
  sa_refmodel#(sa_pkg::DIN_WIDTH, sa_pkg::N, sa_pkg::M)  m_sa_refmodel;
  sa_sb#(sa_pkg::DIN_WIDTH, sa_pkg::N, sa_pkg::M)        m_sa_sb;

  function new(string name = "cva6v_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    `uvm_info("build_phase", "Entered...", UVM_LOW)

    super.build_phase(phase);

    if (m_env_cfg_h == null) begin
      `uvm_fatal(get_name(), "Unable to find environment configuration object in the uvm_config_db");
    end

    m_sa_agt = sa_agent#(sa_pkg::DIN_WIDTH, sa_pkg::N, sa_pkg::M)::type_id::create("m_sa_agt", this);
    m_sa_agt.cfg_h = m_env_cfg_h.m_sa_cfg;

    m_sa_refmodel = sa_refmodel#(sa_pkg::DIN_WIDTH, sa_pkg::N, sa_pkg::M)::type_id::create("m_sa_refmodel", this);
    m_sa_sb = sa_sb#(sa_pkg::DIN_WIDTH, sa_pkg::N, sa_pkg::M)::type_id::create("m_sa_sb", this);

    `uvm_info(get_name(), "Exiting build_phase...", UVM_LOW)
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    `uvm_info("connect_phase", "Entered...", UVM_LOW)

    super.connect_phase(phase);
    m_sa_agt.mon.to_refmodel_port.connect(m_sa_refmodel.seq_item_in.analysis_export);
    m_sa_agt.mon.to_sb_act_port.connect(m_sa_sb.act_fifo.analysis_export);
    m_sa_refmodel.seq_item_out.connect(m_sa_sb.exp_fifo.analysis_export);

    `uvm_info(get_name(), "Exiting connect_phase...", UVM_LOW)
  endfunction : connect_phase
endclass

`endif  // __SA_ENV_SV__
