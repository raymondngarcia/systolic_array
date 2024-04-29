`ifndef __SA_SB_SV__
`define __SA_SB_SV__
class sa_sb#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4, int unsigned M = 'd4) extends uvm_scoreboard;
  `uvm_component_param_utils(sa_sb#(DIN_WIDTH, N, M))

  typedef sa_seq_item#(DIN_WIDTH, N, M) sa_seq_item_t;

  sa_seq_item_t exp_item;
  sa_seq_item_t act_item;

  uvm_tlm_analysis_fifo#(sa_seq_item_t) act_fifo;
  uvm_tlm_analysis_fifo#(sa_seq_item_t) exp_fifo;

  int act_cnt, exp_cnt;

  event  m_rst_evt, m_rst_done_evt;

  function new(string name ="", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp_item = sa_seq_item_t::type_id::create("exp_item");
    act_item = sa_seq_item_t::type_id::create("act_item");
    act_fifo = new("act_fifo", this);
    exp_fifo = new("exp_fifo", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    sa_seq_item_t itm;
    super.run_phase(phase);
    forever begin
      fork
        forever begin
          act_fifo.get(act_item);
          act_cnt+= 1;
          exp_fifo.get(exp_item);
          exp_cnt+= 1;
          if (act_item.compare(exp_item)) begin
            `uvm_info(get_name(), $sformatf("SB Match! %s", act_item.convert2string()), UVM_NONE)
          end else begin
            `uvm_error(get_name(), $sformatf("SB Mismatch! Exp: %s Act: %s", exp_item.convert2string(), act_item.convert2string()))
          end

        end
        begin
          @ (m_rst_evt);
          while(act_fifo.try_get(itm));
          while(exp_fifo.try_get(itm));
          act_cnt = 0;
          exp_cnt = 0;
          @ (m_rst_done_evt);
          `uvm_info(get_name(), "Reset happened", UVM_NONE)
        end
      join_any
      disable fork;
    end
  endtask : run_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if (!exp_fifo.is_empty()) begin
      `uvm_error(get_name, $sformatf("exp_fifo is not empty with %0d items", exp_fifo.used()))
    end
    if (!act_fifo.is_empty()) begin
      `uvm_error(get_name, $sformatf("act_fifo is not empty with %0d items", act_fifo.used()))
    end
    if (exp_cnt != act_cnt) begin
      `uvm_error(get_name, $sformatf("number of received items RTL vs MDL mismatch, mdl: %0d rtl: %0d",act_cnt,exp_cnt))
    end
  endfunction
endclass
`endif
