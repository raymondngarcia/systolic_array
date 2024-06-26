`ifndef __SA_MONITOR_SV__
`define __SA_MONITOR_SV__

class sa_monitor#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4, int unsigned M = 'd4) extends uvm_monitor;
  `uvm_component_param_utils(sa_monitor#(DIN_WIDTH, N, M))

  typedef sa_seq_item#(DIN_WIDTH, N, M)   seq_item_t;
  typedef bit signed [2*DIN_WIDTH-1:0] c_data_t;
  typedef bit signed [DIN_WIDTH-1:0]   ab_data_t;

  sa_cfg                       cfg;
  c_data_t                     cin_q[N][$];
  ab_data_t                    a_q[N][$];
  ab_data_t                    b_q[N][$];
  c_data_t                     cout_q[N][$];
  c_data_t                     cout[N][N];

  seq_item_t sa_q[$];
  semaphore sa_q_sem;

  function new (string name, uvm_component parent);
    super.new (name, parent);
  endfunction

  virtual sa_if#(DIN_WIDTH, N) vif;

  uvm_analysis_port#(seq_item_t) to_refmodel_port; // send to refmodel for processing, compute, etc
  uvm_analysis_port#(seq_item_t) to_sb_act_port;   // send to sb for compare

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg==null) begin
      `uvm_fatal(get_name(), "monitor cfg is null!")
    end else begin
      `uvm_info(get_name(), $sformatf("monitor cfg: %s", cfg.convert2string()), UVM_NONE)
    end
    to_refmodel_port  = new("to_refmodel_port", this);
    to_sb_act_port  = new("to_sb_act_port", this);
    sa_q_sem = new(1);
  endfunction

  virtual task monitor_abc();
    bit first_valid;
    int unsigned diff;
    ab_data_t a, b;
    c_data_t c;
    seq_item_t sa;
    forever begin
      @(vif.mon);
      for (int i=0; i < N; i++) begin
        a = vif.mon.a_din[i];
        a_q[i].push_back(a);

        b = vif.mon.b_din[i];
        b_q[i].push_back(b);

        c = vif.mon.c_din[i];
        cin_q[i].push_back(c);
      end
      if (vif.mon.in_valid === 1) begin
        for (int i=0; i < N; i++) begin
          `uvm_info(get_name(), $sformatf("Matrix A[%0d] %p", i, a_q[i]), UVM_HIGH)
        end
        for (int i=0; i < N; i++) begin
          `uvm_info(get_name(), $sformatf("Matrix B[%0d] %p", i, b_q[i]), UVM_HIGH)
        end
        for (int i=0; i < N; i++) begin
          `uvm_info(get_name(), $sformatf("Matrix C[%0d] %p", i, cin_q[i]), UVM_HIGH)
        end
        if (first_valid==0) begin
          diff = a_q[N-1].size() - N;
          for (int i=0; i < N; i++) begin
            repeat (diff-i) void'(a_q[(N-i)-1].pop_front());
          end
          diff = cin_q[N-1].size() - N;
          for (int i=0; i < N; i++) begin
            repeat (diff-i) void'(cin_q[(N-i)-1].pop_front());
          end
          for (int i=0; i < N; i++) begin
            repeat (i+1) void'(b_q[i].pop_front());
          end
          for (int i=0; i < N; i++) begin
            `uvm_info(get_name(), $sformatf("Matrix After A[%0d] %p", i, a_q[i]), UVM_HIGH)
          end
          for (int i=0; i < N; i++) begin
            `uvm_info(get_name(), $sformatf("Matrix After B[%0d] %p", i, b_q[i]), UVM_HIGH)
          end
          for (int i=0; i < N; i++) begin
            `uvm_info(get_name(), $sformatf("Matrix After C[%0d] %p", i, cin_q[i]), UVM_HIGH)
          end
        end
        first_valid = 1;

        // this means all data are received and we can compute for COUT
        sa = create_matrix_item();
        sa_q_sem.get();
        sa_q.push_back(sa);
        sa_q_sem.put();
        to_refmodel_port.write(sa.do_clone()); // send raw seq sampled to refmodel
      end
    end
  endtask

  function seq_item_t create_matrix_item();
    seq_item_t itm = seq_item_t::type_id::create("itm");

    for (int i=0; i<N; i++) begin
      if (a_q[i].size() < M && cfg.enable_protocol_check) `uvm_error(get_name(), $sformatf("a_q[%0d].size() < M! Got size of %0d. Should be >= %0d", i, a_q[i].size(), M))
    end

    for (int i=0; i<M; i++) begin
      if (b_q[i].size() < N && cfg.enable_protocol_check) `uvm_error(get_name(), $sformatf("b_q[%0d].size() < N! Got size of %0d. Should be >= %0d", i, b_q[i].size(), N))
    end

    for (int i=0; i<N; i++) begin
      if (cin_q[i].size() < N && cfg.enable_protocol_check) `uvm_error(get_name(), $sformatf("cin_q[%0d].size() < N! Got size of %0d. Should be >= %0d", i, cin_q[i].size(), N))
    end

    // create A,B,C_IN
    for (int i=0; i<M; i++) begin
      for (int j=0; j<N; j++) begin
        itm.a_din[i][j] = a_q[j].pop_front();
      end
    end

    for (int i=0; i<N; i++) begin
      for (int j=0; j<M; j++) begin
        itm.b_din[i][j] = b_q[j].pop_front();
      end
    end

    for (int i=0; i<N; i++) begin
      for (int j=0; j<N; j++) begin
        itm.c_din[i][j] = cin_q[j].pop_front();
      end
    end

    return itm;
  endfunction

  virtual task monitor_cout();
    bit first_valid;
    int unsigned diff;
    c_data_t c;
    seq_item_t itm;
    forever begin
      @(vif.mon);
      for (int i=0; i < N; i++) begin
        c = vif.mon.c_dout[i];
        cout_q[i].push_back(c);
      end
      if (vif.mon.out_valid === 1) begin
        for (int i=0; i < N; i++) begin
          `uvm_info(get_name(), $sformatf("Matrix C-OUT [%0d] %p", i, cout_q[i]), UVM_NONE)
        end

        if (first_valid==0) begin
          diff = cout_q[N-1].size() - N;
          for (int i=0; i < N; i++) begin
            repeat (diff-i) void'(cout_q[(N-i)-1].pop_front());
          end
        end
        first_valid = 1;

        sa_q_sem.get();
        if (sa_q.size() ==0) begin
          if (cfg.enable_protocol_check) begin
            `uvm_error(get_name(), "sa_q.size() == 0! Unexpected COUT output!")
          end
        end else begin
          for (int i=0; i < N; i++) begin
            for (int j=0; j < N; j++) begin
               cout[i][j] = cout_q[j].pop_front();
            end
          end
          itm  = sa_q.pop_front();
          itm.c_dout = cout;
          to_sb_act_port.write(itm.do_clone());
        end
        sa_q_sem.put();
      end
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      fork
        begin
          @ (negedge vif.rst_n);
        end
        forever begin
          @ (posedge vif.rst_n);
          fork
            monitor_abc();
            monitor_cout();
          join
        end
      join_any
      disable fork;
      void'(sa_q_sem.try_get());
      sa_q_sem.put();
      `uvm_info(get_name(), "monitor: resetting monitor!", UVM_NONE)
    end
  endtask
endclass

`endif


