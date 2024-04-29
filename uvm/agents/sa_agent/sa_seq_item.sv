`ifndef __SA_SEQ_ITEM_SV__
`define __SA_SEQ_ITEM_SV__

class sa_seq_item#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4, int unsigned M = 'd4) extends uvm_sequence_item;
  `uvm_object_param_utils(sa_seq_item#(DIN_WIDTH, N, M))

  typedef sa_seq_item#(DIN_WIDTH, N, M) this_t;
  typedef bit signed [2*DIN_WIDTH-1:0] ab_data_t;
  typedef bit signed [2*DIN_WIDTH-1:0] c_data_t;

  static int unsigned a_counter = 1;
  static int unsigned b_counter = 1;
  static int unsigned c_counter = 1;

  rand c_data_t  c_din[N][N];
  rand ab_data_t a_din[N][M];
  rand ab_data_t b_din[M][N];
  rand c_data_t  c_dout[N][N];

  rand bit debug_mode;

  constraint abc_debug_data_c {
    foreach (a_din[n,m]) {
      (debug_mode) -> soft a_din[n][m] == (n*N + m) + a_counter;
    }
    foreach (b_din[m,n]) {
      (debug_mode) -> soft b_din[m][n] == (m*M + n) + b_counter;
    }
    foreach (c_din[i,j]) {
      (debug_mode) -> soft c_din[i][j] == (i*N + j) + c_counter;
    }
  }

  rand bit in_valid;
  rand bit out_valid;

  function new (string name = "sa_seq_item");
    super.new (name);
  endfunction

  virtual function void compute_cout();
    // Perform matrix multiplication
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        c_dout[i][j] = 0;
        for (int k = 0; k < M; k++) begin
            c_dout[i][j] += a_din[i][k] * b_din[k][j];
            //$display("c[%0d][%0d] += a[%0d][%0d] (%0d) * b[%0d][%0d] (%0d)", i,j, i,k, a_din[i][k],  j,k, b_din[k][j]);
        end
        c_dout[i][j] += c_din[i][j];
      end
    end
  endfunction

  virtual function bit has_cout_mismatch(c_data_t c[N][N]);
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        if (c[i][j] != c_dout[i][j]) begin
          `uvm_error(get_type_name, $sformatf("Mismatch in COUT[%0d, %0d]! Exp: 0x%0x Act: 0x%0x", i, j, c_dout[i][j], c[i][j]))
          return 1;
        end
      end
    end
    return 0;
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

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    this_t rhs_;
    if(!$cast(rhs_, rhs)) begin
      `uvm_fatal(get_type_name(), "do_compare: Cast error.")
      return 0;
    end
    return((super.do_compare(rhs, comparer) &&
        (c_din == rhs_.c_din) &&
        (a_din == rhs_.a_din) &&
        (b_din == rhs_.b_din) &&
        (c_dout == rhs_.c_dout)));
  endfunction

  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf("\n----------- SA_SEQ ITEM ----------------") };
    s = {s, $sformatf("\n a_din  (%0dx%0d)   : %p", N, M, a_din)};
    s = {s, $sformatf("\n b_din  (%0dx%0d)   : %p", M, N, b_din)};
    s = {s, $sformatf("\n c_din  (%0dx%0d)   : %p", N, N, c_din)};
    s = {s, $sformatf("\n c_dout (%0dx%0d)   : %p", N, N, c_dout)};
    s = {s, $sformatf("\n in_valid : 0x%0x",  in_valid)};
    s = {s, $sformatf("\n out_valid : 0x%0x", out_valid)};
    s = {s, $sformatf("\n---------------------------------------------") };
    return s;
  endfunction

  function void post_randomize();
    super.post_randomize();
    if (debug_mode) begin
      a_counter += N*M;
      b_counter += N*M;
      c_counter += N*N;
    end
    compute_cout(); // provide valid COUT for driver
  endfunction

endclass

`endif

