`ifndef __SA_AGENT_SV__
`define __SA_AGENT_SV__

class sa_agent#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4) extends uvm_agent;
  `uvm_component_param_utils(sa_agent#(DIN_WIDTH, N))

  virtual sa_if#(DIN_WIDTH, N)                vif;
  sa_monitor#(DIN_WIDTH, N)                   mon;
  sa_driver#(DIN_WIDTH, N)                    drv;
  uvm_sequencer#(sa_seq_item#(DIN_WIDTH, N))  sqr;
  sa_cfg                                      cfg_h;

  function new (string name, uvm_component parent);
    super.new (name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual sa_if#(DIN_WIDTH, N))::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_full_name(), "Failed to get vif handle from config_db")
    end

    if (cfg_h == null) begin
       `uvm_fatal(get_full_name(),"Config object null")
    end

    if (cfg_h.is_active == 1) begin
      drv = sa_driver#(DIN_WIDTH, N)::type_id::create("drv",this);
      drv.cfg = cfg_h;
      sqr = uvm_sequencer#(sa_seq_item#(DIN_WIDTH, N))::type_id::create("sqr",this);
    end
    mon = sa_monitor#(DIN_WIDTH, N)::type_id::create("mon",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.vif = vif;

    if (cfg_h.is_active == 1) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
      drv.vif = vif;
    end
  endfunction
endclass

`endif


