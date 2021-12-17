#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         sinclude.sh
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

eval ${_LIB_SINCLUDE_ANNOUNCE_SH_:-}
export _LIB_SINCLUDE_ANNOUNCE_SH_=return

lib.sinclude.to-stderr() { builtin echo -e "$@" >&2 ; }

# ------------------------------------------------------------------------------
# Function:     sinclude.load.announce.load-header()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.load-header() {
  local nm=${1:?'No path'} path=${2:-}

  : ${SINCLUDE_VERBOSE:-unset}
  case ${SINCLUDE_VERBOSE:-n} in n|0|1) return ;; esac

  local msg=() ; case "$nm" in
    $path)  msg+=( $path ) ;;
    *)      msg+=( $nm "(in '$path')" ) ;;
  esac

  lib.sinclude.to-stderr "Load: ${msg[@]}\c"
}

# ------------------------------------------------------------------------------
# Function:     sinclude.load.announce-starting()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.load-starting() {
  local nm=${1:?'No path'} path=${2:-}

  : ${SINCLUDE_VERBOSE:-unset}
  case ${SINCLUDE_VERBOSE:-n} in
    n|0|1)  return ;;
  esac

  lib.sinclude.announce.load-header "$nm" "$path"
  lib.sinclude.to-stderr " - Starting... \c"
}

lib.sinclude.announce.load-done() {
  : ${SINCLUDE_VERBOSE:-unset}
  case ${SINCLUDE_VERBOSE:-n} in
    n|0)  return ;;
    1)    msg=".\c" ;;
    2)    lib.sinclude.to-stderr Done ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     sinclude.announce.already-loaded()
# Description:  As it says on the tin - selectively reports the file load/source
#               loaded event.
# Takes:        None
# Returns:      
# Variables:    None..
# ------------------------------------------------------------------------------
lib.sinclude.announce.already-loaded() {
  local nm=${1:?'No path'} path=${2:-}

  case ${SINCLUDE_VERBOSE:-n} in
    n|0|1)  return ;;
    2)      lib.sinclude.announce.load-header "$nm" "$path"
            lib.sinclude.to-stderr ' - Already loaded'
            ;;
  esac
}

#### END OF FILE
