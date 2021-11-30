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

#-------------------------------------------------------------------------------
# Function:     lib.netrc.verify-details()
# Description:  Function that, by wrapping calls to other functions herein,
#               provides a convenience function to implement CR & U aspects of
#               CRUD in  order to verify the given details for the given/default
#               host/end-point - optionally updating if desired.
# Opts:         -h STR  - specify an alternate host/end-point, default -
#                         'default'
#                         given/default host/end-point).
#               -n      - specify no auto-merge (of the given/default
#                         host/end-point with the default host/end-point.
#               -u STR  - specify the file for post-verification file updating,
#                         default - no update. Note that STR being an empty
#                         string causes the most recently read file to be
#                         updated. Note also that the file is updated iff
#                         changes have been made during the verification
#                         process.
#               -v STR  - specify the env var name, default - $Defaults[VarName]
# Args:         $*      - specify the deatils to verify, by default
# Returns:      None
# Env Vars:     $Defaults[VarName]    - $NETRC
#               $Defaults[AllFields]  -
# Notes:        * The details are verified on STDIN & STDOUT.
#               * By default, only the in-memory details are updated.
#               * Should post-verification update be specified, it's fatal to
#                 attempt to do so
#-------------------------------------------------------------------------------
lib.netrc.verify-details() {
  local OPTARG OPTIND opt ep=default no_mrg= vname=${Defaults[VarName]}
  while getopts 'h:nv:' opt ; do
    case $opt in
      h)  ep=$OPTARG ;;
      n)  no_mrg=t ;;
      u)  upd_file=t ;;
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  lib.netrc.validate-var-name -v $vname
  local -n var=$vname

  local changed= attr ; for attr in ${@:-${Defaults[AllFields]}} ; do
    local oldval=${var[$attr]:-${mrg:+}}

    # Ensure the password is hidden from the console
    local sw= ; case $attr in password) sw='-s' ;; esac
    local newval= ; read -p"$attr - " $sw newval

    # Do next iff no changes
    case v"${newval//$oldval}" in v) continue ;; esac

    # Change made, so reflect it as appropriate i.e. in the actual or default
    # structure
    case "${var[$attr]:-n}" in
      n)  # Undefined in the actual EP ,so musta been from the default
          defaults[$attr]=$newval
          ;;
      *)  # Otherwise, musta been the actual record itself
          var[$attr]="$newval"
          ;;
    esac

    # Now flag the change
    changed=t
  done

  # Nowt left to do if there's no changes or update is not enabled
  case ${changed:+y}:${upd_file:+y} in y:y) : ;; *) return ;; esac

  # Otherwise, do the update
  lib.netrc.save -v $vname
}

lib.sinclude netrc/load netrc/lookup netrc/save

#### END OF FILE
