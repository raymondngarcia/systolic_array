########################################
##@ VCS setup:
########################################

# UVM configuration
VCS_VLOGAN_OPTS += +incdir+${VCS_HOME}/etc/uvm-1.2
VCS_ELAB_OPTS   += -ntb_opts uvm-1.2
VCS_VLOGAN_OPTS += -ntb_opts uvm-1.2

# Specify the debug access:
VCS_VLOGAN_OPTS += +define+SVT_UVM_TECHNOLOGY

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

########################################
##@ VCS build variables:
########################################
ifeq ("$(DEBUG)", "0")
    VCS_LICENSE_TYPE = vcs_batch
else
    VCS_LICENSE_TYPE = vcs_interactive
endif

VLOGAN := $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COMPILE_TIME_MINUTES)  --license $(VCS_LICENSE_TYPE),  $(GRID_CMD)) vlogan

VCS    := $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COMPILE_TIME_MINUTES)  --license $(VCS_LICENSE_TYPE),  $(GRID_CMD)) vcs

URG    := $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COVERAGE_TIME_MINUTES) --license $(VCS_LICENSE_TYPE),  $(GRID_CMD)) urg

VERDI ?= verdi

##% VCS_GUI_TYPE @@ verdi @@ VCS gui to use
VCS_GUI_TYPE ?= verdi

##% VCS_DUMP_TYPE @@ fsdb @@ Dump database datatype
VCS_DUMP_TYPE ?= fsdb

##% VCS_BUILD_DIR @@ build_vcs_<ip> @@ dedicated build direcotry for vcs
VCS_BUILD_DIR ?= $(MAKEFILE_DIR)/build_vcs_$(IP_NAME)

$(call check_undefined, _VCS_COMPILE_DIR, _VCS_COMPILE_DIR should not be externally defined)
_VCS_COMPILE_DIR = $(VCS_BUILD_DIR)/compile_vcs

##% VCS_RUN_DIR @@ build_vcs_<ip>/run_<> @@ dedicated run directory for VCS
VCS_RUN_DIR = $(VCS_BUILD_DIR)/run_vcs_$(TESTNAME)_$(SEED)$(subst /,_,$(subst $(subst ,, ),_,$(PLUSARGS)))

##% VCS_COVERAGE_DIR @@ build_vcs_<ip> @@ dedicated coverage directory for VCS
VCS_COVERAGE_DIR ?= $(VCS_BUILD_DIR)/coverage_vcs

##% VCS_VLOGAN_OPTS_EXT @@ ="<extra_options>" @@ Arguments passed to all VLOG statements
VCS_VLOGAN_OPTS_EXT ?=
VCS_ELAB_OPTS_EXT ?=

VCS_VLOGAN_OPTS ?=
VCS_ELAB_OPTS_EXT ?=

# Common arguments for all vcs builds
# Specify the different Common compile options for configuring from the Makefile

$(call check_undefined, VCS_VLOGAN_OPTS_COMMON, Common build variable should not be externally defined)

# Global defines
VCS_VLOGAN_OPTS_COMMON += $(GLOBAL_DEFINES)

# Supress copyright banner
VCS_VLOGAN_OPTS_COMMON += -nc

# Use full 64-bit mode
VCS_VLOGAN_OPTS_COMMON += -full64
VCS_ELAB_OPTS_COMMON   += -full64

# Set the timescale
VCS_VLOGAN_OPTS_COMMON += -timescale=$(TIMESCALE)

# Enable Verdi debug by default
VCS_VLOGAN_OPTS_COMMON += -kdb
VCS_ELAB_OPTS_COMMON   += -kdb

# Linting
VCS_VLOGAN_OPTS_COMMON += +lint=TFIPC-L
VCS_ELAB_OPTS_COMMON   += +lint=TFIPC-L

# Incremental analysis
VCS_VLOGAN_OPTS_COMMON += -incr_vlogan

# Enable sva assertions
VCS_VLOGAN_OPTS_COMMON += -assert svaext # Incremental analysis

# Verilog 2k
VCS_VLOGAN_OPTS_COMMON += +v2k

# Debug / waves
VCS_ELAB_OPTS_DEBUG += -debug_access+all +vcs+fsdbon

# Licence
VCS_ELAB_OPTS += +vcs+lic+wait
VCS_RUN_OPTS  += -licqueue

# Stop on assertion
VCS_ELAB_OPTS_EXT += -assert enable_hier
VCS_RUN_OPTS      += -assert global_finish_maxfail=1 -assert errmsg

# Coverage
ifneq ("$(COVERAGE)", "0")
VCS_ELAB_OPTS_COMMON += -cm line+cond+tgl+fsm+branch+assert -cm_report svpackages -cm_dir  $(VCS_COVERAGE_DIR)/simv.vdb
VCS_RUN_OPTS         += -cm line+cond+tgl+fsm+branch+assert -cm_report svpackages -cm_dir  $(VCS_COVERAGE_DIR)/simv.vdb -cm_name $(TESTNAME).$(SEED)
endif

ifneq ("$(UVM)", "0")
VCS_VLOGAN_OPTS_COMMON += -ntb_opts uvm-1.2
endif

# UVM Runtime Options
VCS_RUN_OPTS += +UVM_VERBOSITY=$(UVM_VERBOSITY)

########################################
##@ vcs compile targets:
########################################

# Variables for storing the prerequisites for each vcs stage
COMPILE_VCS_PREREQUISITES ?= $(_VCS_COMPILE_DIR)
ifneq ("$(UVM)", "0")
COMPILE_VCS_PREREQUISITES += analyze_vcs_uvm
endif

.PHONY: $(_VCS_COMPILE_DIR) $(VCS_RUN_DIR)
$(_VCS_COMPILE_DIR) $(VCS_RUN_DIR): ## Create the vcs build directory
	@mkdir -p $@

.PHONY: $(_VCS_COMPILE_DIR)/$(IP_NAME).vcs.compile.sh
$(_VCS_COMPILE_DIR)/$(IP_NAME).vcs.compile.sh: bender_update $(FLOW_PREREQUISITES) $(_VCS_COMPILE_DIR) ## Generate the compile script for vcs
	@# Generate the compile script
	$(BENDER) -d $(BENDER_MANI_LOC) \
		$(BENDER_ARGS_EXT) \
		script vcs \
		$(addprefix --target=,$(BENDER_TARGETS)) \
		$(addprefix --target=,$(BENDER_TARGETS_EXT)) \
		--vlog-arg="$(VCS_VLOGAN_OPTS_COMMON) $(VCS_VLOGAN_OPTS) $(VCS_VLOGAN_OPTS_EXT)" \
		$(EXT_BENDER_SUBCMD_ARGS) \
		> $@
	chmod +x $@

# The grep is to extract the top-level package name directly from the top-level Bender.yml
.PHONY: analyze_vcs_uvm
analyze_vcs_uvm: $(_VCS_COMPILE_DIR)
	@# Compile in UVM
	cd $(_VCS_COMPILE_DIR)
	$(VLOGAN) $(VCS_VLOGAN_OPTS_COMMON) $(VCS_VLOGAN_OPTS) $(VCS_VLOGAN_OPTS_EXT)

.PHONY: analyze_vcs
analyze_vcs: $(_VCS_COMPILE_DIR)/$(IP_NAME).vcs.compile.sh $(COMPILE_VCS_PREREQUISITES) ## Run the VCS analysis step
	@# Compile
	cd $(_VCS_COMPILE_DIR)
	TECH_CORNER=$(TECH_CORNER)
	$(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COMPILE_TIME_MINUTES) --license $(VCS_LICENSE_TYPE),  $(GRID_CMD)) $< \
	|& tee $(_VCS_COMPILE_DIR)/$(IP_NAME).$@.log


.PHONY: compile_vcs_dpi

.PHONY: %_vcs_elab
%_vcs_elab: analyze_vcs ## Run the VCS elaboration step for a top-level module
	@cd $(_VCS_COMPILE_DIR) && \
	$(VCS) \
		$(VCS_ELAB_OPTS_COMMON) \
		$(VCS_ELAB_OPTS) \
		$(VCS_ELAB_OPTS_EXT) \
		-l $(_VCS_COMPILE_DIR)/$(patsubst %_vcs_elab,%,$@).elab.log \
		$(patsubst %_vcs_elab,%,$@) \
		-o $(IP_NAME)_elab

.PHONY: %_vcs_elab_debug
%_vcs_elab_debug: %_vcs_elab  ## Run the VCS elaboration step for a top-level module (debug)
	@cd $(_VCS_COMPILE_DIR) && \
	$(VCS) \
		$(VCS_ELAB_OPTS_COMMON) \
		$(VCS_ELAB_OPTS) \
		$(VCS_ELAB_OPTS_EXT) \
		$(VCS_ELAB_OPTS_DEBUG) \
		-l $(_VCS_COMPILE_DIR)/$(patsubst %_vcs_elab_debug,%,$@).elab_debug.log \
		$(patsubst %_vcs_elab_debug,%,$@) \
		-o $(IP_NAME)_elab_debug

.PHONY: compile_vcs
compile_vcs: compile_vcs_dpi .WAIT $(addsuffix _vcs_elab,$(TOP_LEVEL_MODULES)) $(addsuffix _vcs_elab_debug,$(TOP_LEVEL_MODULES)) ## Compile a simulation for a top-level module

########################################
##@ VCS run targets:
########################################

# Variables for storing the prerequisites for each VCS stage
$(call check_undefined, RUN_VCS_PREREQUISITES, RUN_VCS_PREREQUISITES should not be externally defined)

ifeq ("$(NODEPS)", "0")
RUN_VCS_PREREQUISITES += compile_vcs
endif
RUN_VCS_PREREQUISITES += $(VCS_RUN_DIR) $(PRE_SIM_TARGETS)

# Variables for storing the postrequisites for each VCS stage
$(call check_undefined, RUN_VCS_POSTREQUISITES, RUN_VCS_POSTREQUISITES should not be externally defined)

RUN_VCS_POSTREQUISITES += $(POST_SIM_TARGETS)

ifeq ("$(DEBUG)", "0")
RUN_VCS_ELAB = $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_RUN_TIME_MINUTES) --license $(VCS_LICENSE_TYPE),      $(GRID_CMD)) $(_VCS_COMPILE_DIR)/$(IP_NAME)_elab
else
RUN_VCS_ELAB = $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_RUN_TIME_MINUTES) --license $(VCS_LICENSE_TYPE),      $(GRID_CMD)) $(_VCS_COMPILE_DIR)/$(IP_NAME)_elab_debug
endif

ifneq ("$(GUI)", "0")
RUN_VCS_ELAB += -gui=$(VCS_GUI_TYPE)
endif

VCS_RUN_OPTS_TCL ?=

.PHONY: _run_vcs_
_run_vcs_:
	@# Run in single shell
	# Clear Status
	rm -f $(VCS_RUN_DIR)/PASSED $(VCS_RUN_DIR)/FAILED
	mkdir -p $(VCS_RUN_DIR)
	# Mark as failed - in case of error
	touch $(VCS_RUN_DIR)/FAILED
	# Run the simulation
	cd $(VCS_RUN_DIR)
	sim_sts=0
	$(RUN_VCS_ELAB) \
		$(VCS_RUN_OPTS_COMMON) \
		$(VCS_RUN_OPTS) \
		$(VCS_RUN_OPTS_EXT) \
		$(VCS_RUN_OPTS_TCL) \
		+UVM_TESTNAME=$(TESTNAME) \
		$(PLUSARGS) \
		$(SV_LIBS) \
		+ntb_random_seed=$(SEED) \
		-l sim.log || sim_sts=$$?
	# Check the log for errors
	chk_sts=0
	grep -e '^Error:' -e '^Fatal:' -e 'UVM_FATAL :    1' -e 'SvtTestEpilog: Failed' sim.log &> /dev/null || chk_sts=$$?
	if [ $$sim_sts -eq 0 ] && [ $$chk_sts -ne 0 ]; then \
		mv FAILED PASSED; \
	fi

.PHONY:    run_vcs
run_vcs: $(RUN_VCS_PREREQUISITES) .WAIT _run_vcs_ ## Run all tests with vcs
	@# Check for PASSED / FAILED and set correct exit status
	if [ -f $(VCS_RUN_DIR)/PASSED ]; then \
		echo " _____         _____ _____ ______ _____  "; \
		echo "|  __ \ /\    / ____/ ____|  ____|  __ \ "; \
		echo "| |__) /  \  | (___| (___ | |__  | |  | |"; \
		echo "|  ___/ /\ \  \___ \\\___ \|  __| | |  | |"; \
		echo "| |  / ____ \ ____) |___) | |____| |__| |"; \
		echo "|_| /_/    \_\_____/_____/|______|_____/ "; \
	else \
		echo " ______      _____ _      ______ _____  "; \
		echo "|  ____/\   |_   _| |    |  ____|  __ \ "; \
		echo "| |__ /  \    | | | |    | |__  | |  | |"; \
		echo "|  __/ /\ \   | | | |    |  __| | |  | |"; \
		echo "| | / ____ \ _| |_| |____| |____| |__| |"; \
		echo "|_|/_/    \_\_____|______|______|_____/ "; \
		false; \ #Exit status
	fi

########################################
##@ VCS regression targets:
########################################

ifneq ("$(GUI)", "0")
VRUN += -gui
endif

##% VCS_RMDB @@  @@ The regression database
VCS_RMDB ?= $(GIT_REPO)/hw/scripts/vrm/axelera.rmdb

##% VCS_RMDB @@  @@ The run directory for a regression
VCS_REG_RUN_DIR ?= $(VCS_BUILD_DIR)/regression_vcs/$(VCS_REGRESSION)

.PHONY:    regress_vcs
regress_vcs: ## Run a vcs regression
	@# Run a regression
	mkdir -p $(VCS_REG_RUN_DIR)
	cd $(VCS_REG_RUN_DIR)
	rm -rf $(notdir $(VCS_RMDB)) $(notdir $(VCS_REGRESSION)).list
	ln -s $(VCS_RMDB) .
	ln -s $(MAKEFILE_DIR)/$(VCS_REGRESSION).list .
	$(VRUN) regression \
		-exitcodes \
		-rmdb $(notdir $(VCS_RMDB)) \
		-GMAKEFILE_DIR=$(MAKEFILE_DIR) \
		-GCOVERAGE=$(COVERAGE) \
		-GCOMPILE_TARGET=compile_vcs \
		-GRUN_TARGET=run_vcs \
		-GCOVERAGE_TARGET=report_vcs_coverage \
		-GREGRESSION_LIST=$(notdir $(VCS_REGRESSION))

########################################
##@ VCS coverage targets:
########################################

.PHONY: report_vcs_coverage
report_vcs_coverage: ## Generate coverage html report
	@# Generate coverage report
	echo Generating Coverage Report
	$(URG) -dir $(VCS_COVERAGE_DIR)/simv.vdb -report $(VCS_COVERAGE_DIR)/html

.PHONY: view_vcs_coverage
view_vcs_coverage: ## Launch the coverage gui
	@# Coverage Gui
	echo Viewing Coverage
	-$(VERDI) -cov -covdir $(VCS_COVERAGE_DIR)/simv.vdb

########################################
##@ VCS clean targets:
########################################

CLEAN_PREREQUISITES += clean_vcs_runs
.PHONY: clean_vcs_runs
clean_vcs_runs: ## Remove the run directories inside the build directory
	rm -rf $(VCS_BUILD_DIR)/run_*

CLEAN_PREREQUISITES += clean_vcs
.PHONY: clean_vcs
clean_vcs: ## Clean the WHOLE vcs build directory
	rm -rf $(VCS_BUILD_DIR) $(VSIM_BUILD_DIR)/../../gen_rtl
