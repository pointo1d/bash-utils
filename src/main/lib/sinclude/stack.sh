#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         sinclude/stack.sh
# Description:  Pure bash(1) script to provide a recursive inclusion avoiding
#               file inclusion capability whilst providing a simpler interface
#               such that the caller need only know a directory under which the
#               sourced file exists, so for example, this file may be included
#               merely as `. sinclude` or even the help sub-library of console
#               may be included as `. console/help` - in these casaes this is
#               because the directory containing these elements is automgically
#               included in the PATH for free.
# Env vars:     $SINCLUDE_PATH      - used to supplement the callers $PATH for
#                                     "places" in which to seek included files
#                                     (when used with relative included file
#                                     paths).
#               $SINCLUDE_VERBOSE   - when set to a integer, this determines the
#                                     verbosity of file inclusion reports where
#                                     the values are as follows...
#                                       1 - print a '.' for each file on
#                                           successful inclusion.
#                                       2 - full ie.e. starting & done, reports.
#               $SINCLUDE_NO_RECORD - there are instances when files might need
#                                     to be included multiple times, this flag
#                                     should be set (to non-empty) in such
#                                     circumstances. It actually prevents the
#                                     updating of the anti-recursive inclusion
#                                     record for the callers shell (and all
#                                     sub-shells thereof).
# Notes:
# * There are a number of variables...
#   * The pathing - which may be...
#     * fully pathed.
#     * simple relative.
#     * complex relative.
#   * The extension which may, or may not, be present - if not present, then it
#     has to be guessed at (no file has to have an extension - and on Windoze
#     the absence of an extensiona appears to remove the execution status of the
#     file), so the 1st guess is always the extensionless file name).
# * The use of $SINCLUDE_NO_RECORD should be used with great care (for
#   self-evident reasons).
# * With $SINCLUDE_VERBOSE at level 2, the generated messages occur in the
#   following stages for the given scenarios....
#   follows...
#   * Initial load...
#     1 - 'Load: <fname>: '
#     2 - 'Load: <fname>: Starting ...'
#     3 - 'Load: <fname>: Starting ... Done'
#   * Duplicated load...
#     1 - 'Load: <fname>: '
#     2 - 'Load: <fname>: Loaded'
#   $SINCLUDE_VERBOSE at level 1...
#   * Initial load...
#     1 - '.'
#   * Duplicated load...
#     1 - ''
################################################################################

eval ${_LIB_SINCLUDE_STACK_SH_:-}
export _LIB_SINCLUDE_STACK_SH_=return

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.exists()
# Description:  Routine to initialize the given stack.
# Takes:        $1  - the name of the stack - no default
# Returns:      The existence, or otherwise, of the given stack on STDOUT - as
#               one of '0' - exists, <> '0' otherwise (depending on the outcome
#               of running 'declare -p' on the stack name.
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.stack-var() {
  case "$(declare -p ${1:?'No stack name'} 2>/dev/null)" in
    declare\ -n*) builtin echo "declare stack=$1" ;;
    *)            builtin echo "declare -n stack=$1" ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.exists()
# Description:  Routine to initialize the given stack.
# Takes:        $1  - the name of the stack - no default
# Returns:      The existence, or otherwise, of the given stack on STDOUT - as
#               one of '0' - exists, <> '0' otherwise (depending on the outcome
#               of running 'declare -p' on the stack name.
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.exists() {
  ( declare -p ${1:?'No stack name'} >/dev/null 2>&1 ; builtin echo $? )
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.init()
# Description:  Routine to initialize the given stack.
# Takes:        $1  - the name of the stack - no default
# Returns:      None.
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.init() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null
  stack=( )
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.push()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - the name of the stack - no default
#               $2  - posited entry.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.push() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null ; shift
  stack+=( "$@" )
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.push()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - the name of the stack - no default
#               $2  - posited entry.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.peek() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null
  case ${#stack[@]} in 0 ) ;; *) builtin echo ${stack[-1]:-} ;; esac
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.push()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - the name of the stack - no default
#               $2  - posited entry.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.peek.name() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null
  local ret=$(lib.sinclude.stack.peek stack)
  builtin echo ${ret%%:::*}
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.push()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - the name of the stack - no default
#               $2  - posited entry.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.peek.path() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null
  local ret=$(lib.sinclude.stack.peek stack)
  builtin echo ${ret##*:::}
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.push()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - the name of the stack - no default
# Returns:      Previous top-of-stack,  on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.pop() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null
  local ret="$(lib.sinclude.stack.peek stack)"
  case ${#stack[@]} in 0 ) ;; *) unset stack[-1] ;; esac
  builtin echo $ret
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.push()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - the name of the stack - no default
#               $2  - posited entry.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.depth() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null
  builtin echo ${#stack[@]}
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.stack.push()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - the name of the stack - no default
#               $2  - posited entry.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.stack.is-empty() {
  eval lib.sinclude.stack.stack-var ${1:?'No stack name'} >/dev/null
  local ret=n
  case ${#stack[@]} in 0) ret=y ;; esac
  builtin echo $ret
}

#### END OF FILE
