`ifndef __SA_REFMODEL_SV__
`define __SA_REFMODEL_SV__

class sa_refmodel#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4, int unsigned M = sa_pkg::M) extends uvm_component;
  `uvm_component_utils(sa_refmodel#(DIN_WIDTH, N, M))

  typedef sa_seq_item#(DIN_WIDTH, N, M) seq_item_t;

  uvm_tlm_analysis_fifo#(seq_item_t) seq_item_in;
  uvm_analysis_port#(seq_item_t)     seq_item_out;

  event rst_evt;
  event rst_done_evt;

  function new(string name ="", uvm_component parent = null);
    super.new(name,parent);
  endfunction


  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq_item_in  = new ("seq_item_in", this);
    seq_item_out = new ("seq_item_out", this);
  endfunction

  virtual task run_model();
    seq_item_t itm, itm_clone;
    forever begin
      seq_item_in.get(itm);
      itm.compute_cout(); // set expected COUT
      // do other things required here as feaures are added
      seq_item_out.write(itm.do_clone()); // send outside components like coverage/ sb
      `uvm_info(get_name(), $sformatf("Got item %s", itm.convert2string()), UVM_NONE)
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    seq_item_t itm;
    super.run_phase(phase);
     forever begin
      fork
        run_model();
        begin
          @ (rst_evt);
          while(seq_item_in.try_get(itm));
          @ (rst_done_evt);
        end
      join_any
      disable fork;
    end
  endtask
endclass
`endif
