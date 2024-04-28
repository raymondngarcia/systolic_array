# UVM configuration
VCS_VLOGAN_OPTS += +incdir+${VCS_HOME}/etc/uvm-1.2
#VCS_VLOGAN_OPTS += +define+UVM_NO_DPI

VCS_ELAB_OPTS   += -ntb_opts uvm-1.2
VCS_VLOGAN_OPTS += -ntb_opts uvm-1.2

# Specify the debug access:
VCS_VLOGAN_OPTS += +define+SVT_UVM_TECHNOLOGY

#############################################
# Add VCS Run and Elab options for cva6v
#############################################

ifeq (${RUN_UNR}, 0)
  TOP_LEVEL_MODULES  = hdl_top
  VCS_ELAB_OPTS     += -top hdl_top
endif #RUN_UNR

NO_DUT           ?= 0

ifeq ($(REGRESSION), 1)
  VCS_RUN_OPTS += +REGRESSION=1
endif

# SIM RUN
VCS_RUN_OPTS         += -reportstats

ifeq ("$(VCS_DUMP_TYPE)", "vpd")
ifeq ("$(VCS_GUI_TYPE)", "dve")
VCS_ELAB_OPTS += -debug_access+all
VCS_RUN_OPTS_TCL = -ucli -do ../../dump_vpd.tcl
endif
endif
