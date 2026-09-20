# __ADDON_TITLE__ -- development Makefile
#
# Symlinks the addon folder into a World of Warcraft install so edits are picked
# up with /reload. Run `make help` for targets and the resolved paths.

ADDON_NAME  := __ADDON_NAME__
FLAVOR      ?= __FLAVOR__
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

# >>> template-init >>>
# Everything between these markers is removed by `make init`.
# Variables passed on the make command line are exported to the recipe's
# environment, so the script reads NAME, FLAVOR, TITLE, ... from env.
# Inside `define`, `$$` is a literal `$` for the shell. No `#` lines inside.
define INIT_SCRIPT
set -eu
TOKEN_RE='__[A-Z][A-Z0-9_]*__'
TEMPLATE_DIR=__ADDON_NAME__
die() { printf 'init: %s\n' "$$*" >&2; exit 1; }
esc() { printf '%s' "$$1" | sed 's/[\\&|]/\\&/g'; }
rewrite() { f=$$1; shift; "$$@" < "$$f" > "$$f.init.tmp"; cat "$$f.init.tmp" > "$$f"; rm -f "$$f.init.tmp"; }
lower() { printf '%s' "$$1" | tr '[:upper:]' '[:lower:]'; }
upper() { printf '%s' "$$1" | tr '[:lower:]' '[:upper:]'; }

[ -d "$$TEMPLATE_DIR" ] || die "already initialized ($$TEMPLATE_DIR/ not found)"

NAME=$${NAME:-}
[ -n "$$NAME" ] || die "NAME is required, e.g. make init NAME=MyAddon FLAVOR=retail"
case $$NAME in
    [!A-Za-z]*|*[!A-Za-z0-9]*) die "NAME must be letters and digits only, starting with a letter (got '$$NAME')" ;;
esac

FLAVOR=$${FLAVOR:-}
case $$FLAVOR in
    retail|_retail_)        FLAVOR_DIR=_retail_;       INTERFACE=120100 ;;
    forever|_classic_beta_) FLAVOR_DIR=_classic_beta_; INTERFACE=16001 ;;
    "")                     die "FLAVOR is required: retail or forever" ;;
    *)                      die "FLAVOR must be 'retail' or 'forever' (got '$$FLAVOR')" ;;
esac

UPPER=$$(upper "$$NAME")
LOWER=$$(lower "$$NAME")
TITLE=$${TITLE:-$$NAME}
NOTES=$${NOTES:-"$$TITLE for World of Warcraft."}
SLASH=$${SLASH:-$$LOWER}
SLASH=$${SLASH#/}
case $$SLASH in
    ""|*/*|*[[:space:]]*) die "SLASH must be a single word (got '$$SLASH')" ;;
esac
AUTHOR=$${AUTHOR:-$$(git config user.name 2>/dev/null || true)}
AUTHOR=$${AUTHOR:-$${USER:-$$(whoami)}}

REPO=$${REPO:-}
GITHUB_USER=$${GITHUB_USER:-}
remote=$$(git remote get-url origin 2>/dev/null || true)
case $$remote in
    *github.com[:/]*)
        path=$${remote##*github.com[:/]}; path=$${path%/}; path=$${path%.git}
        [ -n "$$GITHUB_USER" ] || GITHUB_USER=$${path%%/*}
        [ -n "$$REPO" ] || REPO=$${path##*/}
        ;;
esac
REPO=$${REPO:-$$(basename "$$(pwd)")}
GITHUB_USER=$${GITHUB_USER:-yak3d}

printf 'Initializing %s\n' "$$NAME"
printf '  Title:  %s\n' "$$TITLE"
printf '  Flavor: %s (Interface %s)\n' "$$FLAVOR_DIR" "$$INTERFACE"
printf '  Slash:  /%s\n' "$$SLASH"
printf '  Author: %s\n' "$$AUTHOR"
printf '  Repo:   %s/%s\n' "$$GITHUB_USER" "$$REPO"

rewrite Makefile  sed '/^# >>> template-init >>>$$/,/^# <<< template-init <<<$$/d'
rewrite README.md sed '/^<!-- template:begin -->$$/,/^<!-- template:end -->$$/d'

if [ "$$SLASH" = "$$LOWER" ]; then
    rewrite "$$TEMPLATE_DIR/Core.lua" sed '/^SLASH___ADDON_UPPER__2 = /d'
    rewrite .luacheckrc sed '/"SLASH___ADDON_UPPER__2",/d'
fi

E_NAME=$$(esc "$$NAME"); E_TITLE=$$(esc "$$TITLE"); E_UPPER=$$(esc "$$UPPER")
E_LOWER=$$(esc "$$LOWER"); E_SLASH=$$(esc "$$SLASH"); E_NOTES=$$(esc "$$NOTES")
E_AUTHOR=$$(esc "$$AUTHOR"); E_REPO=$$(esc "$$REPO"); E_GHUSER=$$(esc "$$GITHUB_USER")
subst() {
    sed -e "s|__ADDON_NAME__|$$E_NAME|g" -e "s|__ADDON_TITLE__|$$E_TITLE|g" \
        -e "s|__ADDON_UPPER__|$$E_UPPER|g" -e "s|__ADDON_LOWER__|$$E_LOWER|g" \
        -e "s|__ADDON_SLASH__|$$E_SLASH|g" -e "s|__ADDON_NOTES__|$$E_NOTES|g" \
        -e "s|__AUTHOR__|$$E_AUTHOR|g" -e "s|__INTERFACE__|$$INTERFACE|g" \
        -e "s|__FLAVOR__|$$FLAVOR_DIR|g" -e "s|__REPO_NAME__|$$E_REPO|g" \
        -e "s|__GITHUB_USER__|$$E_GHUSER|g"
}

find . -type f ! -path './.git/*' ! -name '*.init.tmp' | while IFS= read -r f; do
    if grep -qI -- "$$TOKEN_RE" "$$f"; then
        rewrite "$$f" subst
        printf '  edited  %s\n' "$${f#./}"
    fi
done

find . -depth ! -path './.git/*' -name "*$${TEMPLATE_DIR}*" | while IFS= read -r p; do
    d=$$(dirname "$$p"); b=$$(basename "$$p")
    n=$$(printf '%s' "$$b" | sed "s|__ADDON_NAME__|$$E_NAME|g")
    q=$$d/$$n
    mv "$$p" "$$q"
    printf '  renamed %s -> %s\n' "$${p#./}" "$${q#./}"
done

if leftovers=$$(grep -rIn --exclude-dir=.git -- "$$TOKEN_RE" . 2>/dev/null) && [ -n "$$leftovers" ]; then
    printf '%s\n' "$$leftovers" >&2
    die "unreplaced tokens remain (see above)"
fi

printf '\nDone. %s is ready.\n\nNext steps:\n' "$$NAME"
printf '  git add -A && git commit -m "Initialize %s from template"\n' "$$NAME"
printf '  make install          (symlink into <WOW_DIR>/%s/Interface/AddOns)\n' "$$FLAVOR_DIR"
printf '  Set "## X-Curse-Project-ID" in %s/%s.toc and add the CF_API_KEY secret before tagging.\n' "$$NAME" "$$NAME"
endef
export INIT_SCRIPT

init: ## Instantiate the template: make init NAME=MyAddon FLAVOR=retail|forever [TITLE=..] [AUTHOR=..] [SLASH=..] [NOTES=..] [REPO=..] [GITHUB_USER=..]
	@sh -c "$$INIT_SCRIPT"

ifeq ($(ADDON_NAME),__ADDON_NAME__)
help: template-banner
install uninstall check-wow-dir: template-not-initialized
template-banner:
	@echo "*** Uninitialized template. Run: make init NAME=MyAddon FLAVOR=retail|forever ***"
	@echo ""
template-not-initialized:
	@echo "This is the uninitialized template. Run: make init NAME=MyAddon FLAVOR=retail|forever"; exit 1
endif
.PHONY: init template-banner template-not-initialized

# <<< template-init <<<
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
