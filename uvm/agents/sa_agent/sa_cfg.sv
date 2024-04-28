
`ifndef __SA_CFG_SV__
`define __SA_CFG_SV__

class sa_cfg extends uvm_object;
  `uvm_object_utils(sa_cfg)

  rand int unsigned m_din_width;
  rand int unsigned m_N;
  rand int unsigned m_M;
  rand int unsigned m_a_delay_cycles; // delay before a matrix is driven upon receiving the item
  rand int unsigned m_c_delay_cycles; // same as delay for a


  rand bit is_active;
  rand bit has_coverage;

  rand bit in_valid_seq_ctrl;
  rand bit out_valid_seq_ctrl;

  constraint default_c {
    soft is_active == 1;
    soft has_coverage == 1;
    soft in_valid_seq_ctrl == 0;
    soft out_valid_seq_ctrl == 0;
    soft m_a_delay_cycles == 2;
    soft m_c_delay_cycles == 2;
  }

  function new(string name = "sa_cfg");
    super.new(name);
  endfunction

  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf("\n----------- SA Config ----------------") };
    s = {s, $sformatf("\n Instance            : %s",     get_full_name())};
    s = {s, $sformatf("\n m_din_width         : %0d",    m_din_width)};
    s = {s, $sformatf("\n m_N                 : %0d",    m_N)};
    s = {s, $sformatf("\n m_M                 : %0d",    m_M)};
    s = {s, $sformatf("\n is_active           : %0d",    is_active)};
    s = {s, $sformatf("\n in_valid_seq_ctrl   : %0d",    in_valid_seq_ctrl)};
    s = {s, $sformatf("\n out_valid_seq_ctrl  : %0d",    out_valid_seq_ctrl)};
    s = {s, $sformatf("\n---------------------------------------------") };
    return s;
  endfunction

  function void post_randomize();
    `uvm_info(get_name(), convert2string(), UVM_NONE)
  endfunction

endclass

`endif  // __SA_CFG_SV__
