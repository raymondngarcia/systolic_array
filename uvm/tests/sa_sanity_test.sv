`ifndef __SA_SANITY_TEST_SV__
`define __SA_SANITY_TEST_SV__

class sa_sanity_test extends sa_base_test;
  `uvm_component_utils (sa_sanity_test);

  typedef  sa_seq#(sa_pkg::DIN_WIDTH, sa_pkg::N, sa_pkg::M) sa_seq_t;
  sa_seq_t m_sa_seq;

  function new (string name="sa_sanity_test", uvm_component parent);
    super.new (name, parent);
  endfunction : new

  virtual task test_seq();
    `uvm_info(get_name(), "Start of test", UVM_LOW)

    m_sa_seq = sa_seq_t::type_id::create("m_sa_seq");
    if (!m_sa_seq.randomize() with {
      m_env_num == 0;
    }) begin
      `uvm_fatal(get_name(), "m_sa_seq randomization failed!")
    end

    m_sa_seq.start(m_env.m_sa_agt.sqr);

    // This will do the job as end of test indication. Although a more robust end-of-test sequence is very much recommended
    #100ns;
    `uvm_info(get_name(), "End of test", UVM_LOW)
  endtask

endclass
`endif

