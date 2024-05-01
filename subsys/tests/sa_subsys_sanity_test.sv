`ifndef __SA_SUBSYS_SANITY_TEST_SV__
`define __SA_SUBSYS_SANITY_TEST_SV__

class sa_subsys_sanity_test extends sa_subsys_base_test;
  `uvm_component_utils (sa_subsys_sanity_test)

  typedef sa_seq#(sa_subsys_pkg::DIN_WIDTH_0, sa_subsys_pkg::N_0, sa_subsys_pkg::M_0) sa_seq_0_t;
  typedef sa_seq#(sa_subsys_pkg::DIN_WIDTH_1, sa_subsys_pkg::N_1, sa_subsys_pkg::M_1) sa_seq_1_t;

  sa_seq_0_t m_sa_seq_0;
  sa_seq_1_t m_sa_seq_1;

  function new (string name="sa_subsys_sanity_test", uvm_component parent);
    super.new (name, parent);
  endfunction : new

  virtual task test_seq();
    `uvm_info(get_name(), "Start of test", UVM_LOW)

    m_sa_seq_0 = sa_seq_0_t::type_id::create("m_sa_seq_0");
    m_sa_seq_1 = sa_seq_1_t::type_id::create("m_sa_seq_1");

    if (!m_sa_seq_0.randomize() with {
      m_env_num == 0;
    } ) begin
      `uvm_fatal(get_name(), "m_sa_seq_0 randomization failed!")
    end
    if (!m_sa_seq_1.randomize() with {
      m_env_num == 1;
    }) begin
      `uvm_fatal(get_name(), "m_sa_seq_0 randomization failed!")
    end

    fork
      m_sa_seq_0.start(m_env_0.m_sa_agt.sqr);
      m_sa_seq_1.start(m_env_1.m_sa_agt.sqr);
    join_none
    wait fork;

    // This will do the job as end of test indication. Although a more robust end-of-test sequence is very much recommended
    #100ns;
    `uvm_info(get_name(), "End of test", UVM_LOW)
  endtask

endclass
`endif

