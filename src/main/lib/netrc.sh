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
#declare -Ax ${Defaults[VarName]}

lib.console.die() {
  local rc=$1 ; case ${1//[0-9]:-y} in y) rc=$1 ; shift ;; esac
  builtin echo -e "FATAL!!! $@" >&2
  exit $rc
}

#-------------------------------------------------------------------------------
# Function:     lib.netrc.exists
# Description:  Function to determine if the given env var actually exists.
# Opts:         -l      - specify long i.e. full report, by default the report
#                         is made as per 'declare -p'.
#               -v STR  - specify alternate env var name, default -
#                         ${Defaults[VarName]}
# Args:         None
# Returns:      0 c/w either 'e', 'p', 'n' or full report, where ...
#               * 'e' - var exists & is empty
#               * 'p' - var exists & is not empty i.e. populated
#               * 'n' - var doesn't exist
#               * full report is as reported by 'declare -p'
#               STDOUT.
# Env Vars:     $Defaults[VarName]
# Notes:        None
#-------------------------------------------------------------------------------
lib.netrc.exists() {
  local OPTARG OPTIND opt full= vname=${Defaults[VarName]}
  while getopts 'lv:' opt ; do
    case $opt in
      l)  full=t ;;
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  local ret="$(declare -p $vname 2>&1)"
  case ${full:-n} in
    n)  case "$ret" in
          *=*)          ret=p ;;
          declare\ -*)  ret=e ;;
          *)            ret=n ;;
        esac
        ;;
  esac

  echo $ret
}

#-------------------------------------------------------------------------------
# Function:     lib.netrc.validate-var-name()
# Description:  Function to list the hosts defined in the given/default env
#               var in the order that they would appear as if in a netrc
#               file i.e. 'default', if defined, is last.
# Opts:         -v STR  - specify alternate env var name, default -
#                         $Defaults[VarName]
# Args:         None
# Returns:      None
# Env Vars:     $Defaults[VarName] - $NETRC
# Notes:        * The listing is on STDOUT.
#-------------------------------------------------------------------------------
lib.netrc.validate-var-name() {
  local OPTARG OPTIND opt vname=${Defaults[VarName]}
  while getopts 'v:' opt ; do
    case $opt in
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  case "$(lib.netrc.exists -lv $vname)" in
    declare\ -A*) : ;;
    declare\ -*)  lib.console.die 127 "Var wrong type - expected '-A'" ;;
    *)            lib.console.die 127 "Var not found: '$vname'" ;;
  esac
}

#-------------------------------------------------------------------------------
# Function:     lib.netrc.ls-hosts()
# Description:  Function to list the hosts defined in the given/default env
#               var in the order that they would appear as if in a netrc
#               file i.e. 'default', if defined, is last.
# Opts:         -v STR  - specify the env var name, default -
#                         $Defaults[VarName]
# Args:         None
# Returns:      None
# Env Vars:     $Defaults[VarName] - $NETRC
# Notes:        * The listing is on STDOUT.
#-------------------------------------------------------------------------------
lib.netrc.ls-hosts() {
  local OPTARG OPTIND opt vname=${Defaults[VarName]}
  while getopts 'v:' opt ; do
    case $opt in
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  lib.netrc.validate-var-name -v $vname
  local -n var=$vname

  echo ${!var[@]} | sed '/default/s,\(.*\)default\(.*\),\1 \2 default,'
}

lib.sinclude netrc/load netrc/lookup netrc/save

#### END OF FILE
