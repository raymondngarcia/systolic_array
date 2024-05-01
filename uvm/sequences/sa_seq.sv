`ifndef __SA_SEQ_SV__
`define __SA_SEQ_SV__

class sa_seq#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4, int unsigned M = 'd4) extends uvm_sequence;
  `uvm_object_param_utils(sa_seq#(DIN_WIDTH, N, M))

  typedef sa_seq_item#(DIN_WIDTH, N, M) sa_item_t;
  typedef sa_env#(DIN_WIDTH, N, M) sa_env_t;

  sa_env_t                  m_env_h;
  rand int unsigned         m_iteration;
  rand int unsigned         m_env_num = 0;

  constraint default_c {
    soft m_iteration >= 5;
    soft m_iteration <= 20;
  }

  function new(string name="sa_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    // always good for seq to have a handle to the env for future use
    `uvm_info(get_name(), "pre_body() started.",UVM_LOW)
    if (!uvm_config_db #(sa_env_t)::get(null, "", $sformatf("SA_ENV_%0d", m_env_num), m_env_h)) begin
      `uvm_fatal(get_name(), $sformatf("Unable to get SA_ENV_%0d", m_env_num))
    end
    `uvm_info(get_name(), "pre_body() ended.",UVM_LOW)
  endtask : pre_body

  task body();
    sa_item_t sa_item;

    for (int i=0; i < m_iteration; i++) begin
      sa_item = sa_item_t::type_id::create("sa_item");
      if (!sa_item.randomize() with {
        debug_mode == 1;
      }) begin
        `uvm_fatal(get_name(), "failed to randomize sa_item")
      end

      start_item(sa_item);
      finish_item(sa_item);
      `uvm_info(get_name(), $sformatf("Item %0d \n %s", i, sa_item.convert2string()), UVM_NONE)
    end
  endtask
endclass
`endif // __SA_SEQ_SV__
