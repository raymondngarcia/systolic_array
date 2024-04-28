`ifndef __SA_BASE_TEST_SV__
`define __SA_BASE_TEST_SV__

class sa_base_test extends uvm_test;

  `uvm_component_utils(sa_base_test)

  sa_env                  m_env;
  rand sa_env_cfg         m_env_cfg;

  function new(string name = "sa_base_test", uvm_component parent=null);
    super.new(name,parent);
    uvm_top.set_timeout(1ms,1);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_name(), "build_phase() started.",UVM_LOW)

    m_env_cfg = sa_env_cfg::type_id::create("m_env_cfg");
    m_env = sa_env::type_id::create("m_env", this);
    randomize_env_cfg();
    m_env.m_env_cfg_h = m_env_cfg;

    //uvm_config_db#(sa_env_cfg)::set(this, "m_env", "m_env_cfg", m_env_cfg);
  endfunction: build_phase

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_name(), "end_of_elaboration_phase() started.", UVM_LOW)
    uvm_top.print_topology();
    `uvm_info(get_name(), "end_of_elaboration_phase() ended.", UVM_LOW)
  endfunction: end_of_elaboration_phase

  function void start_of_simulation_phase (uvm_phase phase);
    super.start_of_simulation_phase(phase);
    uvm_config_db#(sa_env)::set(null,"*", "SA_ENV", m_env);
  endfunction: start_of_simulation_phase

  virtual task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    phase.raise_objection(this);
    `uvm_info(get_name(), "reset_phase() started.",UVM_LOW)
    // wait for reset negation
    `uvm_info(get_name(), "reset_phase() ended.",UVM_LOW)
    phase.drop_objection(this);
  endtask: reset_phase

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);
    `uvm_info(get_name(), "main_phase() started.",UVM_LOW)
    test_seq();
    `uvm_info(get_name(), "main_phase() ended.",UVM_LOW)
    phase.drop_objection(this);
  endtask: main_phase

  function void final_phase(uvm_phase phase);
    uvm_report_server svr;
    super.final_phase(phase);
    `uvm_info(get_name(), "final_phase() started.",UVM_LOW)
    svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR)) begin
      `uvm_info(get_name(), "\n SIMULATION RESULT: F-A-I-L-E-D\n", UVM_NONE)
    end else begin
      `uvm_info(get_name(), "\n SIMULATION RESULT: P-A-S-S-E-D\n", UVM_NONE)
    end
    `uvm_info(get_name(), "final_phase() ended.",UVM_LOW)
  endfunction: final_phase

  virtual function void randomize_env_cfg();
    if (!(m_env_cfg.randomize() with {
      m_sa_cfg.m_din_width == sa_pkg::DIN_WIDTH;
      m_sa_cfg.m_N         == sa_pkg::N;
      m_sa_cfg.m_M         == sa_pkg::M;
    })) begin
      `uvm_fatal(get_name(), "Randomization failed for m_env_cfg!")
    end
  endfunction

  virtual task test_seq();
    `uvm_fatal(get_name(), "test_seq(): Please define me in child class!")
  endtask
endclass

`endif // __SA_BASE_TEST_SV__
