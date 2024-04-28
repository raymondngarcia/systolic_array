`ifndef __SA_SEQ_SV__
`define __SA_SEQ_SV__

class sa_seq extends uvm_sequence;
  `uvm_object_utils(sa_seq)

  typedef sa_seq_item#(sa_pkg::DIN_WIDTH, sa_pkg::N) sa_item_t;
  sa_env                    m_env_h;
  rand int unsigned         m_iteration;

  constraint default_c {
    soft m_iteration >= 5;
    soft m_iteration <= 20;
  }

  function new(string name="sa_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    `uvm_info(get_name(), "pre_body() started.",UVM_LOW)
    if (!uvm_config_db #(sa_env)::get(null, "", "SA_ENV", m_env_h)) begin
      `uvm_fatal(get_name(), "Unable to get ENV SA")
    end
    `uvm_info(get_name(), "pre_body() ended.",UVM_LOW)
  endtask : pre_body

  task body();
    sa_item_t sa_item;

    for (int i=0; i < m_iteration; i++) begin
      sa_item = sa_item_t::type_id::create("sa_item");
      if (!sa_item.randomize()) begin
        `uvm_fatal(get_name(), "failed to randomize sa_item")
      end else begin
        `uvm_info(get_name(), $sformatf("Item %0d \n %s", i, sa_item.convert2string()), UVM_NONE)
      end
      start_item(sa_item);
      finish_item(sa_item);
    end
  endtask
endclass
`endif // __SA_SEQ_SV__
