#!/usr/bin/env bash
# vim: ai et fo+=r sw=2 sts=2
################################################################################
# File:         getopts/assert.sh
# Description:  Pure bash(1) script implementing bash-utils.getopts specific
#               extnesions to the core assertions library.
###############################################O################################

eval ${LIB_GET_OPTIONS_ASSERT_SH:-}
export LIB_GET_OPTIONS_ASSERT_SH=return

# Load the core assertions library
. ${BASH_SOURCE/getopts\/}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $1  - Messgae to report.
#-------------------------------------------------------------------------------
getopts.assert.entry-definition-failed() {
  bash-utils.assert.condition-failed "Entry definition - $*"
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $1  - Messgae to report.
#-------------------------------------------------------------------------------
getopts.assert.entry-definition.defined() {
  local type=$1; shift
  if test $# -eq 0; then
    getopts.assert.entry-definition-failed "No ${type:-} entry"
  fi
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $*  - List of mandatory keys
# Variable(s):  entry - defined by the caller, this contains the entry to test
#                       for the key(s).
#-------------------------------------------------------------------------------
getopts.assert.entry-definition.mandatory-keys-defined() {
: $(declare -p entry)
  local -n defn=entry

  local missing=() key=""; for key; do
    if test "${defn[$key]:-}"; then return; fi
    missing+=( $key )
  done

  if test ${#missing[@]}; then
    getopts.assert.entry-definition-failed \
      "Missing mandatory key(s): ${missing[@]}"
  fi
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $*  - List of mandatory keys
# Variable(s):  entry - defined by the caller, this contains the entry to test
#                       for the key(s).
#-------------------------------------------------------------------------------
getopts.assert.entry-definition.extra-keys-defined() {
  local type=$1; shift
  if test $# -eq 0; then
    getopts.assert.entry-definition-failed "No ${type:-} entry definition"
  fi
}

#### END OF FILE
