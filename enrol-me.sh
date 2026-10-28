#!/usr/bin/env bash
# vim: ai et fo+=r sw=2 sts=2
################################################################################
# File:         enrol-me.sh
# Description:  Pure bash(1) script to enrol the caller with the bash-utils
#               library at one of the following 2 levels:
#               - User (to set up their environment - for easier access to
#                 the libraries provisioned herein).
#               - Shell script (to set up the environment and also provide
#                 recursive inclusion avoidance routines overriding the builtin
#                 `.` and `source` function).
# Docs:         [README.md](README.md), [enrol-me.sh](src/doc/enrol-me.sh).
###############################################O################################
# shellcheck disable=SC2086
eval ${BASH_UTILS_ENROL_ME_SH:-}
declare -grx BASH_UTILS_ENROL_ME_SH=return

# ------------------------------------------------------------------------------
# Description:  Function to enrol the caller by...
#               - Exporting variables defined relative to this script into the
#                 callers run-time context.
#               - If given, exporting variables defined relative to the
#                 given location(s) into the callers run-time context.
#               - Appending the appropriate paths to the callers $PATH.
# Args:         $*  - if given,  a colon separated tuple of...
#                   - root directory 
#                   - var name prefix
#                   - callers lib prefix
# Notes:        - The generated var names are upper case e.g. *_LIB_DIR. 
# ------------------------------------------------------------------------------
bash-utils.enrol-me() {
  local print_it=t

  case "$(type -t ${FUNCNAME[1]})" in
    builtin|\
    function) unset print_it ;;
  esac

  local root_dir="" var_prefix="" prefix="" postfix=""
  while IFS=: read -r root_dir var_prefix prefix; do
    : $prefix
    local dir; for dname in '' bin lib sbin; do
      # Set the directory path
      local dir=$root_dir${dname:+/$dname}

      # And the var name
      local vname=${dname:-root}

      local var="${var_prefix^^}_${vname^^}_DIR"

      local str="export $var=$dir"

      eval "$str"

      if test "${print_it:-}"; then builtin echo "$str"; fi

      # Avoid unnecessary path updates
      if test "$dname" = lib; then continue; fi

      local path=":${BASH_UTILS_LD_LIB_PATH:-}:"
      if test "$path" = "${path/:$dir:}" ; then postfix+=":$dir"; fi
    done
  done < <(printf "%s\n" $1)

  declare str="export BASH_UTILS_LD_LIB_PATH=$postfix"
  eval "$str"
  if test "${print_it:-}"; then builtin echo "$str"; fi

  str="export PATH=$PATH$postfix"
  eval "$str"
  if test "${print_it:-}"; then builtin echo "$str"; fi
}

################################################################################
################################################################################
########                         MAIN BODY                              ########
################################################################################
################################################################################
# shellcheck disable=SC2086,SC2155
declare root_dir="$(git rev-parse --show-toplevel 2>/dev/null)"

# and process the/any user supplied args
bash-utils.enrol-me "${root_dir:-$PWD}/src/main:BASH_UTILS:"

#### END OF FILE
