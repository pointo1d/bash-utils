#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         netrc.sh
# Description:  Stand-alone bash function library - implementing netrc
#               access & manipulation routines.
# Takes:        -v  - specify the name of the associated array
# Args:         $1  - optional netrc file path, default - $HOME/.netrc
# Variables:
#   Standard shell:
#     None
#   Bespoke:
#     $<VNAME>  - bash assoc. array representation of the netrc file
# To Do:        Extend to allow class methods (as is) _and_ object methods e.g.
#               <var name>.<class method name>
# Notes:        * Altho' the values are maintained as bare strings within the
#                 netrc file itself, they are normalised as double quoted
#                 strings herein - whether, or not, they (the values) contain
#                 whitespace.
################################################################################

eval ${__LIB_NETRC_LOOKUP_SH__:-}
export __LIB_NETRC_LOOKUP_SH__=return

#-------------------------------------------------------------------------------
# Function:     lib.netrc.lookup()
# Description:  Function to get the value(s) of the given field(s) for the
#               given/default host.
# Opts:         -h STR  - specify the host name to which the field(s) apply,
#                         default - 'default'
#               -n      - specify no-auto merge of the default value (if any)
#                         with the defined value (if set).
#               -q      - specify quiet mode i.e. empty definition &/or field
#                         warnings are suppressed
#               -v STR  - the name of the variable containing the parsed/
#                         generated netrc structure, default defined in/by the
#                         $Defaults[VarName] variable.
# Args:         $1      - the field names one of those defined in the Fields
#                         file global array, no default.
# Returns:      The given field value as determined from the given host data
#               merge with the host data ... if it can be defined.
# Variables:
#   Standard:   None
#   Bespoke:    ${Defaults[Fname]}  - As it says on the tin ;-)
#               ${Default[VarName]} - --------- "" ---------
#               $<VARNAME>          - the variable containing the content to be
#                                     interrogated
# Notes:        * The non-existence of the given/default variable is fatal.
#               * There's no restriction on the names of the sought after
#                 fields.
#               * Unless explicitly disabled, warnings are generated for missing
#                 host specific definitions, as they are for missing fields for
#                 the given/default host.
#-------------------------------------------------------------------------------
lib.netrc.lookup() {
  local OPTARG OPTIND opt \
    merge=t hname=default vname=${Defaults[VarName]} quiet=
  local -n var

  while getopts 'h:nqv:' opt ; do
    case $opt in
      h)  hname=$OPTARG ;;
      n)  merge= ;;
      q)  quiet=t ;;
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  lib.netrc.validate-var-name $vname
  local -n var=$vname

  # Determine the fields of interest to the caller, by default, this is all of
  # them
  local fields=( ${@:-${Defaults[AllFields]}} )
  case ${#var[@]}:${quiet:-n} in
    0:n)  lib.console.warn "Empty definition" ;;&
    0:*)  return ;;
  esac

  eval local -A entry=( ${var[$hname]:-} ) default=( ${var[default]} )
  local ret=()

  case ${entry[@]:-n}:${quiet:-n} in
    n:n)  lib.console.warn "Empty definition for '$hname'" ;;
  esac

  local field msg=() ret=() ; for field in "${fields[@]}" ; do
    case $field in default|machine) continue ;; esac

    # Attempt straightfoward lookup of the given field
    local val=${entry[$field]:-}

    case ${val:-n}:${merge:+y}:${quiet:-n} in
      n:n:n)  # No value, no merge & not quiet
              msg=( 'No/empty definition (no auto-merge)' )
              continue
              ;;
      n:y:*)  # No value & auto-merge, so attempt the merge
              val=${default[$field]}

              # And extend the report if not quiet
              case ${val:-n}:${quiet:-n} in
                n:n)  msg='No definition (+ auto-merge)'
                      continue
                      ;;
              esac
              ;;&
      *)     ret+=( $val ) ;;
    esac

    case ${msg:+y}:${quiet:-n} in
      y:n)  msg+=( "for '$field' " )
            lib.console.warn "${msg[@]} on host '$hname'"
            msg=()
            ;;
    esac
  done

  case ${ret:+y} in y) ret="${ret[@]}" ; builtin echo ${ret// /:} ;; esac
}

#### END OF FILE
