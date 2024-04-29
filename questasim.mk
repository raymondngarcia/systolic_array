########################################
##@ Questasim setup:
########################################

##% VSIM_FLOW_CONFIG @@ ="questasim_config.mk" @@ Specify configuration options
VSIM_FLOW_CONFIG ?= questasim_config.mk
-include $(VSIM_FLOW_CONFIG)

########################################
##@ Questasim build variables:
########################################

ifeq ("$(DEBUG)", "0")
    QUESTA_LICENSE_TYPE ?= questa_batch
else
    QUESTA_LICENSE_TYPE ?= questa_interactive
endif

##% VLOG @@ vlog @@ vlog command
VLOG        :=  $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COMPILE_TIME_MINUTES) --license $(QUESTA_LICENSE_TYPE),   $(GRID_CMD)) vlog

##% VOPT @@ vopt @@ vopt command
VOPT        := $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COMPILE_TIME_MINUTES) --license $(QUESTA_LICENSE_TYPE),    $(GRID_CMD)) vopt

##% VSIM_ELAB @@ vsim @@ vsim command for elaboration only
VSIM_ELAB   := $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COMPILE_TIME_MINUTES) --license $(QUESTA_LICENSE_TYPE),    $(GRID_CMD)) vsim

##% VSIM @@ vsim @@ vsim command
VSIM        := $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_RUN_TIME_MINUTES) --license $(QUESTA_LICENSE_TYPE),        $(GRID_CMD)) vsim

##% VCOVER @@ vcover @@ vcover command
VCOVER      := $(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COVERAGE_TIME_MINUTES) --license $(QUESTA_LICENSE_TYPE),   $(GRID_CMD)) vcover

##% VISUALIZER @@ visualizer @@ visualizer command
VISUALIZER ?= visualizer

##% VSIM_BUILD_DIR @@ build_vsim_<ip> @@ dedicated build direcotry for questasim
VSIM_BUILD_DIR ?= $(MAKEFILE_DIR)/build_vsim_$(IP_NAME)

$(call check_undefined, _VSIM_COMPILE_DIR, _VSIM_COMPILE_DIR should not be externally defined)
_VSIM_COMPILE_DIR = $(VSIM_BUILD_DIR)/compile_vsim

##% VSIM_COVERAGE_DIR @@ build_vsim_<ip>/coverage_vsim @@ dedicated coverage directory for questasim
VSIM_COVERAGE_DIR ?= $(VSIM_BUILD_DIR)/coverage_vsim

##% VSIM_VLOG_OPTS_EXT @@ ="<extra_options>" @@ Arguments passed to all VLOG statements
VSIM_VLOG_OPTS_EXT ?=
##% VSIM_VCOM_OPTS_EXT @@ ="<extra_options>" @@ Arguments passed to all VCOM statements
VSIM_VCOM_OPTS_EXT ?=
##% VSIM_VOPT_OPTS_EXT @@ ="<extra_options>" @@ Arguments passed to all VOPT statements
VSIM_VOPT_OPTS_EXT ?=
##% VSIM_ELAB_OPTS_EXT @@ ="<extra_options>" @@ Arguments passed to all VSIM -elab statements
VSIM_ELAB_OPTS_EXT ?=

VSIM_VLOG_OPTS ?=
VSIM_VCOM_OPTS ?=
VSIM_VOPT_OPTS ?=
VSIM_ELAB_OPTS ?=

# Common arguments for all questasim builds
# Specify the different Common compile options for configuring from the Makefile

$(call check_undefined, VSIM_VLOG_OPTS_COMMON VSIM_VCOM_OPTS_COMMON VSIM_VOPT_OPTS_COMMON VSIM_ELAB_OPTS_COMMON, Common build variable should not be externally defined)

# Global defines
VSIM_VLOG_OPTS_COMMON += $(GLOBAL_DEFINES)
VSIM_VCOM_OPTS_COMMON += $(GLOBAL_DEFINES)

# Supress copyright banner
VSIM_VLOG_OPTS_COMMON += -nologo
VSIM_VCOM_OPTS_COMMON += -nologo
VSIM_VOPT_OPTS_COMMON += -nologo

# Use full 64-bit mode
VSIM_VLOG_OPTS_COMMON += -64
VSIM_VCOM_OPTS_COMMON += -64
VSIM_VOPT_OPTS_COMMON += -64
VSIM_ELAB_OPTS_COMMON += -64

# We enforce strict language checks
VSIM_VLOG_OPTS_COMMON += -pedanticerrors
# Temporarily removed. This option is not compatible with vhdl 2008
# VSIM_VCOM_OPTS_COMMON += -pedanticerrors
VSIM_VOPT_OPTS_COMMON += -pedanticerrors
VSIM_ELAB_OPTS_COMMON += -pedanticerrors

# Set the timescale
VSIM_VLOG_OPTS_COMMON += -timescale=$(TIMESCALE)
VSIM_VOPT_OPTS_COMMON += -timescale=$(TIMESCALE)

# Set the systemverilog LRM version
VSIM_VLOG_OPTS_COMMON += -sv12compat
VSIM_VOPT_OPTS_COMMON += -sv12compat

# Select the default kind for an input port that is declared with a type
VSIM_VLOG_OPTS_COMMON += -svinputport=compat

# Have macros be visible over all files in a command line, questa per default puts each file into it's own compilation scope
VSIM_VLOG_OPTS_COMMON += -mfcu=macro

# Macro expansion to be LRM compliant
VSIM_VLOG_OPTS_COMMON += -macro=compat

# Allow unmarched virtual interfaces
# VSIM_ELAB_OPTS_COMMON += -permit_unmatched_virtual_intf

# Set the UVM version to 1.2, ($(QUESTASIM_HOME) is set by env module)
$(call check_defined, QUESTASIM_HOME, needs to be set in env)

# Add the VIP library, they also need a vendor macro
VSIM_VLOG_OPTS_COMMON += +define+SVT_VENDOR_LC=mti
VSIM_ELAB_OPTS_COMMON += -sv_lib /home/projects/dware/DESIGNWARE_HOME/vip/common/latest/C/lib/linux64/VipCommonNtb

# Do not check timing anotations
VSIM_VOPT_OPTS_COMMON += +notimingchecks

# Debug / waves
VSIM_VOPT_OPTS_DEBUG += -access=rw+/.
VSIM_VOPT_OPTS_DEBUG += -debug
VSIM_VOPT_OPTS_DEBUG += -debug,livesim
VSIM_ELAB_OPTS_DEBUG += -classdebug
VSIM_ELAB_OPTS_DEBUG += -qwavedb=+signal+memory+assertion+class
ifneq ("$(UVM)", "0")
VSIM_ELAB_OPTS_DEBUG += -msgmode both
VSIM_ELAB_OPTS_DEBUG += -uvmcontrol=all
VSIM_VLOG_OPTS_COMMON += -L $(QUESTASIM_HOME)/uvm-1.2
VSIM_VOPT_OPTS_COMMON += -L $(QUESTASIM_HOME)/uvm-1.2
endif


ifneq ("$(COVERAGE)", "0")
VSIM_VOPT_OPTS_COMMON += +cover=bcesft
VSIM_ELAB_OPTS_COMMON += -coverage
else
VSIM_ELAB_OPTS_COMMON += -nocvg
endif

########################################
##@ Questasim run variables:
########################################

##% VSIM_RUN_DIR @@ run_vsim_<UVM>_<seed> @@ dedicated run direcotry for questasim in the build directory
VSIM_RUN_DIR ?= $(VSIM_BUILD_DIR)/run_vsim_$(TESTNAME)_$(SEED)$(subst /,_,$(subst $(subst ,, ),_,$(PLUSARGS)))

##% VSIM_GUI_TOOL @@ {(visualizer), gui } @@ QUESTASIM debugging gui tool
VSIM_GUI_TOOL ?= visualizer

##% VSIM_RUN_OPTS_EXT @@ ="<extra_options>" @@ Arguments passed to all VSIM statements
VSIM_RUN_OPTS_EXT ?=
VSIM_RUN_OPTS     ?=

# Specify the different global compile options for configuring from the Makefile
$(call check_undefined, VSIM_RUN_OPTS_COMMON, Common run variable should not be externally defined)

# Gather the scripts which should be executed during a simulation run
$(call check_undefined, VSIM_RUN_DO_SCRIPTS, Common run variable should not be externally defined)

# Use full 64-bit mode
VSIM_RUN_OPTS_COMMON  += -64

$(call check_defined, TESTNAME, specify the testname)
$(call check_defined, UVM_VERBOSITY, specify the UVM verbosity)

VSIM_RUN_OPTS_COMMON += +UVM_VERBOSITY=$(UVM_VERBOSITY)

# Determine if the gui should be used

ifeq ("$(GUI)", "0")
VSIM_RUN_OPTS_COMMON += -c
else
VSIM_RUN_OPTS_COMMON += $(addprefix +designfile=$(_VSIM_COMPILE_DIR)/,$(addsuffix _vopt_debug.bin,$(TOP_LEVEL_MODULES)))
VSIM_RUN_OPTS_COMMON += -$(VSIM_GUI_TOOL)
endif

ifneq ("$(COVERAGE)", "0")
VSIM_RUN_OPTS_COMMON += -coverstore $(VSIM_COVERAGE_DIR) -testname $(TESTNAME)$(subst $(subst ,, ),_,$(PLUSARGS))
endif

# Generate a run exit script
VSIM_RUN_DO_SCRIPTS  += $(_VSIM_COMPILE_DIR)/run_all_exit.do

########################################
##@ Questasim compile targets:
########################################

# Variables for storing the prerequisites for each questasim stage
COMPILE_VSIM_PREREQUISITES ?= $(_VSIM_COMPILE_DIR)

.PHONY: $(_VSIM_COMPILE_DIR) $(VSIM_RUN_DIR)
$(_VSIM_COMPILE_DIR) $(VSIM_RUN_DIR): ## Create the questasim build directory
	@# Create the build directory
	mkdir -p $@


.PHONY: $(_VSIM_COMPILE_DIR)/dump.do
$(_VSIM_COMPILE_DIR)/dump.do: dump.tcl $(_VSIM_COMPILE_DIR) ## Generate the dump do script in the build directory
	@# Compy the dump script
	cp -rf $< $@

.PHONY:    $(_VSIM_COMPILE_DIR)/run_all_exit.do
$(_VSIM_COMPILE_DIR)/run_all_exit.do: $(_VSIM_COMPILE_DIR) ## Generate a run all exit do script in the build directory
	@# Generate a run all exit do script in the build directory
	echo "# Generated by <make $@>" > $@
	echo "assertion action -cond global_fail_limit 1 -exec break" >> $@
	echo "onerror {break}" >> $@
	echo "# Run the simulation only in batch mode:" >> $@
	echo "if {[batch_mode]} {" >> $@
	echo "  onbreak {exit -f -code 1}" >> $@
	echo "  run -all" >> $@
	echo "  exit" >> $@
	echo "}" >> $@

.PHONY:    $(_VSIM_COMPILE_DIR)/$(IP_NAME).vsim.analyze.sh
$(_VSIM_COMPILE_DIR)/$(IP_NAME).vsim.analyze.sh: bender_update $(FLOW_PREREQUISITES) $(_VSIM_COMPILE_DIR) ## Generate the analyze script
	@# Generate the analyze script
	$(BENDER) -d $(BENDER_MANI_LOC) \
		$(BENDER_ARGS_EXT) \
		script template \
		--template=$(GIT_REPO)/hw/scripts/bender_templates/vsim_sh.tera \
		--target=vsim \
		$(addprefix --target=,$(BENDER_TARGETS)) \
		$(addprefix --target=,$(BENDER_TARGETS_EXT)) \
		--vlog-arg="$(VSIM_VLOG_OPTS_COMMON) $(VSIM_VLOG_OPTS) $(VSIM_VLOG_OPTS_EXT)" \
		--vcom-arg="$(VSIM_VCOM_OPTS_COMMON) $(VSIM_VCOM_OPTS) $(VSIM_VCOM_OPTS_EXT)" \
		$(EXT_BENDER_SUBCMD_ARGS) \
		> $@
	echo "Bender done"
	chmod +x $@

# The grep is to extract the top-level package name directly from the top-level Bender.yml
# TODO(wroennin): Think about a TECH_CORNER setup
.PHONY: analyze_vsim
analyze_vsim: $(_VSIM_COMPILE_DIR)/$(IP_NAME).vsim.analyze.sh $(COMPILE_VSIM_PREREQUISITES) ## Run the QUESTASIM analysis step
	@# Run the vsim analyze step
	cd $(_VSIM_COMPILE_DIR)
	$(subst time=$(GRID_TIME_MINUTES),time=$(SIM_COMPILE_TIME_MINUTES) --license $(QUESTA_LICENSE_TYPE),     $(GRID_CMD)) $< |& tee $(_VSIM_COMPILE_DIR)/$(IP_NAME).$@.log

.PHONY: %_vopt
%_vopt: analyze_vsim ## Run the QUESTASIM vopt step for a top-level module
	@# Run the $@ step for: $(patsubst %_vopt,%,$@)
	cd $(_VSIM_COMPILE_DIR)
	$(VOPT) \
		$(VSIM_VOPT_OPTS_COMMON) \
		$(VSIM_VOPT_OPTS) \
		$(VSIM_VOPT_OPTS_EXT) \
		-l $(_VSIM_COMPILE_DIR)/$(patsubst %_vopt,%,$@).vopt.log \
		$(patsubst %_vopt,%,$@) \
		-o $@

.PHONY: %_vopt_debug
%_vopt_debug: %_vopt ## Run the QUESTASIM vopt step for a top-level module
	@# Run the $@ step for: $(patsubst %_vopt,%,$@)
	cd $(_VSIM_COMPILE_DIR)
	$(VOPT) \
		$(VSIM_VOPT_OPTS_COMMON) \
		$(VSIM_VOPT_OPTS_DEBUG) \
		$(VSIM_VOPT_OPTS) \
		$(VSIM_VOPT_OPTS_EXT) \
		-l $(_VSIM_COMPILE_DIR)/$(patsubst %_vopt_debug,%,$@).vopt_debug.log \
		$(patsubst %_vopt_debug,%,$@) \
		-designfile $@.bin \
		-o $@

.PHONY: compile_vsim_dpi

.PHONY: %_vsim_elab
%_vsim_elab: compile_vsim_dpi $(addsuffix _vopt,$(TOP_LEVEL_MODULES)) ## Elaborate a simulation for a top-level module
	@# Run the $@ step for: $(patsubst %_vopt,%,$@)
	cd $(_VSIM_COMPILE_DIR)
	$(VSIM_ELAB) \
		$(VSIM_ELAB_OPTS_COMMON) \
		$(VSIM_ELAB_OPTS) \
		$(VSIM_ELAB_OPTS_EXT) \
		-elab $(IP_NAME)_vsim_elab \
		-l $@.log \
		$(filter %_vopt,$^)

.PHONY: %_vsim_elab_debug
%_vsim_elab_debug: compile_vsim_dpi $(addsuffix _vopt_debug,$(TOP_LEVEL_MODULES)) ## Elaborate a simulation for a top-level module (debug)
	@# Run the $@ step for: $(patsubst %_vopt,%,$@)
	cd $(_VSIM_COMPILE_DIR)
	$(VSIM_ELAB) -c \
		$(VSIM_ELAB_OPTS_COMMON) \
		$(VSIM_ELAB_OPTS_DEBUG) \
		$(VSIM_ELAB_OPTS) \
		$(VSIM_ELAB_OPTS_EXT) \
		-elab $(IP_NAME)_vsim_elab_debug \
		-l $@.log \
		$(filter %_vopt_debug,$^)

.PHONY: compile_vsim
compile_vsim: compile_vsim_dpi .WAIT $(addsuffix _vsim_elab,$(TOP_LEVEL_MODULES)) $(addsuffix _vsim_elab_debug,$(TOP_LEVEL_MODULES)) ## Compile a simulation for a top-level module

########################################
##@ Questasim run targets:
########################################

# Variables for storing the prerequisites for each questasim stage
$(call check_undefined, RUN_VSIM_PREREQUISITES, RUN_VSIM_PREREQUISITES should not be externally defined)

ifeq ("$(NODEPS)", "0")
RUN_VSIM_PREREQUISITES += compile_vsim
endif
RUN_VSIM_PREREQUISITES += $(VSIM_RUN_DIR) $(VSIM_RUN_DO_SCRIPTS) $(PRE_SIM_TARGETS)

# Variables for storing the postrequisites for each questasim stage
$(call check_undefined, RUN_VSIM_POSTREQUISITES, RUN_VSIM_POSTREQUISITES should not be externally defined)
RUN_VSIM_POSTREQUISITES += $(POST_SIM_TARGETS)

ifeq ("$(DEBUG)", "0")
RUN_VSIM_ELAB = $(_VSIM_COMPILE_DIR)/$(IP_NAME)_vsim_elab
else
RUN_VSIM_ELAB = $(_VSIM_COMPILE_DIR)/$(IP_NAME)_vsim_elab_debug
endif

.PHONY: _run_vsim_
_run_vsim_:
	@# Run in single shell
	# Clear status
	rm -f $(VSIM_RUN_DIR)/PASSED $(VSIM_RUN_DIR)/FAILED
	# Mark as failed - in case of error
	touch $(VSIM_RUN_DIR)/FAILED
	# Make the do file
	rm -rf $(VSIM_RUN_DIR)/run.do
	echo "# Generated by make " > $(VSIM_RUN_DIR)/run.do
	echo "# Run different sub-scripts for the simulation" >> $(VSIM_RUN_DIR)/run.do
	for script in $(VSIM_RUN_DO_SCRIPTS); do \
		echo "do $$script" >> $(VSIM_RUN_DIR)/run.do; \
	done
	# Run the simulation
	cd $(VSIM_RUN_DIR)
	sim_sts=0
	$(VSIM) \
		$(VSIM_RUN_OPTS_COMMON) \
		$(VSIM_RUN_OPTS) \
		$(VSIM_RUN_OPTS_EXT) \
		-load_elab $(RUN_VSIM_ELAB) \
		+UVM_TESTNAME=$(TESTNAME) \
		$(PLUSARGS) \
		$(SV_LIBS) \
		-sv_seed $(SEED) \
		-l sim.log \
		-do run.do || sim_sts=$$?
	# Check the log for errors
	chk_sts=0
	grep -e '^# \*\* Error:' -e '^# \*\* Fatal:' sim.log &> /dev/null || chk_sts=$$?
	if [ $$sim_sts -eq 0 ] && [ $$chk_sts -ne 0 ]; then \
		mv FAILED PASSED; \
	fi

.PHONY: run_vsim
run_vsim: $(RUN_VSIM_PREREQUISITES) .WAIT _run_vsim_ .WAIT $(RUN_VSIM_POSTREQUISITES) ## Run all tests with vsim
	@# Check for PASSED / FAILED and set correct exit status
	if [ -f $(VSIM_RUN_DIR)/PASSED ]; then \
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
##@ Questasim regression targets:
########################################

ifneq ("$(GUI)", "0")
VRUN += -gui
endif

##% VSIM_RMDB @@  @@ The regression database
VSIM_RMDB ?= $(GIT_REPO)/hw/scripts/vrm/axelera.rmdb

##% VSIM_RMDB @@  @@ The run directory for a regression
VSIM_REG_RUN_DIR ?= $(VSIM_BUILD_DIR)/regression_vsim/$(VSIM_REGRESSION)

.PHONY:    regress_vsim
regress_vsim:
	@# Run a regression
	mkdir -p $(VSIM_REG_RUN_DIR)
	cd $(VSIM_REG_RUN_DIR)
	rm -rf $(notdir $(VSIM_RMDB)) $(notdir $(VSIM_REGRESSION)).list
	ln -s $(VSIM_RMDB) .
	ln -s $(MAKEFILE_DIR)/$(VSIM_REGRESSION).list .
	$(VRUN) regression \
		-exitcodes \
		-rmdb $(notdir $(VSIM_RMDB)) \
		-GMAKEFILE_DIR=$(MAKEFILE_DIR) \
		-GCOVERAGE=$(COVERAGE) \
		-GCOMPILE_TARGET=compile_vsim \
		-GRUN_TARGET=run_vsim \
		-GCOVERAGE_TARGET=report_vsim_coverage \
		-GREGRESSION_LIST=$(notdir $(VSIM_REGRESSION))

########################################
##@ Questasim coverage targets:
########################################
$(VSIM_COVERAGE_DIR)/coverage.ucdb: $(wildcard $(VSIM_COVERAGE_DIR)/*.data) ## Generate a merged coverage ucdb
	@# Merge all coverage data
	echo Merging Coverage
	$(VCOVER) merge -out $@ $(VSIM_COVERAGE_DIR)
	sleep 2 # Needed to avoid race condition

.PHONY: report_vsim_coverage
report_vsim_coverage: $(VSIM_COVERAGE_DIR)/coverage.ucdb ## Generate coverage html report
	@# Generate coverage report
	echo Generating Coverage Report
	$(VCOVER) report -html -annotate -details -output $(VSIM_COVERAGE_DIR)/html $(VSIM_COVERAGE_DIR)/coverage.ucdb

.PHONY: view_vsim_coverage
view_vsim_coverage: $(VSIM_COVERAGE_DIR)/coverage.ucdb ## Launch the coverage gui
	@# Coverage Gui
	echo Viewing Coverage
	$(VISUALIZER) -viewcov $(VSIM_COVERAGE_DIR)/coverage.ucdb


########################################
##@ Questasim clean targets:
########################################

CLEAN_PREREQUISITES += clean_vsim_runs
.PHONY: clean_vsim_runs
clean_vsim_runs: ## Remove the run directories inside the build directory
	rm -rf $(VSIM_BUILD_DIR)/run_*

CLEAN_PREREQUISITES += clean_vsim
.PHONY: clean_vsim
clean_vsim: clean_reg ## Clean the WHOLE questasim build directory
	rm -rf $(VSIM_BUILD_DIR)
