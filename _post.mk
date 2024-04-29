
########################################
##@ Flow maintenance:
########################################

##% CLEAN_PREREQUISITES @@ clean_<subtarget> @@ Collects all sub-clean commands, add this to your clean target to this variable

.PHONY: clean
clean: $(CLEAN_PREREQUISITES) ## Cleans everything
	rm -rf build_*
	find $(MAKEFILE) -name \Bender.lock -type f -delete

.PHONY: help_grid
help_grid: ## List the options for the computing grid
	@echo "Grid enabeld:         $(GRID_ENABLE)"
	@echo "Number CPU:           $(GRID_NUM_CPUS)"
	@echo "Timeout Minutes:      $(GRID_TIMEOUT_MIN)"
	@echo "Common Options:       $(GRID_OPTS)"
	@echo "Extra Options:        $(GRID_OPTS_EXT)"
	@echo "Commandline:          $(GRID_CMD)"

.PHONY: help_bender
help_bender: ## List all bender targets
	@echo "Top manifest location: $(BENDER_MANI_LOC)"
	@echo "Internal targets:      $(BENDER_TARGETS)"
	@echo "External targets:      $(BENDER_TARGETS_EXT)"

# This is an auto-documenting Makefile.
#
# This rule will crawl all included makefiles and build a  help target.
# They are grouped in sections and then listed alphabetically.
# There are three ways to use special comments to document:
#
# 1: Section header: For grouping targets
#   ##@ <section_name>
#
# 2: Variable documentation: Should be placed in line above and kept up to date!
#   ##% <variable_name> @@ <default> @@ <short_comment>
#
# 3: Target documentation: In line of the actual target.
#   <target>: <prerequesites> ## <short_comment>
.PHONY: help
help: ## Display this help
	@awk 'BEGIN { \
			FS = ":.*##|@@"; \
			printf "\nUsage:\n  make <target> <VARIABLE=<external_specify>>\n" \
		} \
		/^[%a-zA-Z_0-9-]+:.*?##/ { \
			printf "  %-20s %s\n", $$1, $$2 \
		} \
		/^##%.+[a-zA-Z_0-9-]+.*@@.*@@/ { \
			printf "  %-20s %-20s %s\n", substr($$1, 5), $$2, $$3 \
		} \
		/^##@/ { \
			printf "\n%s\n", substr($$0, 5) \
		} '  $(MAKEFILE_LIST)

.PHONY: make_stru
make_stru: ## List all linked makefile files (includes config.mk and verif.mk)
	$(info $(MAKEFILE_LIST))
