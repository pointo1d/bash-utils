#! /usr/bin/env bash
################################################################################
# File:		console.sh
# Description:	Shell script defining the console related library routines -
#               including, but not limited to, the introspective help & man
#               routines.
################################################################################

eval ${LIB_CONSOLE_SH:-}
export LIB_CONSOLE_SH=return

# ------------------------------------------------------------------------------
# Function:     console.to-stderr()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.to-stderr() { echo -e "$@" >&2 ; }

# Load the logger - initially basic, but extendable post-init
# . ${BASH_SOURCE//console/log4sh}

# This script essentially contains wrapper for the core STDERR & STDOUT based
# logger provisioned by log4sh

# Enumerate the severities - as a precursor to a log4bash implementation
declare SevPriorities=( unknown fatal error warn info debug trace )

# Declare the possible severity types
declare -A \
  ExitStatus=() \
  SevTypes=(
    [unknown]=y [fatal]=y [error]=y
    [warn]=n [info]=n [debug]=n [trace]=n
  )
# For efficiency, a mapping of the severity names onto their generated severity
# logging routine name
declare -A Severities=()

# ------------------------------------------------------------------------------
# Function:     lib.console._gen-msg-logger()
# Description:  Utility routine provided to generate a message logger routine
# Takes:        None.
# Variables:    $SeverityTypes  - assoc array defining the possible message
#                                 types
# ------------------------------------------------------------------------------
lib.console._gen-msg-logger() {
  local nm=${1:?'No msg logger name'} typ=${2:?'No msg logger type'}
  local init=${nm:0:1}

  Severities[$init]=$nm
  local fn_nm="lib.console.$nm"

  local code ; case ${SeverityTypes[$nm]:-n} in
    y) code='exit ${ExitStatus[rc]}'
  esac

  # Generate the routine
  eval "
  $fn_nm() {
    lib.console._extract-rc \$*
    lib.console.to-stderr \"${nm^^}!! \${ExitStatus[msg]}\"

  }
  $code
  "

  #... and finally the associated global readonly var - as an integer value
  # determined by the priorities defined in/by $SevPriorities - where 0 i.e.
  # unknown, is the highest priority
  declare -gr ${nm^^}=$(declare -p SevPriorities | sed "s,.*\[\(.\)\]=\\\"$nm\\\".*,\1,")
}

# ------------------------------------------------------------------------------
# Function:     lib.console.init()
# Description:  Utility routine to initialise the conle logging "subsystem".
# Takes:        None.
# Returns:      The standard form comprising a string on STDOUT where the exit
#               status is always the first token and the message the rest of the
#               string thereafter.
# ------------------------------------------------------------------------------
lib.console.init() {
  local n ; for n in ${!SevPriorities[@]} ; do
    lib.console._gen-msg-logger ${SevPriorities[$n]} $n
  done
}

# ------------------------------------------------------------------------------
# Function:     console._extract-rc()
# Description:  Utility routine to translate the input string into an exit
#               status + mesage.
# Takes:        $*  - the optional exit status + message to be translated to the
#                     standard form i.e. the exit status is enforced.
# Returns:      The standard form comprising a string on STDOUT where the exit
#               status is always the first token and the message the rest of the
#               string thereafter.
# ------------------------------------------------------------------------------
lib.console._extract-rc() {
  ExitStatus=([rc]=1 [msg]='')

  case $(expr $1 : '[^0-9]') in
    0)  ExitStatus[rc]=$1 ; shift ;;
  esac

  ExitStatus[msg]="$*"
}

# ------------------------------------------------------------------------------
# Function:     console.clear-screen()
# Description:  Routine provided to selectively clear the screen - env var
#               permitting.
# Takes:        None.
# Variables:    $NO_CLEAR_SCREEN  - the screen is cleared iff undefined or
#                                   defined as an empty value.
# ------------------------------------------------------------------------------
lib.console.clear-screen() {
  case "n$NO_CLEAR_SCREEN" in n) ;; *) clear ;; esac
}

# ------------------------------------------------------------------------------
# Function:     lib.console.die()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that if $1 is
#                     numeric and > 0, then this is extracted from the message
#                     and used for the exit status; Note also, that escape
#                     sequences contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.die() {
  local prefix=Died ; case ${FUNCNAME[1]} in
    lib.console.error|\
    lib.console.fatal|\
    lib.console.unknown)  prefix=${FUNCNAME[1]//lib.console.}
                          prefix=${prefix^^}
                          ;;
  esac

  lib.console._extract-rc $*
  lib.console.to-stderr "${prefix}:: ${ExitStatus[msg]} !!!"
  exit ${ExitStatus[rc]}
}

# ------------------------------------------------------------------------------
# Function:     console.unknown()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that if $1 is
#                     numeric and > 0, then this is extracted from the message
#                     and used for the exit status; Note also, that escape
#                     sequences contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.unknown() { lib.console.die $@ ; }

# ------------------------------------------------------------------------------
# Function:     console.fatal()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that if $1 is
#                     numeric and > 0, then this is extracted from the message
#                     and used for the exit status; Note also, that escape
#                     sequences contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.fatal() { lib.console.die $@ ; }

# ------------------------------------------------------------------------------
# Function:     console.error()
# Synopsis:
#   console.error MSG DIAG
#   console.error INT MSG DIAG
# Description:  Routine to provide a simple way of reporting a fatal error with
#               an accompanying non-zero exit status.
# Takes:        $1  - either the basic message to print to STDERR or an integer
#                     specifying the return code.
#               $2  - depending on $1, either the basic message or an optional
#                     diagnostic message.
#               $3  - depending on $1, an optional diagnostic message.
# ------------------------------------------------------------------------------
lib.console.error() { lib.console.die $@ ; }

# ------------------------------------------------------------------------------
# Function:     console.warn()
# Description:  Routine to report the given message as a warning.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.warn() { lib.console.to-stderr "WARN:: $@"; }

# ------------------------------------------------------------------------------
# Function:     console.info()
# Description:  Routine to report the given message as routine information.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.info() { lib.console.to-stderr "INFO:: $@"; }

# ------------------------------------------------------------------------------
# Function:     console.debug()
# Description:  Routine to report the given message as routine information.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.debug() { lib.console.to-stderr "DEBUG:: $@"; }

# ------------------------------------------------------------------------------
# Function:     console.trace()
# Description:  Routine to report the given message as routine information.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.trace() { lib.console.to-stderr "TRACE:: $@"; }

. ${BASH_SOURCE%.sh}/help.sh

# ------------------------------------------------------------------------------
# Function:     lib.console.log-msg()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated severity handling code in error reporting scripts.
# Takes:        -s SEV  - specify the severity of the error to be reported as
#                         one of...
#                         't' (trace)
#                         'd' (debug)
#                         'i' (info)
#                         'w' (warn)
#                         'e' (error)
#                         'f' (fatal)
#                         'u' (unknown)
#
#                         , default - fatal
# Args:         $*  - the message to be reported to STDERR - note that escape
#                     sequence(s) contained therein are honoured.
# ------------------------------------------------------------------------------
lib.console.log-msg() {
  local OPTARG OPTIND opt sev=t
  while getopts 's:' opt ; do
    case $opt in
      s)  sev=${OPTARG//[${!Severities[@]}]}
          case ${sev:-n} in
            n) lib.console.fatal "Unknown severity: $sev" ;;
          esac
          ;;
    esac
  done

  shift $((OPTIND - 1))

  eval lib.console.${Severities[$sev]} "$*"
}

# vim: ai sw=2 sts=2 et
#### END OF FILE
