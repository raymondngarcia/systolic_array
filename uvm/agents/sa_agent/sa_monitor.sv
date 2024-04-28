`ifndef __SA_MONITOR_SV__
`define __SA_MONITOR_SV__

class sa_monitor#(int unsigned DIN_WIDTH = 'd8, int unsigned N = 'd4) extends uvm_monitor;
  `uvm_component_param_utils(sa_monitor#(DIN_WIDTH, N))

  typedef sa_seq_item#(DIN_WIDTH, N)   seq_item_t;
  typedef bit signed [2*DIN_WIDTH-1:0] c_data_t;
  typedef bit signed [DIN_WIDTH-1:0]   ab_data_t;
  typedef enum { A_DIN, B_DIN, C_DIN, C_DOUT } drv_port_t;

  c_data_t                     cin_q[N][$];
  ab_data_t                    a_q[N][$];
  ab_data_t                    b_q[N][$];
  c_data_t                     cout_q[N][$];

  function new (string name, uvm_component parent);
    super.new (name, parent);
  endfunction

  virtual sa_if#(DIN_WIDTH, N) vif;

  uvm_analysis_port#(sa_seq_item#(DIN_WIDTH, N)) sa_port;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sa_port  = new("ag_ap", this);
  endfunction

  virtual task monitor_abc();
    bit first_valid;
    int unsigned diff;
    ab_data_t a, b;
    c_data_t c;
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
          `uvm_info(get_name(), $sformatf("Matrix A[%0d] %p", i, a_q[i]), UVM_NONE)
        end
        for (int i=0; i < N; i++) begin
          `uvm_info(get_name(), $sformatf("Matrix B[%0d] %p", i, b_q[i]), UVM_NONE)
        end
        for (int i=0; i < N; i++) begin
          `uvm_info(get_name(), $sformatf("Matrix C[%0d] %p", i, cin_q[i]), UVM_NONE)
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
            `uvm_info(get_name(), $sformatf("Matrix After A[%0d] %p", i, a_q[i]), UVM_NONE)
          end
          for (int i=0; i < N; i++) begin
            `uvm_info(get_name(), $sformatf("Matrix After B[%0d] %p", i, b_q[i]), UVM_NONE)
          end
          for (int i=0; i < N; i++) begin
            `uvm_info(get_name(), $sformatf("Matrix After C[%0d] %p", i, cin_q[i]), UVM_NONE)
          end
        end
        first_valid = 1;
      end
    end
  endtask

   virtual task monitor_cout();
    bit first_valid;
    int unsigned diff;
    c_data_t c;
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
      `uvm_info(get_name(), "monitor: resetting monitor!", UVM_NONE)
    end
  endtask
endclass

`endif


