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
################################################################################

eval ${__LIB_NETRC_SH__:-}
export __LIB_NETRC_SH__=return

# Include core library and its benefits
. ${BASH_SOURCE%/*}.sh

# Then make use of the non-recursive include to load the console library
lib.sinclude console

declare FilePrefix="$(case $(uname -o) in Msys) echo _ ;; esac )"
declare StdFields="login password macdef"
declare AddlFields=""
declare -A Defaults=(
  [Fname]="$HOME/${FilePrefix:-.}netrc"
  [VarName]="Netrc"
  [AllFields]="default machine $StdFields $AddlFields"
) \
InstanceMethods=()
declare ClassMethods=(
  $(sed -n '/^lib\..*() {/s,(} {,,p' $BASH_SOURCE)
)

readonly ClassMethods Defaults FilePrefix

declare netrc_file
declare -Ax ${Defaults[VarName]}

lib.console.die() {
  local rc=$1 ; case ${1//[0-9]:-y} in y) rc=$1 ; shift ;; esac
  builtin echo -e "FATAL!!! $@" >&2
  exit $rc
}

#-------------------------------------------------------------------------------
# Function:     lib.netrc.parse()
# Description:  Function to read & parse the given/default netrc file into the
#               given/default assoc. array. As with the netrc definition, the
#               assoc. array is keyed on the machine name where 'default' is a
#               pseudo-machine name whose values, if present, may be
#               auto-merged in/with the other entries.
# Opts:         -m      - specify auto-merge of defaults into the entries as
#                         appropriate
#               -o STR  - specify the name of the output file,
#                         default '-' i.e. stdout
#               -v STR  - specify the name of the associated array,
#                         default - NETRC
# Args:         $1      - optional netrc file path, default defined in/by
#                         $NetrcDefaultFname. Note that, as per POSIX,
#                         STDIN may be indicated by '-'.
# Returns:      
# Env Vars:     $NetrcDefaultFname    - $HOME/<FilePrefix>netrc
#               $NetrcDefaultVarName - $NETRC
#-------------------------------------------------------------------------------
lib.netrc.parse() {
  local OPTARG OPTIND opt automerge= vname=${Defaults[VarName]} opfile='-'
  while getopts 'mo:v:' opt ; do
    case $opt in
      m)  auto_mrg=t ;;
      o)  opfile=$OPTARG ;;
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  # Translate the output file name from '-' to /dev/stdout
  case "$opfile" in -) opfile=/dev/stdout ;; esac

  # Determine the file name - translating POSIX STDIN symbol ('-') to
  # '/dev/stdin' as appropriate
  case "${fname:=${1:-$NetrcDefaultFname}}" in
    -)          fname=/dev/stdin ;&
    /dev/stdin) ;;
    *)          case "$(builtin echo $fname*)" in
                  *\*)  lib.console.die 127 "Netrc file not found: $fname" ;;
                esac 

                case "$(wc -l $fname)" in
                  0\ *) lib.console.warn "Empty NETRC file: $fname"
                        return
                        ;;
                esac
                ;;
  esac

  # Setup the variable to take the values - and save the filename
  declare -gxA $vname ; local -n var=$vname
  var+=( [fname]="$fname" )
  
  local line ; local -A entry=() ; while read line ; do
    # Load & split the current line
    case "${line:-MT}" in
      MT)   # Empty line - which, if there's a record definition in progress,
            # delineates the end of the record
            ;;
      *)    # Process the non-empty line
            local tokens=( $line )

            local cursor
            for ((cursor=0; cursor<=${#tokens[@]}; cursor++)) ; do
              local \
                token="${tokens[$cursor]:-MT}" \
                next="${tokens[$((cursor + 1))]}"

              case "$token" in
                machine)  host=$next
                          ((cursor=cursor + 1))
                          ;;
                default)  host=$token ;;
                login|\
                macdef|\
                password) entry+=( ["$token"]="$next" )
                          ((cursor=cursor + 1))
                          ;;
                MT)       var+=( [$host]="$(declare -p entry)" )
                          ;;
              esac
            done
    esac
  done < $fname
}

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
#                         $NetrcDefaultVarName variable.
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

  # 1st ensure the named variable exists, fatal otherwise
  case "$(declare -p $vname 2>&1)" in
    *$vname=*)  var=$vname ;;
    *)          lib.console.die 127 "Variable not found: $vname" ;;
  esac

  # Determine the fields of interest to the caller, by default, this is all of
  # them
  local fields=( ${@:-${Defaults[AllFields]}} )
  case ${#var[@]} in 0) lib.console.warn "Empty definition" ; return ;; esac

  eval local -A entry=( ${var[$hname]:-} ) default=( ${var[default]} )
  local ret=()

  case ${entry[@]:-n}:${quiet:-n} in
    n:n)  lib.console.warn "Empty definition for '$hname'" ;;
  esac

  local field msg=() ret=() ; for field in "${fields[@]}" ; do
  : $field
    case $field in default|machine) continue ;; esac

    # Attempt straightfoward lookup of the given field
    local val=${entry[$field]:-}

    : ${val:-n}:${merge:+y}:${quiet:-n}
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
