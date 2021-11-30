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

eval ${__LIB_NETRC_LOAD_SH__:-}
export __LIB_NETRC_LOAD_SH__=return

#-------------------------------------------------------------------------------
# Function:     lib.netrc.load()
# Description:  Function to load the given/default posited netrc file where any
#               loading problems, other than an empty file, are fatal and the
#               loaded (& parsed) data is used to populate given environment
#               assoc. array variable.
# Opts:         -f      - specify overwrite of existing env var - effectively
#                         converting the fatal error to a non-fatal warning.
#               -v STR  - specify the name of the assoc. array variable,
#                         default $Defaults[VarName] (see below)- 
# Args:         $1  - optional data source, if not given, then STDIN is assumed.
# Returns:      0 if the data was parsed and loaded into the given/default
#               variable, fatal otherwise. Note that an empty data source is not
#               fatal.
# Env Vars:     $NetrcDefaultFname    - $HOME/<FilePrefix>netrc
#               $Defaults[VarName] - $NETRC
# Notes:        * As per POSIX, STDIN may be indicated by '-'.
#               * Hote that an attempt to overwrite a pre-existing envirnoment
#                 variable fo the same name is fata if not forced i.e. using
#                 '-f'
#-------------------------------------------------------------------------------
lib.netrc.load() {
  local OPTARG OPTIND opt ovrwr= vname=${Defaults[VarName]}
  while getopts 'fv:' opt ; do
    case $opt in
      f)  ovrwr=t ;;
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  # Now that's outta the way, get the specified data source name - using the
  # default as appropriate
  local fname=${1:-'-'}

  # Now determine the actual source filename - translating POSIX STDIN symbol
  # ('-') to /dev/stdin as appropriate and then normalising to a temporary
  # physical file
  local in_file=$fname ; case "$in_file" in
    -) in_file=/dev/stdin ;;
    *) in_file=$fname ;;
  esac

  # Validate the existence of the source file
  case "$(builtin echo $in_file*)" in
    *\*)  lib.console.die 127 "File not found: '$fname'" ;;
  esac 

  # Now read the file in its entirety
  local content ; mapfile content -t < $in_file

  case ${#content[@]} in
    0)  lib.console.warn "Empty file: '$fname'" ;;
  esac

  # Now see if the env var already exists and action accordingly
  case "$(lib.netrc.exists -v $vname)" in
    y)  # It exists, so action
        msg="Env var already exists: $vname"

        case ${ovrwr:-n} in
          n)  lib.console.die 127 "$msg - no overwrite" ;;
          n)  lib.console.warn "$msg - overwriting" ;;
        esac
        ;;
  esac

  # Setup the variable to take the values
  declare -gxA $vname ; local -n var=$vname

  local line chars=0 ; local -A entry=() ; for line in "${content[@]}" ; do
    : ${line:-}
    chars=$((chars + ${#line}))

    # Load & split the current line
    case "${line:-MT}" in
      MT)   # Empty line - which, if there's a record definition in
            # progress, delineates the end of the record
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
                        MT)       var+=(
                                    [$host]="$(declare -p entry |
                                      sed 's,.*(\([^)]*\) ).*,\1,')"
                                  )
                          ;;
              esac
            done
    esac
  done
}

#### END OF FILE
