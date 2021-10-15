#! /usr/bin/env bash
################################################################################
# File:		path.sh
# Description:	Shell script implementing library path related functions
################################################################################

eval ${LIB_PATH_ERRORS_SH:-} ; export LIB_PATH_ERRORS_SH=return
. ${BASH_SOURCE%/*}/../console.sh

################################################################################
# Function:     lib.path.error.not-found()
# Description:  Core function to report that the given path doesn't exist, where
#               the nature of the report depends entirely on the given severity.
# Opts:         -s SEV  - specify th severity to report - as one of...
#                         'f' - fatal
#                         'w' - warning
# Args:         $1  - the path to report
# Returns:      0 iff the severity is 'w'arn, doesn't return otherwise
################################################################################
lib.path.error.not-found() {
  local OPTARG OPTIND opt sev=f
  while getopts 's:' opt ; do
    case $opt in
      s)  case o${OPTARG//[fw]} in
            o)  sev=$OPTARG ;;
            *)  lib.console.fatal "Unknown severity: $OPTARG" ;;
          esac
          ;;
    esac
  done

  shift $((OPTIND - 1))
  local msg="Path not found: ${1:-'No path to report'}"

  case $sev in
    f)  lib.console.fatal "$msg" ;;
    w)  lib.console.warn "$msg" ;;
  esac
}

#### END OF FILE
