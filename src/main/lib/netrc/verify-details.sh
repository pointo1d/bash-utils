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

eval ${__LIB_NETRC_VERIFY_DETAILS_SH__:-}
export __LIB_NETRC_VERIFY_DETAILS_SH__=return

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

#### END OF FILE
