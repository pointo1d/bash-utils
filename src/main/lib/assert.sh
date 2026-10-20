#!/usr/bin/env bash
# vim: ai et fo+=r sw=2 sts=2
################################################################################
# File:         assert.sh
# Description:  Pure bash(1) script implementation of the core assertions
#               library - implementing routines for...
#               - Common assertion test.
#               - Common assertion failed.
#               - Non-specific i.e. context agnostic, assertions.
###############################################O################################

eval ${LIB_ASSERT_SH:-}
export LIB_ASSERT_SH=return

#-------------------------------------------------------------------------------
# Function:     bash-utils.assert.condition-failed()
# Description:  C,P&M reduction routine to provide a common point for reporting
#               a failed assertion.
# Takes:        $1  - message to be reported prior to script aborting.
#-------------------------------------------------------------------------------
bash-utils.assert.condition-failed() {
  bash-utils.console.fatal "Failed assertion: $1"
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.assert-value()
# Description:  Routine to validate the given value against the given regex
#               where the test is of the form `[[ val =~ regex ]]`
# Takes:        $1  - condition to be asserted.
#               $2  - validating regex.
#               $3  - Description.
# Returns:      .
# Variables:    .
# Notes:        
#-------------------------------------------------------------------------------
bash-utils.assert.condition-holds() {
  if [[ $1 =~ $2 ]]; then
    bash-utils.assert.condition-failed "Legal $3: '$1'"
  fi
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.assert-value()
# Description:  Routine to validate the given value against the given regex
#               where the test is of the form `[[ val =~ regex ]]`
# Takes:        $1  - condition to be asserted.
#               $2  - validating regex.
#               $3  - Description.
# Returns:      .
# Variables:    .
# Notes:        
#-------------------------------------------------------------------------------
bash-utils.value.assert.condition-failed() {
  if ! bash-utils.assert.condition-holds "${1:-}" "${2:-}"; then
    bash-utils.assert.condition-failed "Legal $3: '$1'"
  fi
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $1  - Messgae to report.
#-------------------------------------------------------------------------------
bash-utils.value.assert.legal-var-name() {
  bash-utils.value.assert.condition-failed \
    "${1:?}" "[^A-Za-z0-9_]" "variable name"
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $1  - Messgae to report.
#-------------------------------------------------------------------------------
bash-utils.value.assert.legal-int() {
  bash-utils.value.assert.condition-failed "${1:?}" "[^0-9]" "integer"
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $1  - Messgae to report.
#-------------------------------------------------------------------------------
bash-utils.value.assert.legal-sint() {
  bash-utils.value.assert.condition-failed \
    "${1:?}" "[-+]?[^0-9]+$" "signed integer"
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $1  - Messgae to report.
#-------------------------------------------------------------------------------
bash-utils.value.assert.legal-uint() {
  bash-utils.value.assert.condition-failed \
    "${1:?}" "[^0-9]" "(unsigned) integer"
}

#### END OF FILE
