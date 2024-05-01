
`ifndef __SA_CFG_SV__
`define __SA_CFG_SV__

class sa_cfg extends uvm_object;
  `uvm_object_utils(sa_cfg)

  rand int unsigned m_a_delay_cycles; // delay before a matrix is driven upon receiving the item
  rand int unsigned m_c_delay_cycles; // same as delay for a

  //Driver
  rand bit is_active;
  rand bit in_valid_seq_ctrl;
  rand bit out_valid_seq_ctrl;
  rand bit drive_cin; // set to 0 to have the option to loopack cout in top level

  //Monitor
  //for simplicity, we have just field to enable/disable protocol check
  //but they can be for each kind of protocol violation ideally
  rand bit enable_protocol_check;

  // Coverage
  rand bit has_coverage;

  constraint drv_default_c {
    soft is_active == 1;
    soft in_valid_seq_ctrl == 1;
    soft out_valid_seq_ctrl == 1;
  }

  constraint drv_default_cin_c {
    soft drive_cin == 1;
  }


  constraint mon_default_c {
    soft enable_protocol_check == 1;
  }

  constraint cov_default_c {
    soft has_coverage == 0; // function coverage is not yet implemented
  }

  function new(string name = "sa_cfg");
    super.new(name);
  endfunction

  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf("\n----------- SA Config ----------------") };
    s = {s, $sformatf("\n Instance               : %s",     get_full_name())};
    s = {s, $sformatf("\n is_active              : %0d",    is_active)};
    s = {s, $sformatf("\n in_valid_seq_ctrl      : %0d",    in_valid_seq_ctrl)};
    s = {s, $sformatf("\n out_valid_seq_ctrl     : %0d",    out_valid_seq_ctrl)};
    s = {s, $sformatf("\n drive_cin              : %0d",    drive_cin)};
    s = {s, $sformatf("\n enable_protocol_check  : %0d",    enable_protocol_check)};
    s = {s, $sformatf("\n has_coverage           : %0d",    has_coverage)};
    s = {s, $sformatf("\n---------------------------------------------") };
    return s;
  endfunction

  function void post_randomize();
    `uvm_info(get_name(), convert2string(), UVM_LOW)
  endfunction

endclass

`endif  // __SA_CFG_SV__
