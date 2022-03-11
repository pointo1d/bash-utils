#! /usr/bin/env bash
################################################################################
# File:		path.sh
# Description:	Shell script implementing library path environment variable
#               related function(s).
################################################################################

eval ${LIB_PATH_VAR_SH:-} ; export LIB_PATH_VAR_SH=return
. ${BASH_SOURCE/update-var/error}

################################################################################
# Function:     bash-utils.path.update-var.__do-op()
# Description:  Utility function to update the given/default path orientated
#               variable by appending the given path(s) to the given/default
#               variable.
# Opts:         -n STR  - STR specifies the variable to be updated, default -
#                         'PATH'
#               -s CHR  - specify the severity of a non-existant element before
#                         adding - as one of the following...
#                           * 'f' - fatal
#                           * 'i' - ignore
#                           * 'w' - warn
#                         By default, this is 'i' (ignore) i.e. the variable is
#                         updated irrespective of the existence of the path
#                         where non-existence goes unreported.
# Args:         $*      - the path(s) with which to update the named/default
#                         variable
# Returns:      0 iff the path exists or path does exist when existence is
#               non-fatal.
# Notes:
###############################################################################
bash-utils.path.update-var.__do-op() {
  local code="${1:?'No code'}" vname=

  : $#
  case $# in 0) bash-utils.console.fatal "No paths for code: '$code'" ;; esac

  local path ; for path ; do
    : $path

    # 1st off, ensure the variable value is topped & tailed by ':'
    local val=":${!vname}:"

    # It's an update, so 1st ensure non-existence isn't a problem
    case $(ls -ad $path 2>/dev/null | echo n)::$sev in
      n::i) ;;
      n::*) bash-utils.path.error.not-found -s$sev "$path" ;;
    esac

    # Finally, if all's ok thus far, set the new value iff it isn't
    # already present (somewhere :-)
    case "${val//:$path:}" in
      $val) case $op in
              a)  val="${!vname}:$path" ;;
              p)  val="$path:${!vname}" ;;
            esac
            ;;
    esac

    # Tidy up the variable by replacing '::' with ':' globally
    val="$(echo $val | sed 's,::,:,g; s,^:,,; s,:$,,')"

    # Finally, update the variable
    export $vname="$val"
  done 
}

################################################################################
# Function:     bash-utils.path.update-var.append()
# Description:  Utility function to update the given/default path orientated
#               variable by appending the given path(s) to the given/default
#               variable.
# Opts:         -n STR  - STR specifies the variable to be updated, default -
#                         'PATH'
#               -s CHR  - specify the severity of a non-existant element before
#                         adding - as one of the following...
#                           * 'f' - fatal
#                           * 'i' - ignore
#                           * 'w' - warn
#                         By default, this is 'i' (ignore) i.e. the variable is
#                         updated irrespective of the existence of the path
#                         where non-existence goes unreported.
# Args:         $*      - the path(s) with which to update the named/default
#                         variable
# Returns:      0 iff the path exists or path does exist when existence is
#               non-fatal.
# Notes:
###############################################################################
bash-utils.path.update-var.append() {
  local OPTARG OPTIND opt sev=i vname=PATH
  while getopts 'n:s:' opt ; do
    case $opt in
      n)  vname=$OPTARG ;;
      s)  case o${OPTARG//[fiw]} in
            o)  ;;
            *)  bash-utils.console.fatal "Unknown severity: $OPTARG" ;;
          esac

          sev=$OPTARG
          ;;
    esac
  done

  shift $((OPTIND - 1))

  bash-utils.path.update-var.__do-op "$code" $@

  : $#
  case $# in 0) bash-utils.console.fatal 'No paths' ;; esac

  local path ; for path ; do
    : $path

    # 1st off, ensure the variable value is topped & tailed by ':'
    local val=":${!vname}:"

    # It's an update, so 1st ensure non-existence isn't a problem
    case $(ls -ad $path 2>/dev/null | echo n)::$sev in
      n::i) ;;
      n::*) bash-utils.path.error.not-found -s$sev "$path" ;;
    esac

    # Finally, if all's ok thus far, set the new value iff it isn't
    # already present (somewhere :-)
    case "${val//:$path:}" in
      $val) case $op in
              a)  val="${!vname}:$path" ;;
              p)  val="$path:${!vname}" ;;
            esac
            ;;
    esac

    # Tidy up the variable by replacing '::' with ':' globally
    val="$(echo $val | sed 's,::,:,g; s,^:,,; s,:$,,')"

    # Finally, update the variable
    export $vname="$val"
  done 
}

################################################################################
# Function:     bash-utils.path.update-var()
# Description:  Utility function to update the given/default path orientated
#               variable.
# Opts:         -n STR  - STR specifies the variable to be updated, default -
#                         'PATH'
#               -o CHR  - CHR specifies the operation to be performed as one of
#                         the following ...
#                           * 'a' - append the value(s) (if not already present)
#                           * 'd' - remove trailing duplicated value(s)
#                           * 'D' - remove leading duplicated value(s)
#                           * 'p' - prepend the value(s) (if not already
#                                   present)
#                           * 'r' - remove the value(s) (if present)
#                         By default, 'a' (append) is assumed.
#               -s CHR  - specify the severity of a non-existant element before
#                         adding - as one of the following...
#                           * 'f' - fatal
#                           * 'i' - ignore
#                           * 'w' - warn
#                         By default, this is 'i' (ignore) i.e. the variable is
#                         updated irrespective of the existence of the path
#                         where non-existence goes unreported.
# Args:         $*      - the path(s) with which to update the variable
# Returns:      0 iff the path exists or path does exist when existence is
#               non-fatal.
# Notes:
################################################################################
bash-utils.path.update-var() {
  local OPTARG OPTIND opt op=a sev=i vname=PATH
  while getopts 'n:o:s:' opt ; do
    case $opt in
      n)  vname=$OPTARG ;;
      o)  case o${OPTARG//[apr]} in
            o)  op=$OPTARG ;;
            *)  bash-utils.console.fatal "Unknown op: $OPTARG" ;;
          esac
          ;;
      s)  case o${OPTARG//[fiw]} in
            o)  ;;
            *)  bash-utils.console.fatal "Unknown severity: $OPTARG" ;;
          esac

          sev=$OPTARG
          ;;
    esac
  done

  shift $((OPTIND - 1))

  : $#
  case $# in 0) bash-utils.console.fatal 'No paths' ;; esac

  local path ; for path ; do
    : $path

    # 1st off, ensure the variable value is topped & tailed by ':'
    local val=":${!vname}:"

    case $op in
      r)  # It's a removal, so carry on regardless - now remove the instance(s)
          # of the given path
          val=${val//:$path:/:}
          ;;
      *)  # It's an update, so 1st ensure non-existence isn't a problem
          case $(ls -ad $path 2>/dev/null | echo n)::$sev in
            n::i) ;;
            n::*) bash-utils.path.error.not-found -s$sev "$path" ;;
          esac

          # Finally, if all's ok thus far, set the new value iff it isn't
          # already present (somewhere :-)
          case "${val//:$path:}" in
            $val) case $op in
                    a)  val="${!vname}:$path" ;;
                    p)  val="$path:${!vname}" ;;
                  esac
                  ;;
          esac
          ;;
    esac

    # Tidy up the variable by replacing '::' with ':' globally
    val="$(echo $val | sed 's,::,:,g; s,^:,,; s,:$,,')"

    # Finally, update the variable
    export $vname="$val"
  done
}

#### END OF FILE
