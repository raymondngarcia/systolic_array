`ifndef __SA_SUBSYS_BASE_TEST_SV__
`define __SA_SUBSYS_BASE_TEST_SV__

class sa_subsys_base_test extends uvm_test;

  `uvm_component_utils(sa_subsys_base_test)

  typedef sa_env#(sa_subsys_pkg::DIN_WIDTH_0, sa_subsys_pkg::N_0, sa_subsys_pkg::M_0) sa_env_0_t;
  typedef sa_env#(sa_subsys_pkg::DIN_WIDTH_1, sa_subsys_pkg::N_1, sa_subsys_pkg::M_1) sa_env_1_t;

  sa_env_0_t              m_env_0;
  sa_env_1_t              m_env_1;
  rand sa_env_cfg         m_env_cfg[NUM_SA];

  function new(string name = "sa_subsys_base_test", uvm_component parent=null);
    super.new(name,parent);
    uvm_top.set_timeout(1ms,1);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_name(), "build_phase() started.",UVM_LOW)

    for (int i=0; i < NUM_SA; i++) begin
      m_env_cfg[i] = sa_env_cfg::type_id::create($sformatf("m_env_cfg_%0d", i));
    end
    randomize_env_cfg();

    m_env_0 = sa_env_0_t::type_id::create("m_env_0", this);
    m_env_0.m_env_cfg_h = m_env_cfg[0];

    m_env_1 = sa_env_1_t::type_id::create("m_env_1", this);
    m_env_1.m_env_cfg_h = m_env_cfg[1];
  endfunction: build_phase

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_name(), "end_of_elaboration_phase() started.", UVM_LOW)
    uvm_top.print_topology();
    `uvm_info(get_name(), "end_of_elaboration_phase() ended.", UVM_LOW)
  endfunction: end_of_elaboration_phase

  function void start_of_simulation_phase (uvm_phase phase);
    super.start_of_simulation_phase(phase);
    for (int i=0; i < NUM_SA; i++) begin
      if (i==0) uvm_config_db#(sa_env_0_t)::set(null,"*", $sformatf("SA_ENV_%0d", i), m_env_0);
      if (i==1) uvm_config_db#(sa_env_1_t)::set(null,"*", $sformatf("SA_ENV_%0d", i), m_env_1);
    end
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
    for (int i=0; i < NUM_SA; i++) begin
      if (!(m_env_cfg[i].randomize())) begin
        `uvm_fatal(get_name(), "Randomization failed for m_env_cfg!")
      end
    end
  endfunction

  virtual task test_seq();
    `uvm_fatal(get_name(), "test_seq(): Please define me in child class!")
  endtask
endclass

`endif // __SA_SUBSYS_BASE_TEST_SV__
