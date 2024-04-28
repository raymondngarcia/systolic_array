`ifndef __SA_SEQ_ITEM_SV__
`define __SA_SEQ_ITEM_SV__

class sa_seq_item#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4) extends uvm_sequence_item;
  `uvm_object_param_utils(sa_seq_item#(DIN_WIDTH, N))

  typedef sa_seq_item#(DIN_WIDTH, N) this_t;

  static int unsigned a_counter = 1;
  static int unsigned b_counter = 1;
  static int unsigned c_counter = 1;

  rand bit signed [N-1:0][2*DIN_WIDTH-1:0] c_din;
  rand bit signed [N-1:0][DIN_WIDTH-1:0]   a_din;
  rand bit signed [N-1:0][DIN_WIDTH-1:0]   b_din;
  rand bit signed [N-1:0][2*DIN_WIDTH-1:0] c_dout;

  constraint abc_data_c {
    foreach (a_din[i]) soft a_din[i] == i+a_counter; // TODO: for easy debug, remove once tb is mature
    foreach (b_din[i]) soft b_din[i] == i+b_counter; // TODO: for easy debug, remove once tb is mature
    foreach (c_din[i]) soft c_din[i] == i+c_counter; // TODO: for easy debug, remove once tb is mature
  }

  rand bit in_valid;
  rand bit out_valid;

  function new (string name = "sa_seq_item");
    super.new (name);
  endfunction

  virtual function this_t do_clone();
    this_t item;

    if(!$cast(item, this.clone()))
      `uvm_error(get_full_name(), "Clone failed")

    return item;
  endfunction

  virtual function void do_copy(uvm_object rhs);
    this_t seq_rhs;

    if(rhs == null)
      `uvm_fatal(get_full_name(), "do_copy from null ptr");

    if(!$cast(seq_rhs, rhs))
      `uvm_fatal(get_full_name(), "do_copy cast failed");

    super.do_copy(rhs);
    this.c_din             = seq_rhs.c_din;
    this.a_din             = seq_rhs.a_din;
    this.b_din             = seq_rhs.b_din;
    this.c_dout            = seq_rhs.c_dout;
    this.in_valid          = seq_rhs.in_valid;
    this.out_valid         = seq_rhs.out_valid;
  endfunction

  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf("\n----------- SA_SEQ ITEM ----------------") };
    for (int i=0; i < N; i++) begin
      s = {s, $sformatf("\n a_din[%0d]    : 0x%0x", i, a_din[i])};
      s = {s, $sformatf("\n b_din[%0d]    : 0x%0x", i, b_din[i])};
      s = {s, $sformatf("\n c_din[%0d]    : 0x%0x", i, c_din[i])};
      s = {s, $sformatf("\n c_dout[%0d]   : 0x%0x", i, c_dout[i])};
    end
    s = {s, $sformatf("\n in_valid : 0x%0x",  in_valid)};
    s = {s, $sformatf("\n out_valid : 0x%0x", out_valid)};
    s = {s, $sformatf("\n---------------------------------------------") };
    return s;
  endfunction

  function void post_randomize();
    super.post_randomize();
    a_counter += N;
    b_counter += N;
    c_counter += N;
  endfunction

endclass

`endif

