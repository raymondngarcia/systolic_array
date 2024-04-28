`ifndef __SA_DRIVER_SV__
`define __SA_DRIVER_SV__

class sa_driver#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4) extends uvm_driver #(sa_seq_item#(DIN_WIDTH, N));;
  `uvm_component_param_utils(sa_driver#(DIN_WIDTH, N))

  typedef sa_seq_item#(DIN_WIDTH, N)   seq_item_t;
  typedef bit signed [2*DIN_WIDTH-1:0] c_data_t;
  typedef bit signed [DIN_WIDTH-1:0]   ab_data_t;
  typedef enum { A_DIN, B_DIN, C_DIN, C_DOUT } drv_port_t;

  semaphore    sem;
  int          lane_delay_done;

  function new (string name, uvm_component parent);
    super.new (name, parent);
  endfunction

  virtual sa_if#(DIN_WIDTH, N) vif;
  sa_cfg                       cfg;

  c_data_t                     cin_q[N][$];
  ab_data_t                    a_q[N][$];
  ab_data_t                    b_q[N][$];
  c_data_t                     cout_q[N][$];

  bit first_cout_ready;
  bit last_cout_ready;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg==null) begin
      `uvm_fatal(get_name(), "driver cfg is null!")
    end else begin
      `uvm_info(get_name(), $sformatf("driver cfg: %s", cfg.convert2string()), UVM_NONE)
    end
    sem = new(1);
  endfunction

  function void add_to_q(seq_item_t itm);
    c_data_t                     cin;
    ab_data_t                    a;
    ab_data_t                    b;
    c_data_t                     cout;

    for (int i =0; i < N; i++) begin
      cin  = itm.c_din[i];
      a    = itm.a_din[i];
      b    = itm.b_din[i];
      cout = itm.c_dout[i];

      if (lane_delay_done==0) begin
        // delay
        for (int i=1; i < N; i++) begin
          repeat (i) a_q[i].push_back(0);
          repeat (i) b_q[i].push_back(0);
          repeat (i) cin_q[i].push_back(0);
          repeat (i) cout_q[i].push_back(0);
        end
        lane_delay_done = 1;
      end

      cin_q[i].push_back(cin);
      a_q[i].push_back(a);
      b_q[i].push_back(b);
      cout_q[i].push_back(cout);
    end

  endfunction

  function int get_matrix_delay();
    return (N * N); // since we are always mulpying NxM x MxN matrices
  endfunction

  virtual task get_item();
    seq_item_t req_item;

    forever begin
      `uvm_info(get_name(), "driver: getting item!", UVM_NONE)
      seq_item_port.get_next_item(req_item);
      sem.get();
      add_to_q(req_item.do_clone());
      sem.put();
      @(vif.drv);
      seq_item_port.item_done();
      `uvm_info(get_name(), "driver: item done!", UVM_NONE)
    end
  endtask

  function bit is_size_not_zero(drv_port_t port);
    if (port == A_DIN) begin
      foreach (a_q[i]) begin
        if (a_q[i].size() > 0) return 1;
      end
      return 0;
    end else if (port == B_DIN) begin
      foreach (b_q[i]) begin
        if (b_q[i].size() > 0) return 1;
      end
      return 0;
    end else if (port == C_DIN) begin
      foreach (cin_q[i]) begin
        if (cin_q[i].size() > 0) return 1;
      end
      return 0;
    end else begin
      foreach (cout_q[i]) begin
        if (cout_q[i].size() > 0) return 1;
      end
      return 0;
    end
  endfunction

  // drive a
  virtual task drive_a();
    int delay_count = 0;
    bit delay_done = 0;
    int b2b_in_count;
    bit in_valid_done;
    ab_data_t a_var;

    forever begin
      @(vif.drv);
      vif.drv.in_valid <= 0;
      if (is_size_not_zero(A_DIN)) begin
        if (delay_count >= cfg.m_a_delay_cycles || delay_done) begin

          for (int i=0; i< N; i++) begin
            if (a_q[i].size() >0) begin
              a_var = a_q[i].pop_front();
              vif.drv.a_din[i] <= a_var;
            end
          end
          delay_done = 1;
          `uvm_info(get_name(), "driver: drive_a() done!", UVM_NONE)

          // process in_valid
          if ((delay_count-cfg.m_a_delay_cycles) >= 2*N-2 ) begin
            if (!in_valid_done) begin
              vif.drv.in_valid <= 1;
              b2b_in_count = 1;
            end else begin
              if (b2b_in_count >= cfg.m_M) begin
                vif.drv.in_valid <= 1;
                b2b_in_count = 0;
              end
              b2b_in_count += 1;
            end
            in_valid_done =  1;
          end

        end
        delay_count += 1;
      end
    end
  endtask

   // drive b
  virtual task drive_b();
    ab_data_t b_var;

    forever begin
      @(vif.drv);
      if (is_size_not_zero(B_DIN)) begin

        for (int i=0; i< N; i++) begin
          if (b_q[i].size() >0) begin
            b_var = b_q[i].pop_front();
            vif.drv.b_din[i] <= b_var;
          end
        end
        `uvm_info(get_name(), "driver: drive_b() done!", UVM_NONE)
      end
    end
  endtask

  // drive cin
  virtual task drive_cin();
    int delay_count = 0;
    bit delay_done = 0;
    c_data_t c_var;

    forever begin
      @(vif.drv);
      if (is_size_not_zero(C_DIN)) begin
        if (delay_count >= cfg.m_c_delay_cycles || delay_done) begin

          for (int i=0; i< N; i++) begin
            if (cin_q[i].size() >0) begin
              c_var = cin_q[i].pop_front();
              vif.drv.c_din[i] <= c_var;
            end
          end
          delay_done = 1;
          `uvm_info(get_name(), "driver: drive_cin() done!", UVM_NONE)
        end
        delay_count += 1;
      end
    end
  endtask

  // drive cout
  virtual task drive_cout();
    int delay_count = 0;
    bit delay_done = 0;
    int unsigned b2b_out_count;
    c_data_t c_var;

    forever begin
      @(vif.drv);
      vif.drv.out_valid <= 0;

      if (is_size_not_zero(C_DOUT)) begin
        if (delay_count >= get_matrix_delay() || delay_done) begin

          for (int i=0; i< N; i++) begin
            if (cout_q[i].size() >0) begin
              c_var = cout_q[i].pop_front();
              vif.drv.c_dout[i] <= c_var;
            end else begin
              vif.drv.c_dout[i] <= 0;
            end
          end
          if (b2b_out_count >= cfg.m_M) begin
            b2b_out_count = 0;
            vif.drv.out_valid <= 1;
          end

          b2b_out_count += 1;
          delay_done = 1;
          `uvm_info(get_name(), "driver: drive_cout() done!", UVM_NONE)
        end
        delay_count += 1;
      end else begin
        for (int i=0; i< N; i++) begin
          vif.drv.c_dout[i] <= 0;
        end
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
            get_item();
            drive_a();
            drive_b();
            drive_cin();
            drive_cout();
          join
        end
      join_any
      disable fork;
      `uvm_info(get_name(), "driver: resetting driver!", UVM_NONE)
      for (int i=0; i < N; i++) begin
        cin_q[i].delete();
        a_q[i].delete();
        b_q[i].delete();
        cout_q[i].delete();
      end
      lane_delay_done = 0;
    end
  endtask
endclass

`endif


