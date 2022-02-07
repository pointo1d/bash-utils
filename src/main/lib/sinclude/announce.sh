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
#   * Initial load (single)...
#     1 - 'Load: <fname>: '
#     2 - 'Load: <fname>: Starting ...'
#     3 - 'Load: <fname>: Starting ... Done'
#   * Initial load (multiple)...
#     1 - 'Load: <fname1>: '
#     2 - 'Load: <fname1>: Starting ...'
#     3 - 'Load: <fname2>: '
#     4 - 'Load: <fname2>: Starting ...'
#     5 - 'Load: <fname2>: Starting ... Done'
#     6 - 'Load: <fname1>: Done'
#   * Duplicated load...
#     1 - 'Load: <fname>: '
#     2 - 'Load: <fname>: Loaded'
#   $SINCLUDE_VERBOSE at level 1...
#   * Initial load...
#     1 - '.'
#   * Duplicated load...
#     1 - ''
#
#   header
#   starting done | already loaded
################################################################################

#eval ${_LIB_SINCLUDE_ANNOUNCE_SH_:-}
#export _LIB_SINCLUDE_ANNOUNCE_SH_=return
: $# - $@

declare -a IncludeStack
declare Pself="$(lib.sinclude.abs-path $BASH_SOURCE)"
declare action=${1:-} ; shift
: $# - $@

case $action in
  noload) lib.sinclude.announce.warning \
            "'$BASH_SOURCE' ('$Pself') already loaded"
          return
          ;;
esac

# Update the inclusion stack for load of this file - which will already be
# present if already loaded
lib.sinclude.add-lib "$Pself"
IncludeStack+=( "$BASH_SOURCE::$Pself" )
lib.sinclude.announce.action-msg "$BASH_SOURCE" "$Pself"
case ${SINCLUDE_VERBOSE:-} in
  2) lib.sinclude.announce.msg " - Starting ...\c" ;;
esac

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.load.announce()
# Description:  Reports the given message.
# Takes:        $*  - the message to be reported.
# Returns:      0 + the message on STDOUT.
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.announce() { builtin echo -e "$@" ; }

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.fatal()
# Description:  Reports the given message to STDOUT and exits with the optional
#               return code.
# Takes:        $1  - optional return code as a +ve integer.
#               $*  - the message itself
# Returns:      Never - generates the message on STDOUT + exit with the
#               given/default return code.
# Variables:    None.
# ------------------------------------------------------------------------------
lib.sinclude.announce.fatal() {
  local rc=1 ; case i${1//[0-9]/} in i) rc=$1 ; shift ;; esac

  builtin echo -e "$*" >&2
  exit $rc
}

# ------------------------------------------------------------------------------
# Function:     sinclude.load.announce.add-lib()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.add-lib() {
  local nm=${1:?'No name'} path="${2:-$1}"
  path="$(lib.sinclude.abs-path $path)"

  # Save the actual path irrespective of verbosity (might be needed later for
  # error reporting purposes)
  IncludeStack+=( "$nm:::$path" )
}

lib.sinclude.announce.get-top() {
  case ${IncludeStack[@]:-0} in
    0)  ;;
    *)  builtin echo ${IncludeStack[-1]} ;;
  esac
}

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
  local nm=${1:?'No name'} path="${2:-$1}"

  # Save the actual path irrespective of verbosity (might be needed later for
  # error reporting purposes)
  lib.sinclude.announce.add-lib "$nm" "$path"

  case ${SINCLUDE_VERBOSE:-n} in n|0|1) return ;; esac

  local msg=( 'Load:' ) ; case "$nm" in
    $path)  msg+=( "'$path'" ) ;;
    *)      msg+=( "'$nm', file: '$path'" ) ;;
  esac

  lib.sinclude.announce "${msg[@]}\c"
}

# ------------------------------------------------------------------------------
# Function:     sinclude.load.announce-starting()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event. If called before .*load-header(), then it
#               (lib.sinclude.load-header()) is automatically called
# Takes:        $1  - accessible lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.load-starting() {
  local top="$(lib.sinclude.announce.get-top)"
  local nm="${top/::*}" path="${top/*::}"

  case ${SINCLUDE_VERBOSE:-n} in n|0|1) return ;; esac

  lib.sinclude.announce " - Starting ... \c"
}

# Better late than never, announce this file is starting to load
#lib.sinclude.announce.load-starting "$BASH_SOURCE"

# ------------------------------------------------------------------------------
# Function:     sinclude.load.announce-done()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        none
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.load-done() {
  : ${IncludeStack[@]}
  local msg= nm="$(lib.sinclude.announce.get-top)"
  local abs="${nm//*::}" ; nm=${nm//::*}

  case ${#IncludeStack[@]} in 0) ;; *) unset IncludeStack[-1] ;; esac

  case ${SINCLUDE_VERBOSE:-n} in
    1)  lib.sinclude.announce ".\c" ;;
    2)  case ${#IncludeStack[@]} in
          0)  lib.sinclude.announce.action-msg "$nm" "$abs"
              lib.sinclude.announce ' - Done' 
              ;;
          *)  lib.sinclude.announce ' Done' ;;
        esac
        ;;
  esac
}

lib.sinclude.announce.load-done

#### END OF FILE
