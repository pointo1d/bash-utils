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

eval ${__LIB_NETRC_SAVE_SH__:-}
export __LIB_NETRC_SAVE_SH__=return

#-------------------------------------------------------------------------------
# Function:     lib.netrc.save()
# Description:  Function to save the given/default env var struct to the
#               given/default file.
# Opts:         -f      - specify force overwrite of any existing file
#               -v STR  - specify the name of the env var to save, default -
#                         Netrc
# Args:         $1  - alternate output file name, default '-' i.e. STDOUT
# Returns:      None
# Env Vars:     $NetrcDefaultFname    - $HOME/<FilePrefix>netrc
#               $Defaults[VarName] - $NETRC
# Notes:        * As per POSIX, STDOUT may be indicated by '-'.
#-------------------------------------------------------------------------------
lib.netrc.save() {
  local OPTARG OPTIND opt frc= vname=${Defaults[VarName]}
  while getopts 'fv:' opt ; do
    case $opt in
      f)  frc=t ;;
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  lib.netrc.validate-var-name -v $vname

  # Var name's valid, so is it empty ?
  local -n var=$vname ; case ${#var[@]} in
    0)  lib.console.warn "Empty struct in var: '$vname'"
        return
        ;;
  esac

  # Determine and validate, the file name - translating POSIX STDOUT ('-') to
  # '/dev/stdout' as appropriate
  local out_file="${1:--}"
  case "$out_file" in
    -)            out_file=/dev/stdout ;&
    /dev/stdout)  ;;
    *)            case "$(builtin echo $out_file*)":${frc:-n} in
                    $out_file:n)  lib.console.die \
                                  127 "File exists, no overwrite: '$out_file'"
                                  ;;
                  esac 
                  ;;
  esac

  # Var's not empty and the output file has been validated, so list the content
  # to the output file
  local host="" default="" ; for host in $(lib.netrc.ls-hosts -v $vname) ; do
    local str=""
    case $host in
      default)  str="$host" ;;
      *)        str="machine $host" ;;
    esac

    builtin echo -e "$str"

    eval local -A entry=( ${var[$host]} )
    local keyword ; for keyword in ${Defaults[AllFields]} ; do
      case ${entry[$keyword]:+y} in
        y)  builtin echo "  $keyword ${entry[$keyword]//\"/}" ;;
      esac

      # Save the default 'til last
      case "$str" in default\ *) continue ;; esac

    done

    # Generate end of record i.e. empty line
    echo
  done > $out_file

  # Finally, the default - if any ;-)
  case "${default:+y}" in y)  builtin echo "$default\n\n" >> $out_file ;; esac
}

#### END OF FILE
