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
################################################################################

eval ${_LIB_SINCLUDE_ANNOUNCE_SH_:-}
export _LIB_SINCLUDE_ANNOUNCE_SH_=return

# Include stack whose elements are each of the form <name>':::'<path>
declare IncludeStack=()

lib.sinclude.to-stdout() { builtin echo -e "$@" ; }

lib.sinclude.to-stderr() { builtin echo -e "$@" >&2 ; }

lib.sinclude.path.push() {
  : ${#IncludeStack[@]}, ${IncludeStack[@]}
  IncludeStack+=( ${1:?'No path to push'} )
  : ${#IncludeStack[@]}
}

lib.sinclude.path.peek() {
  case ${#IncludeStack[@]} in 0 ) ;; *) echo ${IncludeStack[-1]:-} ;; esac
}

lib.sinclude.path.peek.name() {
  local ret=$(lib.sinclude.path.peek)
  builtin echo ${ret##*:::}
}

lib.sinclude.path.peek.path() {
  local ret=$(lib.sinclude.path.peek)
  builtin echo ${ret%%:::*}
}

lib.sinclude.path.pop() {
  local ret="$(lib.sinclude.path.peek)"
  : ${#IncludeStack[@]}
  case ${#IncludeStack[@]} in 0 ) ;; *) unset IncludeStack[-1] ;; esac
  : ${#IncludeStack[@]}
  builtin echo $ret
}

lib.sinclude.path.depth() { echo ${#IncludeStack[@]} ; }

lib.sinclude.path.is-empty() {
  local ret=n
  case ${#IncludeStack[@]} in 0) ret=y ;; esac
  builtin echo $ret
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
  : ${SINCLUDE_VERBOSE:-unset}
  case ${SINCLUDE_VERBOSE:-n} in n|0|1) return ;; esac

  local nm=$(lib.sinclude.path.peek.name) path=$(lib.sinclude.path.peek.path)

  local msg=() ; case "$nm" in
    $path)  msg+=( $path ) ;;
    *)      msg+=( $nm "(in '$path')" ) ;;
  esac

  lib.sinclude.to-stdout "Load: ${msg[@]}\c"
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
  local nm=${1:?'No name'} path=${2:?'No path'}

  # Save the actual path irrespective of verbosity (might be needed later for
  # error reporting purposes)
  lib.sinclude.path.push "$nm:::$path"
  
  : ${SINCLUDE_VERBOSE:-unset}
  case ${SINCLUDE_VERBOSE:-n} in n|0|1) return ;; esac

  case $(lib.sinclude.path.is-empty) in n) lib.sinclude.to-stdout ;; esac

  lib.sinclude.to-stdout "$(lib.sinclude.announce.load-header) - Starting... \c"
}

lib.sinclude.announce.load-done() {
  : ${SINCLUDE_VERBOSE:-unset}
  local path="$(lib.sinclude.path.peek)" msg=
  lib.sinclude.path.pop >/dev/null

  : ${SINCLUDE_VERBOSE:-n}
  case ${SINCLUDE_VERBOSE:-n} in n|0) return ;; esac

  case ${SINCLUDE_VERBOSE:-n} in 1) msg="." ;; 2) msg=Done ;; esac

  # Continue line iff appropriate i.e. a nested include
  case $(lib.sinclude.path.is-empty) in
    n)  msg="$msg\c" ;;
    y)  msg="$msg\n" ;;
  esac

  lib.sinclude.to-stdout "$msg"
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
  local path="$(lib.sinclude.path.peek)" msg=
  lib.sinclude.path.pop >/dev/null

  case ${SINCLUDE_VERBOSE:-n} in
    n|0|1) return ;;
    2)      lib.sinclude.announce.load-header "$nm" "$path"
            lib.sinclude.to-stdout ' - Already loaded'
            ;;
  esac
}

#### END OF FILE
