#!/usr/bin/env bash
# This script was generated automatically by bender.
ROOT="./uvm"

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+./rtl" \
    "./rtl/sa_pkg.sv" \
    "./rtl/sa_if.sv" \
    "./rtl/sa.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2/src" \
    "+incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2/vcs" \
    "+incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2/verdi" \
    "/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2/uvm_pkg.sv" \
    "/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2/vcs/uvm_custom_install_vcs_recorder.sv" \
    "/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2/verdi/uvm_custom_install_verdi_recorder.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+$ROOT/agents/sa_agent" \
    "$ROOT/agents/sa_agent/sa_agent_pkg.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+$ROOT/refmodels/sa_refmodel" \
    "$ROOT/refmodels/sa_refmodel/sa_refmodel_pkg.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+$ROOT/scoreboards/sa_sb" \
    "$ROOT/scoreboards/sa_sb/sa_sb_pkg.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+$ROOT/env" \
    "$ROOT/env/sa_env_pkg.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+$ROOT/sequences" \
    "$ROOT/sequences/sa_seq_pkg.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+$ROOT/tests" \
    "$ROOT/tests/sa_test_pkg.sv" 

vlogan -sverilog \
    -full64 \
    -nc -full64 -timescale=1ns/1ps -kdb +lint=TFIPC-L -incr_vlogan -assert svaext  +v2k +incdir+/opt/synopsys/vcs/U-2023.03-SP2-1/etc/uvm-1.2 -ntb_opts uvm-1.2 +define+SVT_UVM_TECHNOLOGY  \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VCS \
    "+incdir+$ROOT/." \
    "$ROOT/../rtl/hdl_top.sv" 
