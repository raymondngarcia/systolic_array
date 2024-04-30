########################################
## This file provides common setup
########################################

.DEFAULT_GOAL := help

# Tell make to use bash instead of sh and make use of oneshell
SHELL := /usr/bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined: $1$(if $2, ($2))))

# Check that given variables are not set
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_undefined = \
    $(strip $(foreach 1,$1, \
        $(call __check_undefined,$1,$(strip $(value 2)))))
__check_undefined = \
    $(if $(value $1), \
      $(error Already defined: $1$(if $2, ($2))), \
      $(eval $1 := ))

########################################
##@ Global Variables:
########################################

##% GIT_REPO @@ @@ This always points to the root of the repository
$(call check_defined, GIT_REPO, add 'GIT_REPO := $(shell git rev-parse --show-toplevel)' before including _pre.mk)

##% MAKEFILE_DIR @@ @@ This points to the location the makefile link is located
MAKEFILE_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))

##% RANDOM_SEED @@ /dev/urandom @@ This always gives a different random number
RANDOM_SEED := $(strip $(shell od -vAn -N4 -tu4 < /dev/urandom))

# Get the current timestamp
TIMESTAMP := $(shell date +"%Y%m%d_%H%M%S")

##% FLOW_PREREQUISITES @@ @@ These targets are called every time when executing something
$(call check_undefined, FLOW_PREREQUISITES, This variable is reserved for global prerequisites)

########################################
##@ Global computing grid setup (SLURM):
########################################

##% GRID_ENABLE @@ { 0 ,(1)} @@ Run heavy jobs on the computing grid
GRID_ENABLE ?= 1

##% GRID_CPUS @@ {1} @@ The amount of cpu cores to allocate
GRID_NUM_CPUS ?= 1

##% GRID_TIME_MINUTES @@ {1440} @@ The number of minutes until timeout
GRID_TIME_MINUTES ?= 1440

##% GRID_OPTS_EXT @@ ="<extra_options>" @@ Arguments passed to compute grid commands
GRID_OPTS_EXT ?=
$(call check_undefined, GRID_OPTS, do not add to this variable)

$(call check_undefined, GRID_CMD, do not add to this variable)
GRID_CMD ?=

GRID_OPTS  = --verbose
GRID_OPTS += --job-name=$@
GRID_OPTS += --cpus-per-task=$(GRID_NUM_CPUS)
GRID_OPTS += --time=$(GRID_TIME_MINUTES)

ifeq ("$(GRID_ENABLE)", "1")
GRID_CMD  = srun $(GRID_OPTS) $(GRID_OPTS_EXT)
endif

########################################
##@ Bender Variables:
########################################
BENDER ?= bender

##% BENDER_MANI_LOC @@ @@ Point to the direcotry where bender hooks in, set in config
# Add this in any makefile that uses bender !!!
# $(call check_defined, BENDER_MANI_LOC, add to your configuration file)

##% BENDER_TARGETS_EXT @@ @@ add extra targets to the bender invocation
BENDER_TARGETS_EXT ?=
$(call check_undefined, BENDER_TARGETS, do not add to this variable)

##% BENDER_ARGS_EXT @@ @@ add extra bender global arguments
BENDER_ARGS_EXT ?=
$(call check_undefined, BENDER_ARGS, do not add to this variable)

##% BENDER_ARGS_EXT @@ @@ add extra bender subcommand arguments
BENDER_SUBCMD_ARGS_EXT ?=
$(call check_undefined, BENDER_SUBCMD_ARGS, do not add to this variable)

CLEAN_PREREQUISITES += clean_bender
.PHONY: clean_bender
clean_bender: ## Remove all Bender.lock files in the repo
	@# Keep the Bender.lock files clean
	rm -f $(shell find $(GIT_REPO) -name Bender.lock)

.PHONY: bender_update
bender_update: clean_bender ## Run bender dependency resolution
	$(BENDER) -d $(BENDER_MANI_LOC) update
