`ifndef __SA_REFMODEL_SV__
`define __SA_REFMODEL_SV__

class sa_refmodel#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4) extends uvm_component;
  `uvm_component_utils(sa_refmodel#(DIN_WIDTH, N))

  typedef sa_seq_item#(DIN_WIDTH, N) sa_seq_item_t;

  uvm_tlm_analysis_fifo#(sa_seq_item_t) cmd_in;
  uvm_analysis_port#(sa_seq_item_t)     cmd_out;

  function new(string name ="", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

  endtask
endclass
`endif
