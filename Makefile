# Your Chronicle -- development Makefile
#
# Symlinks the addon folder into a World of Warcraft install so edits are picked
# up with /reload. Run `make help` for targets and the resolved paths.

ADDON_NAME  := YourChronicle
FLAVOR      ?= _classic_beta_
SRC_DIR     := $(CURDIR)/$(ADDON_NAME)
CONFIG_FILE := .wow_path

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# WoW install location
# ---------------------------------------------------------------------------
# Resolution order: WOW_DIR on the command line / environment, then the cached
# value in $(CONFIG_FILE), then the per-OS default below.
ifeq ($(OS),Windows_NT)
  DEFAULT_WOW_DIR := C:/Program Files (x86)/World of Warcraft
else
  UNAME_S := $(shell uname -s)
  ifeq ($(UNAME_S),Darwin)
    DEFAULT_WOW_DIR := /Applications/World of Warcraft
  else
    DEFAULT_WOW_DIR := $(HOME)/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft
  endif
endif

ifdef WOW_DIR
  # explicit override wins
else ifneq (,$(wildcard $(CONFIG_FILE)))
  WOW_DIR := $(shell cat $(CONFIG_FILE))
else
  WOW_DIR := $(DEFAULT_WOW_DIR)
endif

ADDONS_DIR := $(WOW_DIR)/$(FLAVOR)/Interface/AddOns
DEST       := $(ADDONS_DIR)/$(ADDON_NAME)

# Recursively expanded (=) so cygpath only runs when a recipe uses these.
ifeq ($(OS),Windows_NT)
  LINK_CMD   = cmd //c mklink /J "$(shell cygpath -w "$(DEST)")" "$(shell cygpath -w "$(SRC_DIR)")"
  UNLINK_CMD = cmd //c rmdir "$(shell cygpath -w "$(DEST)")"
else
  LINK_CMD   = ln -sfn "$(SRC_DIR)" "$(DEST)"
  UNLINK_CMD = rm -rf "$(DEST)"
endif

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
.PHONY: help install uninstall reset check-wow-dir lint

help: ## Show this help
	@echo "$(ADDON_NAME) -- development Makefile"
	@echo ""
	@echo "Targets:"
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN { FS = ":.*## " } { printf "  %-14s %s\n", $$1, $$2 }'
	@echo ""
	@echo "Variables (override on the command line, e.g. make install FLAVOR=_classic_beta_):"
	@echo "  WOW_DIR    $(WOW_DIR)"
	@echo "  FLAVOR     $(FLAVOR)"
	@echo "  AddOns dir $(ADDONS_DIR)"
ifneq (,$(wildcard $(CONFIG_FILE)))
	@echo ""
	@echo "WOW_DIR is cached in $(CONFIG_FILE); run 'make reset' to forget it."
endif

check-wow-dir: ## Verify WOW_DIR and its FLAVOR directory exist
	@test -d "$(WOW_DIR)" || { echo "WOW_DIR does not exist: $(WOW_DIR)"; echo "Pass WOW_DIR=\"/path/to/World of Warcraft\""; exit 1; }
	@test -d "$(WOW_DIR)/$(FLAVOR)" || { echo "Flavor directory not found: $(WOW_DIR)/$(FLAVOR)"; echo "Pass FLAVOR=_retail_ or FLAVOR=_classic_beta_"; exit 1; }

install: check-wow-dir ## Symlink the addon into WoW and cache WOW_DIR in .wow_path
	@mkdir -p "$(ADDONS_DIR)"
	@if [ -e "$(DEST)" ] || [ -L "$(DEST)" ]; then $(UNLINK_CMD); fi
	@$(LINK_CMD)
	@printf '%s\n' "$(WOW_DIR)" > $(CONFIG_FILE)
	@echo "Installed $(ADDON_NAME) -> $(DEST)"

uninstall: check-wow-dir ## Remove the addon symlink from WoW
	@if [ -e "$(DEST)" ] || [ -L "$(DEST)" ]; then $(UNLINK_CMD); echo "Removed $(DEST)"; else echo "Nothing installed at $(DEST)"; fi

reset: ## Forget the cached WOW_DIR
	@rm -f $(CONFIG_FILE)
	@echo "Cleared $(CONFIG_FILE)"

lint: ## Run luacheck on the addon (skipped if luacheck is not installed)
	@if command -v luacheck >/dev/null 2>&1; then luacheck "$(ADDON_NAME)"; else echo "luacheck not found; install with: luarocks install luacheck"; fi
