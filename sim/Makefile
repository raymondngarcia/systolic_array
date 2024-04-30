GIT_REPO := $(shell git rev-parse --show-toplevel)
include $(GIT_REPO)/sim/_pre.mk

########################################
##@ Simulation setup:
########################################

##% SIM_FLOW_CONFIG @@ ="simulation_config.mk" @@ Specify configuration options
SIM_FLOW_CONFIG ?= simulation_config.mk
-include $(SIM_FLOW_CONFIG)

########################################
##@ Validate the configuration:
########################################
$(call check_defined, BENDER_MANI_LOC, add to your configuration file)
$(call check_defined, IP_NAME, specify the name of the IP in SIM_FLOW_CONFIG)
$(call check_defined, TOP_LEVEL_MODULES, specify all top-level modules SIM_FLOW_CONFIG)

########################################
##@ Common Simulator variables (keep short to make commandline simple):
########################################

##% TIMESCALE @@ 1ns/1ps @@ Default timescale
TIMESCALE ?= 1ns/1ps

##% GLOBAL_DEFINES @@  @@ Additional defines applied to all compilations
override GLOBAL_DEFINES +=

##% PLUSARGS @@  @@ Additional +plusargs to simulation
override PLUSARGS +=

##% SV_LIBS @@  @@ Additional sv_libs to simulation (DPI code libraries)
SV_LIBS +=

##% UVM @@ {(0), 1 } @@ Automatically build for UVM
UVM       ?= 0
ifneq ("$(UVM)", "0")
override GLOBAL_DEFINES += +define+UVM_NO_DPI
override GLOBAL_DEFINES += +define+UVM_NO_DEPRECATED
endif

##% GUI @@ {(0), 1 } @@ Enable GUI
GUI       ?= 0

##% COVERAGE @@ {(0), 1 } @@ Enable coverage
COVERAGE ?= 0

##% DEBUG @@ {(0), 1 } @@ Enable debug (including waves)
ifeq ("$(GUI)", "0")
DEBUG     ?= 0
else
DEBUG     ?= 1
GRID_CMD  += --x11
endif

##% NODEPS @@ {(0), 1 } @@ No dependencies - rerun last compile
NODEPS    ?= 0

##% SIM_COMPILE_TIME_MINUTES @@ {(15), N} @@ Simulation compile time in minutes
SIM_COMPILE_TIME_MINUTES ?= 15

##% SIM_RUN_TIME_MINUTES @@ {(60(batch), 720(gui)), N} @@ Simulation run time in minutes
ifeq ("$(GUI)", "0")
SIM_RUN_TIME_MINUTES ?= 60
else
SIM_RUN_TIME_MINUTES ?= 720
endif

##% SIM_COVERAGE_TIME_MINUTES @@ {(60), N} @@ Coverage collection time in minutes
SIM_COVERAGE_TIME_MINUTES ?= 60

##% VRUN_PARALLEL_JOBS @@ Number of jobs to run in parallel
VRUN_PARALLEL_JOBS ?= 10

##% VRUN @@ vrun command
VRUN ?= vrun -j $(VRUN_PARALLEL_JOBS)


########################################
##@ Simulation run variables:
########################################

##% TESTNAME @@ $(IP_NAME) @@ Name of the test to run
TESTNAME ?= $(IP_NAME)

##% UVM_VERBOSITY @@ {UVM_LOW} @@ UVM verbosity level
UVM_VERBOSITY ?= UVM_LOW

##% SEED @@ $(RANDOM_SEED) @@ Seed for the simulation, if not specified a random seed is used
SEED ?= $(RANDOM_SEED)

##% REGRESSION @@  @@ Regression name, if not specified will run all
REGRESSION ?=

##% PRE_SIM_TARGETS @@  @@ User defined pre-simulation targets
PRE_SIM_TARGETS ?=

##% POST_SIM_TARGETS @@  @@ User defined post-simulation targets
POST_SIM_TARGETS ?=

########################################
## Bender setup:
########################################
$(call check_undefined, BENDER_TARGETS, Internal BENDER_TARGETS should not be externally defined)
BENDER_TARGETS += rtl
BENDER_TARGETS += simulation

########################################
## VCS specific
########################################
include $(GIT_REPO)/sim/vcs.mk

.PHONY: clean
clean:
	rm -rf build_*
	find $(MAKEFILE) -name \Bender.lock -type f -delete
