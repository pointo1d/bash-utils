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

eval ${ENROL_ME_SH:-}
readonly export ENROL_ME_SH=return

# Load the errors core i.e. context agnostic, library
#. $(dirname $BASH_SOURCE)/src/main/lib/errors.sh

export Enrolments=()

# ------------------------------------------------------------------------------
# Description:   The enrolment function itself.
# ------------------------------------------------------------------------------
bash-utils.enrol() {
  if ! test "${1:-}"; then return; fi
  
  local root_dir="" var_root="" prefix=""
  while IFS=: read -r root_dir var_prefix prefix; do
    local dir; for dname in '' bin sbin lib; do
      # Set the directory path
      local dir=$root_dir${dname:+/$dname}

      # And the var name
      dname=${dname^^}

      local var="${var_prefix^^}_${dname:-ROOT}_DIR"

      export $var=$dir
      Enrolments+=( "${!var}" )

      # Avoid unnecessary path updates
      case $dname in LIB|ROOT) continue ;; esac

      local path=":${PATH//::}:"
      if test "$path" = "${path/:$dir:}" ; then
        export PATH+=":${!var}"
      fi
    done
  done < <(printf "%s\n" $1)
}

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
  local root_dir="$(git rev-parse --show-toplevel 2>/dev/null)"

  if test "${root_dir:-}"; then
    root_dir+=/src/main
  fi

  # Do the enrolment(s) themselves - starting with self
  local e; for e in "$root_dir:BASH_UTILS:" "$@"; do
    bash-utils.enrol "$e"
  done
}

# ------------------------------------------------------------------------------
# Description:  Function to enrol the caller by...
#               - Exporting variables defined relative to this script into the
#                 callers run-time context.
#               - If given, exporting variables defined relative to the
#                 given location(s) into the callers run-time context.
#               - Appending the appropriate paths to the callers $PATH.
# ------------------------------------------------------------------------------
bash-utils.lib-include() {
  fatal() { builtin echo "FATAL: $* !!!" >&2; exit 1; }

  if test $# -eq 0; then fatal "Nothing to include"; fi

  local caller=${FUNCNAME[1]} dirs=( "${Enrolments[@]}" ${PATH//:} )

  local lib; for lib; do
    local orig=$lib

    local found; for found in "${dirs[@]}"; do
      if test -f $lib; then
        found=$lib
      elif test -f $found/$lib; then
        found=$found/$lib
      elif test -f $found/$lib.sh; then
        found=$found/$lib.sh
      else
        unset found
      fi

      if test "${found:-}"; then break; fi
    done

    if test "${found:-}"; then
      builtin $caller $found
    else
      fatal "File not found for library: '$orig'"
    fi
  done
}

# Define the builtin file inclusion overrides
.() { bash-utils.lib-include "$@"; }

source() { bash-utils.lib-include "$@"; }

export -f . source

# Adjust the args (to remove the invocation of this script)
shift 2

# and process the/any user supplied args
bash-utils.enrol-me "$@"

#### END OF FILE
