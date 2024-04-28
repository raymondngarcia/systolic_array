`ifndef IDF_ODR_ADDR_GEN_REF_MODEL_SV
`define IDF_ODR_ADDR_GEN_REF_MODEL_SV

class ifd_odr_addr_gen_ref_model extends uvm_component;
  `uvm_component_utils(ifd_odr_addr_gen_ref_model)

  addr_gen_cmd_t             addr_gen_cmd;
  bit                        regression = 0;
  bit                        sanity = 0;
  bit                        vsim = 0;
  ifd_odr_addr_gen_seq_item  cmd_in_item, cmd_out_item;
 `ifdef AI_CORE_TOP_ENV_CHECK
  string                     refmodel_path = "../../../../ai_core_ls/uvm_env/refmodels/ifd_odr_addr_gen_ref_model"; // always relative to where simulation is taking place, default is regression mode
 `else
  string                     refmodel_path = "../../../uvm_env/refmodels/ifd_odr_addr_gen_ref_model"; // always relative to where simulation is taking place, default is regression mode
 `endif

  string                     txt_filename = "*addr_gen_cmd.txt";
  string                     vtrsp_odr_stream_filename;
  string                     vtrsp_odr_memory_filename;
  string                     icdf_dir = "icdf";
  string                     icdf_out_dir = "icdf_out";
  string                     python_version = "python3.8";
  string                     model_name;
  uvm_tlm_analysis_fifo#(ifd_odr_addr_gen_seq_item) cmd_in;
  uvm_analysis_port#(ifd_odr_addr_gen_seq_item)     cmd_out;
  uvm_analysis_port#(odr_stream_mem_t)              vtrsp_out; // post memory snaopshot of vector transposed data

  mem_baseaddr_t             l1_base_addr;
  mem_baseaddr_t             mem_baseaddr;
  bit                        m_addr_out_of_range_en;
  bit                        m_vtrsp_err_en;
  int unsigned               mem_bsize;
  bit                        m_last_addr_out_of_range;
  stream_info_t              m_stream_info_q[$];
  semaphore                  m_semaphore;
  int8_data_arr_t            m_int8_q[$];
  odr_stream_data_t          m_mem_q[odr_stream_addr_t];     // per command memory
  odr_stream_data_t          m_abs_mem_q[odr_stream_addr_t]; // whole memory model
  bit                        m_all_padded;
  int                        m_cmd_counter;

  event                      m_rst_evt;
  event                      m_rst_done_evt;

  function new(string name ="", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    int unsigned seed;
    string testcase_name;
    super.build_phase(phase);
    cmd_in   = new("cmd_in", this);
    cmd_out  = new("cmd_out" , this);
    if (get_device_name() == "d_odr") begin
      vtrsp_out  = new("vtrsp_out" , this);
    end
    void'($value$plusargs("REGRESSION=%0d", regression));
    void'($value$plusargs("SANITY=%0d", sanity));
    void'($value$plusargs("VSIM=%0d", vsim));
    if (regression==0 || sanity==1) begin
      if (vsim==0) begin
        refmodel_path = refmodel_path.substr(6, refmodel_path.len()-1); // remove ../../ or 2 directory less
      end else begin
        refmodel_path = refmodel_path.substr(3, refmodel_path.len()-1); // remove ../ or 1 directory less
      end
    end
    `uvm_info(get_name(), $sformatf("Debug  VSIM: %0d", vsim), UVM_LOW)
    if ($value$plusargs("UVM_TESTNAME=%s", testcase_name)) begin
      seed = $get_initial_random_seed();
    end else begin
      `uvm_fatal(get_name(), $sformatf("Tescase name not found!, %s", testcase_name))
    end
    model_name = $sformatf("%s_%s_%0d", testcase_name, get_name(), seed); // make it unique so it supports regression
    m_semaphore = new(1);
  endfunction : build_phase

  virtual task run_model();
    forever begin
      cmd_in.get(cmd_in_item);
      if (cmd_in_item.m_has_cmd) begin
        addr_gen_cmd = cmd_in_item.m_cmd;
        `uvm_info(get_name(), $sformatf("Received ifd_odr_addr_gen_seq_item: %s", cmd_in_item.convert2string()), UVM_LOW)
        do_mdl();
      end
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    ifd_odr_addr_gen_seq_item itm;
    super.run_phase(phase);
    $system($sformatf("ln -sf %s/create_instr.sh", refmodel_path));
    $system($sformatf("ln -sf %s/replace_mem_baseaddr.sh", refmodel_path));

    forever begin
      fork
        run_model();
        begin
          @ (m_rst_evt);
          m_stream_info_q.delete();
          while(cmd_in.try_get(itm));
          void'(m_semaphore.try_get());
          m_semaphore.put();
          @ (m_rst_done_evt);
          m_abs_mem_q.delete();
          m_cmd_counter = 0;
        end
      join_any
      disable fork;
    end
  endtask : run_phase

  /* TODO: remove once all commands are fully supported
    #!/bin/sh
    # setup instructions
    python -m testing.rtldebugger.filebased.cli -p single_dir -r set_instr -m m_odr --instr-file 4dim_instr.yml
    # setup ODR's
    #python -m testing.rtldebugger.filebased.cli -p single_dir -r send_cmd -m m_odr --cmd '{"cmd_format": "def_based", "mem_baseaddr": 402653184, "pad_val": 48, "mask_start": 0, "mask_end": 64, "mem_offset": 0, "ring_buf_size": 0, "dim_def_ptr": 0, "loop_def_ptr": 16, "num_dim": 4, "vect_dim": 3, "vtrsp_mode": 0, "pad_mode": 0, "mem_bsize": 0}'
    python -m testing.rtldebugger.filebased.cli -p single_dir -r send_cmd -m m_odr --cmd '{"cmd_format": "four_dim_fallback", "mem_baseaddr": 402653184, "pad_val": 48, "mask_start": 0, "mask_end": 64, "mem_offset": 0, "ring_buf_size": 0, "vect_dim": 3, "vtrsp_mode": 0, "pad_mode": 0, "mem_bsize": 0, "dim_width_a": 1, "dim_width_b": 1, "dim_width_c": 1, "dim_width_d": 1, "dim_offset_a": 0, "dim_offset_b": 0, "dim_offset_c": 0, "dim_offset_d": 0, "mem_stride_a": 0, "mem_stride_b": 0, "mem_stride_c": 0, "mem_stride_d": 0, "inner_length_a": 1, "inner_length_b": 1, "inner_length_c": 1, "inner_length_d": 1, "outer_length_a": 1, "outer_length_b": 1, "outer_length_c": 1, "outer_length_d": 1, "inner_stride_a": 1, "inner_stride_b": 1, "inner_stride_c": 1, "inner_stride_d": 1, "outer_stride_a": 1, "outer_stride_b": 1, "outer_stride_c": 1, "outer_stride_d": 1}'
    #python -m testing.rtldebugger.filebased.cli -p single_dir -r set_stream -m m_odr --stream-file test_stream.yml --in-stream-port m_dpu
    # execute test
    #python -m testing.rtldebugger.filebased.cli -p single_dir -r execute
    # execute address generation
    python -m testing.rtldebugger.filebased.cli -p single_dir -r execute_ifd_odr -m m_odr
    # get expected post memory snapshot
    #python -m testing.rtldebugger.filebased.cli -p single_dir -r get_memory
  */

  function string get_device_name();
    string dev_name, out_name;
    dev_name = get_name();
    dev_name = dev_name.substr(2, dev_name.len()-9); // minus m_ and _ref_mdl

    case (dev_name)
      "m_ifd0": out_name = "m_ifd_0";
      "m_ifd1": out_name = "m_ifd_1";
      "m_ifdw": out_name = "m_ifd_w";
      "d_ifd0": out_name = "d_ifd_0";
      "d_ifd1": out_name = "d_ifd_1";
      "m_odr" : out_name = "m_odr";
      "d_odr" : out_name = "d_odr";
    endcase

    return out_name;
  endfunction

  function string create_icdf_dir();
    string bash_cmd = "";
    if (regression==0 || sanity == 1) begin
      if (vsim==0) begin
        $sformat(bash_cmd, "rm -rf %s/%s && mkdir -p %s/%s", icdf_out_dir, model_name, icdf_out_dir, model_name); // mkdir
      end else begin
        $sformat(bash_cmd, "rm -rf ../%s/%s && mkdir -p ../%s/%s", icdf_out_dir, model_name, icdf_out_dir, model_name); // mkdir
      end
    end else begin
      $sformat(bash_cmd, "rm -rf ../../%s/%s && mkdir -p ../../%s/%s", icdf_out_dir, model_name, icdf_out_dir, model_name); // mkdir
    end
    return bash_cmd;
  endfunction

  function string go_to_icdf_dir();
    string bash_cmd = "";
    if (regression==0 || sanity == 1) begin
      if (vsim==0) begin
        $sformat(bash_cmd, "cd %s", icdf_dir);
      end else begin
        $sformat(bash_cmd, "cd ../%s", icdf_dir);
      end
    end else begin
      $sformat(bash_cmd, "cd ../../%s", icdf_dir);
    end
    return bash_cmd;
  endfunction

  function string get_icdf_out_dir();
    string bash_cmd = "";

    if (regression==0 || sanity == 1) begin
      if (vsim==0) begin
        $sformat(bash_cmd, "%s", icdf_out_dir);
      end else begin
        $sformat(bash_cmd, "../%s", icdf_out_dir);
      end
    end else begin
      $sformat(bash_cmd, "../../%s", icdf_out_dir);
    end
    return bash_cmd;
  endfunction

  function void run_cmd();
    string bash_cmd;
    if (cmd_in_item == null) begin
      `uvm_fatal(get_name(), "cmd_in_item is null!")
    end

    mem_baseaddr = cmd_in_item.get_mem_base_addr();
    mem_bsize = (m_addr_out_of_range_en)? 0: cmd_in_item.m_mem_bsize;

    bash_cmd = create_icdf_dir();
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)

    case (cmd_in_item.m_cmd_format)
      CMDFORMAT_LINEAR        : run_linear_cmd();
      CMDFORMAT_DEF_BASED     : run_def_based_cmd();
      CMDFORMAT_OFFSET_BASED  : run_offset_based_cmd();
      CMDFORMAT_3DIM_FALLBACK : run_3dim_fallback_cmd();
      CMDFORMAT_4DIM_FALLBACK : run_4dim_fallback_cmd();
      default: `uvm_fatal(get_name(), $sformatf("Invalid command format of %s !", cmd_in_item.m_cmd_format.name()))
    endcase
  endfunction

  function void run_linear_cmd();
    string bash_cmd = go_to_icdf_dir();
    // e.g. python3 -m testing.rtldebugger.filebased.cli -p exchange_dir -r send_cmd -m m_ifd_1 --cmd '{"cmd_format": "linear", "mem_baseaddr": 0, "compression": 0, "length": 4}'
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r send_cmd -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $sformat(bash_cmd, "%s --cmd '{\"cmd_format\": \"linear\", \"mem_baseaddr\": %0d, \"compression\": %0d, \"length\": %0d}'", bash_cmd, mem_baseaddr, cmd_in_item.m_decomp_en, cmd_in_item.m_length);
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r execute_ifd_odr -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
  endfunction

  function void run_def_based_cmd();
    string bash_cmd;
    int loop_ptr, dim_ptr;

    // e.g. python -m testing.rtldebugger.filebased.cli -p single_dir -r set_instr -m m_odr --instr-file 4dim_instr.yml
    $sformat(bash_cmd, "./create_instr.sh %s %s.yaml 1 dim_def %0d %0d %0d", get_icdf_out_dir(), model_name, cmd_in_item.m_dim_offset_a, cmd_in_item.m_dim_width_a, cmd_in_item.m_mem_stride_a);
    if (cmd_in_item.m_num_dim > 1) begin
      $sformat(bash_cmd, "%s dim_def %0d %0d %0d", bash_cmd, cmd_in_item.m_dim_offset_b, cmd_in_item.m_dim_width_b, cmd_in_item.m_mem_stride_b);
    end
    if (cmd_in_item.m_num_dim > 2) begin
      $sformat(bash_cmd, "%s dim_def %0d %0d %0d", bash_cmd, cmd_in_item.m_dim_offset_c, cmd_in_item.m_dim_width_c, cmd_in_item.m_mem_stride_c);
    end
    if (cmd_in_item.m_num_dim > 3) begin
      $sformat(bash_cmd, "%s dim_def %0d %0d %0d", bash_cmd, cmd_in_item.m_dim_offset_d, cmd_in_item.m_dim_width_d, cmd_in_item.m_mem_stride_d);
    end
    $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_a, cmd_in_item.m_inner_stride_a, cmd_in_item.m_outer_length_a, cmd_in_item.m_outer_stride_a);
    if (cmd_in_item.m_num_dim > 1) begin
      $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_b, cmd_in_item.m_inner_stride_b, cmd_in_item.m_outer_length_b, cmd_in_item.m_outer_stride_b);
    end
    if (cmd_in_item.m_num_dim > 2) begin
      $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_c, cmd_in_item.m_inner_stride_c, cmd_in_item.m_outer_length_c, cmd_in_item.m_outer_stride_c);
    end
    if (cmd_in_item.m_num_dim > 3) begin
      $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_d, cmd_in_item.m_inner_stride_d, cmd_in_item.m_outer_length_d, cmd_in_item.m_outer_stride_d);
    end
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r set_instr -m %s --instr-file ../%s/%s.yaml", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name(), icdf_out_dir, model_name);
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    dim_ptr = 0; // to simplify, feed the RTL debugger adjacent mem locations, only randomize in DUT
    loop_ptr = cmd_in_item.m_num_dim;

    // e.g. python3 -m testing.rtldebugger.filebased.cli -p single_dir -r send_cmd -m m_odr --cmd '{"cmd_format": "def_based", "mem_baseaddr": 402653184, "pad_val": 48, "mask_start": 0, "mask_end": 64, "mem_offset": 0, "ring_buf_size": 0, "dim_def_ptr": 0, "loop_def_ptr": 16, "num_dim": 4, "vect_dim": 3, "vtrsp_mode": 0, "pad_mode": 0, "mem_bsize": 0}'
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r send_cmd -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $sformat(bash_cmd, "%s --cmd '{\"cmd_format\": \"def_based\", \"mem_baseaddr\": %0d, \"pad_val\": %0d, \"mask_start\": %0d, \"mask_end\": %0d,", bash_cmd, mem_baseaddr,  cmd_in_item.m_pad_val, cmd_in_item.m_mask_start, cmd_in_item.m_mask_end);
    $sformat(bash_cmd, "%s \"mem_offset\": %0d, \"ring_buf_size\": %0d, \"dim_def_ptr\": %0d, \"loop_def_ptr\": %0d, \"num_dim\": %0d,", bash_cmd, cmd_in_item.m_mem_offset, cmd_in_item.m_ring_buff_size, dim_ptr, loop_ptr, cmd_in_item.m_num_dim);
    $sformat(bash_cmd, "%s \"vect_dim\": %0d, \"vtrsp_mode\": %0d, \"pad_mode\": %0d, \"mem_bsize\": %0d}'", bash_cmd, cmd_in_item.m_vect_dim, cmd_in_item.m_vtrsp_mode, cmd_in_item.m_pad_mode, mem_bsize);
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r execute_ifd_odr -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
  endfunction

  function void run_offset_based_cmd();
    string bash_cmd = go_to_icdf_dir();
    int loop_ptr, dim_ptr;

    $sformat(bash_cmd, "./create_instr.sh %s %s.yaml 1 dim_def 0 %0d %0d", get_icdf_out_dir(), model_name, cmd_in_item.m_dim_width_a, cmd_in_item.m_mem_stride_a);
    if (cmd_in_item.m_num_dim > 1) begin
      $sformat(bash_cmd, "%s dim_def 0 %0d %0d", bash_cmd, cmd_in_item.m_dim_width_b, cmd_in_item.m_mem_stride_b);
    end
    if (cmd_in_item.m_num_dim > 2) begin
      $sformat(bash_cmd, "%s dim_def 0 %0d %0d", bash_cmd, cmd_in_item.m_dim_width_c, cmd_in_item.m_mem_stride_c);
    end
    if (cmd_in_item.m_num_dim > 3) begin
      $sformat(bash_cmd, "%s dim_def 0 %0d %0d", bash_cmd, cmd_in_item.m_dim_width_d, cmd_in_item.m_mem_stride_d);
    end

    $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_a, cmd_in_item.m_inner_stride_a, cmd_in_item.m_outer_length_a, cmd_in_item.m_outer_stride_a);
    if (cmd_in_item.m_num_dim > 1) begin
      $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_b, cmd_in_item.m_inner_stride_b, cmd_in_item.m_outer_length_b, cmd_in_item.m_outer_stride_b);
    end
    if (cmd_in_item.m_num_dim > 2) begin
      $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_c, cmd_in_item.m_inner_stride_c, cmd_in_item.m_outer_length_c, cmd_in_item.m_outer_stride_c);
    end
    if (cmd_in_item.m_num_dim > 3) begin
      $sformat(bash_cmd, "%s loop_def %0d %0d %0d %0d", bash_cmd, cmd_in_item.m_inner_length_d, cmd_in_item.m_inner_stride_d, cmd_in_item.m_outer_length_d, cmd_in_item.m_outer_stride_d);
    end
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r set_instr -m %s --instr-file ../%s/%s.yaml", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name(), icdf_out_dir, model_name);
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)

    dim_ptr = 0; // to simplify, feed the RTL debugger adjacent mem locations, only randomize in DUT
    loop_ptr = cmd_in_item.m_num_dim;

    // e.g. python3 -m testing.rtldebugger.filebased.cli -p single_dir -r send_cmd -m m_odr --cmd '{"cmd_format": "offset_based", "mem_baseaddr": 402653184, "pad_val": 48, "mask_start": 0, "mask_end": 64, "mem_offset": 0, "ring_buf_size": 0, "dim_def_ptr": 0, "loop_def_ptr": 16, "num_dim": 4, "vect_dim": 3, "vtrsp_mode": 0, "pad_mode": 0, "mem_bsize": 0}'
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r send_cmd -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $sformat(bash_cmd, "%s --cmd '{\"cmd_format\": \"offset_def_based\", \"mem_baseaddr\": %0d, \"pad_val\": %0d, \"mask_start\": %0d, \"mask_end\": %0d,", bash_cmd, mem_baseaddr,  cmd_in_item.m_pad_val, cmd_in_item.m_mask_start, cmd_in_item.m_mask_end);
    $sformat(bash_cmd, "%s \"mem_offset\": %0d, \"ring_buf_size\": %0d, \"dim_def_ptr\": %0d, \"loop_def_ptr\": %0d, \"num_dim\": %0d,", bash_cmd, cmd_in_item.m_mem_offset, cmd_in_item.m_ring_buff_size, dim_ptr, loop_ptr, cmd_in_item.m_num_dim);
    $sformat(bash_cmd, "%s \"dim_offset_a\": %0d,", bash_cmd, cmd_in_item.m_dim_offset_a);
    if (cmd_in_item.m_num_dim > 1) begin
      $sformat(bash_cmd, "%s \"dim_offset_b\": %0d,", bash_cmd, cmd_in_item.m_dim_offset_b);
    end else begin
      $sformat(bash_cmd, "%s \"dim_offset_b\": 0,", bash_cmd);
    end
    if (cmd_in_item.m_num_dim > 2) begin
      $sformat(bash_cmd, "%s \"dim_offset_c\": %0d,", bash_cmd, cmd_in_item.m_dim_offset_c);
    end else begin
      $sformat(bash_cmd, "%s \"dim_offset_c\": 0,", bash_cmd);
    end
    if (cmd_in_item.m_num_dim > 3) begin
      $sformat(bash_cmd, "%s \"dim_offset_d\": %0d,", bash_cmd, cmd_in_item.m_dim_offset_d);
    end else begin
      $sformat(bash_cmd, "%s \"dim_offset_d\": 0,", bash_cmd);
    end
    $sformat(bash_cmd, "%s \"vect_dim\": %0d, \"vtrsp_mode\": %0d, \"pad_mode\": %0d, \"mem_bsize\": %0d}'", bash_cmd, cmd_in_item.m_vect_dim, cmd_in_item.m_vtrsp_mode, cmd_in_item.m_pad_mode, mem_bsize);
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r execute_ifd_odr -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
  endfunction

  function void run_3dim_fallback_cmd();
    string bash_cmd = go_to_icdf_dir();

    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r send_cmd -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $sformat(bash_cmd, "%s --cmd '{\"cmd_format\": \"three_dim_fallback\", \"mem_baseaddr\": %0d, \"pad_val\": %0d, \"mask_start\": %0d, \"mask_end\": %0d,", bash_cmd, mem_baseaddr,  cmd_in_item.m_pad_val, cmd_in_item.m_mask_start, cmd_in_item.m_mask_end);
    $sformat(bash_cmd, "%s \"mem_offset\": %0d, \"ring_buf_size\": %0d, \"dim_offset_a\": %0d, \"dim_offset_b\": %0d, \"dim_offset_c\": %0d,", bash_cmd, cmd_in_item.m_mem_offset, cmd_in_item.m_ring_buff_size, cmd_in_item.m_dim_offset_a, cmd_in_item.m_dim_offset_b, cmd_in_item.m_dim_offset_c);
    $sformat(bash_cmd, "%s \"vect_dim\": %0d, \"vtrsp_mode\": %0d, \"pad_mode\": %0d, \"mem_bsize\": %0d,", bash_cmd, cmd_in_item.m_vect_dim, cmd_in_item.m_vtrsp_mode, cmd_in_item.m_pad_mode, mem_bsize);
    $sformat(bash_cmd, "%s \"dim_width_a\": %0d, \"dim_width_b\": %0d, \"dim_width_c\": %0d,", bash_cmd, cmd_in_item.m_dim_width_a, cmd_in_item.m_dim_width_b, cmd_in_item.m_dim_width_c);
    $sformat(bash_cmd, "%s \"mem_stride_a\": %0d, \"mem_stride_b\": %0d, \"mem_stride_c\": %0d,", bash_cmd, cmd_in_item.m_mem_stride_a, cmd_in_item.m_mem_stride_b, cmd_in_item.m_mem_stride_c);
    $sformat(bash_cmd, "%s \"inner_length_a\": %0d, \"inner_length_b\": %0d, \"inner_length_c\": %0d,", bash_cmd, cmd_in_item.m_inner_length_a, cmd_in_item.m_inner_length_b, cmd_in_item.m_inner_length_c);
    $sformat(bash_cmd, "%s \"outer_length_a\": %0d, \"outer_length_b\": %0d, \"outer_length_c\": %0d,", bash_cmd, cmd_in_item.m_outer_length_a, cmd_in_item.m_outer_length_b, cmd_in_item.m_outer_length_c);
    $sformat(bash_cmd, "%s \"inner_stride_a\": %0d, \"inner_stride_b\": %0d, \"inner_stride_c\": %0d,", bash_cmd, cmd_in_item.m_inner_stride_a, cmd_in_item.m_inner_stride_b, cmd_in_item.m_inner_stride_c);
    $sformat(bash_cmd, "%s \"outer_stride_a\": %0d, \"outer_stride_b\": %0d, \"outer_stride_c\": %0d}'", bash_cmd, cmd_in_item.m_outer_stride_a, cmd_in_item.m_outer_stride_b, cmd_in_item.m_outer_stride_c);
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r execute_ifd_odr -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
  endfunction

  function void run_4dim_fallback_cmd();
    string bash_cmd =  go_to_icdf_dir();

    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r send_cmd -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $sformat(bash_cmd, "%s --cmd '{\"cmd_format\": \"four_dim_fallback\", \"mem_baseaddr\": %0d, \"pad_val\": %0d, \"mask_start\": %0d, \"mask_end\": %0d,", bash_cmd, mem_baseaddr,  cmd_in_item.m_pad_val, cmd_in_item.m_mask_start, cmd_in_item.m_mask_end);
    $sformat(bash_cmd, "%s \"mem_offset\": %0d, \"ring_buf_size\": %0d, \"dim_offset_a\": %0d, \"dim_offset_b\": %0d, \"dim_offset_c\": %0d, \"dim_offset_d\": %0d,", bash_cmd, cmd_in_item.m_mem_offset, cmd_in_item.m_ring_buff_size, cmd_in_item.m_dim_offset_a, cmd_in_item.m_dim_offset_b, cmd_in_item.m_dim_offset_c, cmd_in_item.m_dim_offset_d);
    $sformat(bash_cmd, "%s \"vect_dim\": %0d, \"vtrsp_mode\": %0d, \"pad_mode\": %0d, \"mem_bsize\": %0d,", bash_cmd, cmd_in_item.m_vect_dim, cmd_in_item.m_vtrsp_mode, cmd_in_item.m_pad_mode, mem_bsize);
    $sformat(bash_cmd, "%s \"dim_width_a\": %0d, \"dim_width_b\": %0d, \"dim_width_c\": %0d, \"dim_width_d\": %0d,", bash_cmd, cmd_in_item.m_dim_width_a, cmd_in_item.m_dim_width_b, cmd_in_item.m_dim_width_c, cmd_in_item.m_dim_width_d);
    $sformat(bash_cmd, "%s \"mem_stride_a\": %0d, \"mem_stride_b\": %0d, \"mem_stride_c\": %0d, \"mem_stride_d\": %0d,", bash_cmd, cmd_in_item.m_mem_stride_a, cmd_in_item.m_mem_stride_b, cmd_in_item.m_mem_stride_c, cmd_in_item.m_mem_stride_d);
    $sformat(bash_cmd, "%s \"inner_length_a\": %0d, \"inner_length_b\": %0d, \"inner_length_c\": %0d, \"inner_length_d\": %0d,", bash_cmd, cmd_in_item.m_inner_length_a, cmd_in_item.m_inner_length_b, cmd_in_item.m_inner_length_c, cmd_in_item.m_inner_length_d);
    $sformat(bash_cmd, "%s \"outer_length_a\": %0d, \"outer_length_b\": %0d, \"outer_length_c\": %0d, \"outer_length_d\": %0d,", bash_cmd, cmd_in_item.m_outer_length_a, cmd_in_item.m_outer_length_b, cmd_in_item.m_outer_length_c, cmd_in_item.m_outer_length_d);
    $sformat(bash_cmd, "%s \"inner_stride_a\": %0d, \"inner_stride_b\": %0d, \"inner_stride_c\": %0d, \"inner_stride_d\": %0d,", bash_cmd, cmd_in_item.m_inner_stride_a, cmd_in_item.m_inner_stride_b, cmd_in_item.m_inner_stride_c, cmd_in_item.m_inner_stride_d);
    $sformat(bash_cmd, "%s \"outer_stride_a\": %0d, \"outer_stride_b\": %0d, \"outer_stride_c\": %0d, \"outer_stride_d\": %0d}'", bash_cmd, cmd_in_item.m_outer_stride_a, cmd_in_item.m_outer_stride_b, cmd_in_item.m_outer_stride_c, cmd_in_item.m_outer_stride_d);
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r execute_ifd_odr -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    $system(bash_cmd);
    `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_NONE)
  endfunction

  virtual task read_addr_gen_output();
    string line;
    int file_handle, index;
    bit [35:0] addr;
    bit [AI_CORE_LS_PWORD_SIZE-1:0] msk;
    bit pad;
    int pad_val;
    int counter=0;
    int num_pword;
    ifd_odr_addr_gen_seq_item addr_item_q[$];
    stream_info_t stream_info;

    if (regression==0 || sanity == 1) begin
      if (vsim==0) begin
        txt_filename = $sformatf("%s/%s/output/dp_ctrl_stream_%s.txt", icdf_out_dir, model_name, get_device_name());
      end else begin
        txt_filename = $sformatf("../%s/%s/output/dp_ctrl_stream_%s.txt", icdf_out_dir, model_name, get_device_name());
      end
    end else begin
      txt_filename = $sformatf("../../%s/%s/output/dp_ctrl_stream_%s.txt", icdf_out_dir, model_name, get_device_name());
    end

    file_handle = $fopen(txt_filename, "r");
    if (file_handle) begin
        m_last_addr_out_of_range = 0;
        m_all_padded = 1;
        while($fgets(line,file_handle)) begin
            if (counter !=0) begin // skip txt file header
              void'($sscanf(line, "#%d addr: %h msk: %h pad: %d pad_val: %h", index, addr,msk,pad,pad_val));
              `uvm_info(get_type_name(), $sformatf("refmodel_dbg: %0d addr: %h msk: %h pad: %d pad_val: %h ... mem_baseaddr: 0x%0x mem_bsize: 0x%0x", index, addr,msk,pad,pad_val, mem_baseaddr, addr_gen_cmd.mem_bsize), UVM_HIGH)
              cmd_out_item = ifd_odr_addr_gen_seq_item::type_id::create("out_item");
              cmd_out_item.do_copy(cmd_in_item);
              cmd_out_item.m_has_dpc_cmd = 1;
              cmd_out_item.m_dpc_cmd.dpc_addr = addr;
              cmd_out_item.m_dpc_cmd.dpc_msk = msk;
              cmd_out_item.m_dpc_cmd.dpc_pad = pad;
              cmd_out_item.m_dpc_cmd.dpc_pad_val = pad_val; // cmd.pad_val;
              cmd_out_item.m_dpc_cmd.err_addr_out_of_range = !(addr inside {[mem_baseaddr : mem_baseaddr + addr_gen_cmd.mem_bsize]}) && !pad;
              // Error addr out of range only when mem_bsize != 0
              cmd_out_item.m_dpc_cmd.err_addr_out_of_range = cmd_out_item.m_dpc_cmd.err_addr_out_of_range & (addr_gen_cmd.mem_bsize !=0);
              addr_item_q.push_back(cmd_out_item); // add into queue first because setting of dpc_last needs to be done.
              m_last_addr_out_of_range = cmd_out_item.m_dpc_cmd.err_addr_out_of_range || m_last_addr_out_of_range;
              if (pad==0 ) begin
                m_all_padded = 0;
                num_pword += 1;
              end
            end
            counter+=1;
        end
        $fclose(file_handle);
        if (addr_item_q.size() > 0) begin
          int a_size = addr_item_q.size()-1;
          addr_item_q[$].m_dpc_cmd.dpc_last = 1;
          addr_item_q[$].m_pword_len = num_pword; // for coverage
        end
    end
    if (addr_item_q.size()==0) begin
      #100ns;
      `uvm_fatal(get_name(), "Got size of 0 for address generator! Please check the command used!")
    end else begin
      `uvm_info(get_name(), $sformatf("[%0d] Got size of %0d for address generator!", m_cmd_counter, addr_item_q.size()), UVM_LOW)
      m_cmd_counter += 1;
    end
    foreach (addr_item_q[i]) begin
      if (cmd_in_item.m_vtrsp_mode!=0 || get_device_name()== "d_odr") begin
        if (i==0) begin
          m_mem_q.delete();
        end
      end
      // removed sanity check as there is cmdb vs addr_gen command comparison already added
      cmd_out.write(addr_item_q[i]);
      `uvm_info(get_name(), $sformatf("addr_item_q[%0d]: %h", i, addr_item_q[i].m_dpc_cmd.dpc_addr), UVM_HIGH)
      `uvm_info(get_name(), $sformatf("[%0d] VTRSP MODE: %0d PWORD: %0d",  i, addr_item_q[i].m_vtrsp_mode, addr_item_q[i].m_pword_len), UVM_HIGH)
    end
    stream_info.length = addr_item_q.size();
    stream_info.used = 0;
    m_stream_info_q.push_back(stream_info);
    `uvm_info(get_name(), $sformatf("Address out of range: %0d", m_last_addr_out_of_range), UVM_HIGH)
  endtask

  // waits the most recent address gen stream info
  virtual task wait_address_gen_output(ref int unsigned len);
    int indx;
    int q_size;
    int effective_indx;
    m_semaphore.get();
    indx = -1;
    q_size = m_stream_info_q.size();
    foreach(m_stream_info_q[i]) begin
      if (m_stream_info_q[i].used == 0) begin
        indx = i;
        break;
      end
    end
    if (indx != -1) begin
      len = m_stream_info_q[indx].length;
      m_stream_info_q[indx].used = 1;
      effective_indx = indx;
    end else begin
      fork
        wait (m_stream_info_q.size() == q_size + 1);
        begin
          #300us; // this will be enough to support outstanding commands
          `uvm_fatal(get_name(), "Timeout getting length from refmodel!")
        end
      join_any
      disable fork;
      len = m_stream_info_q[q_size].length;
      m_stream_info_q[q_size].used = 1;
      effective_indx = q_size;
    end
    `uvm_info(get_name(), $sformatf("Wait done with value of m_stream_info_q[%0d] %0d", effective_indx, len), UVM_LOW)
    m_semaphore.put();
  endtask

  task get_odr_stream(odr_stream_data_t odr_stream[$]);
    int8_data_arr_t int8_arr;
    bit[7:0] curr_byte;
    string s="";
    string cmd;
    int fd;

    if (m_vtrsp_err_en==1) return; // avoid ICDF assertion errors

    if (regression==0 || sanity == 1) begin
      if (vsim == 0) begin
        vtrsp_odr_stream_filename = $sformatf("%s/%s/vtrsp_odr_stream.yaml", icdf_out_dir, model_name);
        vtrsp_odr_memory_filename = $sformatf("%s/%s/output/post_memory_snapshot.bin", icdf_out_dir, model_name);
      end else begin
        vtrsp_odr_stream_filename = $sformatf("../%s/%s/vtrsp_odr_stream.yaml", icdf_out_dir, model_name);
        vtrsp_odr_memory_filename = $sformatf("../%s/%s/output/post_memory_snapshot.bin", icdf_out_dir, model_name);
      end
    end else begin
      vtrsp_odr_stream_filename = $sformatf("../../%s/%s/vtrsp_odr_stream.yaml", icdf_out_dir, model_name);
      vtrsp_odr_memory_filename = $sformatf("../../%s/%s/output/post_memory_snapshot.bin", icdf_out_dir, model_name);
    end

    foreach (odr_stream[i]) begin
      foreach (int8_arr[j]) int8_arr[j] = 0;
      `uvm_info(get_name(), $sformatf("ODR Stream[%0d]: 0x%128x", i, odr_stream[i]), UVM_LOW)
      for (int k=0; k < ODR_STREAM_LEN/8; k++) begin
        curr_byte = odr_stream[i][k*8 +: 8];
        if (curr_byte[7] == 1) begin
          int8_arr[k] = {{24{1'b1}}, curr_byte};
        end else begin
          int8_arr[k] = {{24{1'b0}}, curr_byte};
        end
        if (k == 0) begin
           s = {s, $sformatf("- [%0d, ", int8_arr[k])};
        end else if (k != ODR_STREAM_LEN/8 - 1) begin
          s = {s, $sformatf("%0d, ", int8_arr[k])};
        end else begin
          if (i != odr_stream.size()-1) begin
            s = {s, $sformatf("%0d]\n", int8_arr[k])};
          end else begin
            s = {s, $sformatf("%0d]", int8_arr[k])};
          end
        end
      end
      m_int8_q.push_back(int8_arr);
    end

    if (m_all_padded==1) begin
      `uvm_info(get_name(), "All padded data. Nothing to do.", UVM_LOW)
    end else begin
      `uvm_info(get_name(), $sformatf("ODR Stream in Int8 Format: \n%s", s), UVM_LOW);
      fd = $fopen(vtrsp_odr_stream_filename, "w");
      $fwrite(fd, s);
      $fclose(fd);
      run_set_stream_cmd();
      read_memory_file(vtrsp_odr_memory_filename);
    end
  endtask

  task run_set_stream_cmd();
    string bash_cmd;
    int loop_ptr, dim_ptr;

    if (regression==0 || sanity == 1) begin
      if (vsim==0) begin
        $sformat(bash_cmd, "./replace_mem_baseaddr.sh %s/%s/input/%s/command.yml", icdf_out_dir, model_name, get_device_name());
      end else begin
        $sformat(bash_cmd, "./replace_mem_baseaddr.sh ../%s/%s/input/%s/command.yml", icdf_out_dir, model_name, get_device_name());
      end
    end else begin
      $sformat(bash_cmd, "./replace_mem_baseaddr.sh ../../%s/%s/input/%s/command.yml", icdf_out_dir, model_name, get_device_name());
    end
    if (!$system(bash_cmd)) `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_LOW)
    else `uvm_fatal(get_name(), $sformatf("Running shell command: %s ,failed!", bash_cmd))

    // e.g. python3.8 -m testing.rtldebugger.filebased.cli -p ../icdf_out/ai_core_ls_ifd_odr_cmdb_vtrsp_test_m_d_odr_ref_mdl_1 -r set_stream -m d_odr --stream-file ../vtrsp_odr_stream.yaml --in-stream-port d_dpu
    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r set_stream -m %s --stream-file ../%s/%s/vtrsp_odr_stream.yaml --in-stream-port d_dpu", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name(), icdf_out_dir, model_name);
    if (!$system(bash_cmd)) `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_LOW)
    else `uvm_fatal(get_name(), $sformatf("Running shell command: %s ,failed!", bash_cmd))

    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r execute -m %s", bash_cmd, python_version, icdf_out_dir, model_name, get_device_name());
    if (!$system(bash_cmd)) `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_LOW)
    else `uvm_fatal(get_name(), $sformatf("Running shell command: %s ,failed!", bash_cmd))

    bash_cmd = go_to_icdf_dir();
    $sformat(bash_cmd, "%s && %s -m testing.rtldebugger.filebased.cli -p ../%s/%s -r get_memory", bash_cmd, python_version, icdf_out_dir, model_name);
    if (!$system(bash_cmd)) `uvm_info(get_name(), $sformatf("Running shell command: %s ,done!", bash_cmd), UVM_LOW)
    else `uvm_fatal(get_name(), $sformatf("Running shell command: %s ,failed!", bash_cmd))
  endtask

  task read_memory_file(string name);
    int counter, pword_counter;
    bit [7:0] line;
    bit [511:0] full_line;
    int file_handle, index;
    odr_stream_mem_t mem;
    mem_baseaddr_t mem_addr = mem_baseaddr;
    `uvm_info(get_name(), $sformatf("Reading memory file: %s", name), UVM_LOW)

    if (!$system($sformatf("test -e %s", name))) begin
      `uvm_info(get_name(), $sformatf("File exists: %s", name), UVM_LOW)
    end else begin
      `uvm_fatal(get_name(), $sformatf("File do not exist: %s", name))
    end

    file_handle = $fopen(name, "rb");
    if (file_handle) begin
      while($fgets(line,file_handle)) begin
        full_line[counter * 8 +: 8] = line;
        if (counter == AI_CORE_LS_PWORD_SIZE -1) begin
          if (full_line == ICDF_MEMORY_DEFAULT_VALUE) begin
            if (m_abs_mem_q.exists(mem_addr)) begin
              m_mem_q[mem_addr] = m_abs_mem_q[mem_addr]; // overwrite w/ previously written data
            end else begin
              m_mem_q[mem_addr] = 0; // overwrite w/ 0
            end
          end else begin
            m_mem_q[mem_addr] = full_line;
            m_abs_mem_q[mem_addr] = full_line;
          end
          `uvm_info(get_name(), $sformatf("[%s] Assigning Addr[%0d]: 0x%0x with Data: [%128h]", name, pword_counter, mem_addr, full_line), UVM_HIGH)
          mem.addr = mem_addr;
          mem.data = m_mem_q[mem_addr];
          if (vtrsp_out != null) begin
            vtrsp_out.write(mem); // write to analysis port
          end
          mem_addr += AI_CORE_LS_PWORD_SIZE;
          counter = 0;
          pword_counter+=1;
        end else begin
          counter += 1;
        end
      end
      $fclose(file_handle);
    end
    foreach (m_mem_q[i]) begin
      `uvm_info(get_name(), $sformatf("Post memory snapshot. Address: 0x%0x, Data: 0x%0x", i, m_mem_q[i]), UVM_LOW)
    end
  endtask

  function void clean_up_files();
    if (regression==0 || sanity == 1) begin
      if (vsim == 0) begin
        $system($sformatf("rm -rf %s/%s %s/%s.yaml", icdf_out_dir, model_name, icdf_out_dir, model_name));
      end else begin
        $system($sformatf("rm -rf ../%s/%s %s/%s.yaml", icdf_out_dir, model_name, icdf_out_dir, model_name));
      end
    end else begin
      $system($sformatf("rm -rf ../../%s/%s ../../%s/%s.yaml", icdf_out_dir, model_name, icdf_out_dir, model_name));
    end
  endfunction

  //model based on python model
  //https://git.axelera.ai/dev/rd/IntraCoreDataFlow/-/blob/master/core/functional/IFD_ODR_common.py#L117-277
  task do_mdl();
    run_cmd();
    read_addr_gen_output();
  endtask

  virtual task shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    if (regression==1 && sanity==0) begin
      clean_up_files();
    end
  endtask : shutdown_phase
endclass
`endif
