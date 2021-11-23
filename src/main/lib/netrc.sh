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
declare -Ax ${Defaults[VarName]}

lib.console.die() {
  local rc=$1 ; case ${1//[0-9]:-y} in y) rc=$1 ; shift ;; esac
  builtin echo -e "FATAL!!! $@" >&2
  exit $rc
}

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
  local OPTARG OPTIND opt ovrwr= vname=
  while getopts 'fv:' opt ; do
    case $opt in
      f)  ovrwr=t ;;
      v)  vname=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  # 1st, see if the env var already exists and action accordingly
  case "$(declare -p $vname 2>&1)" in
    *=*)  # It exists, so action
          msg="Env var already exists: $vname"
          case ${ovrwr:-n} in
            n)  lib.console.die 127 "$msg - no overwrite" ;;
            n)  lib.console.warn "$msg - overwriting" ;;
          esac
          ;;
  esac

  # Now that's outta the way, get the specified data source name - using the
  # default as appropriate
  local fname=${1:-'-'}

  # Now determine the actual source filename - translating POSIX STDIN symbol
  # ('-') to /dev/stdin as appropriate and then normalising to a temporary
  # physical file
  local src_fname=$fname ; case "$src_fname" in
    -)            src_fname=/dev/stdin ;;
    *)            src_fname=$fname ;;
  esac

  # Now translate the output file name from '-' to /dev/stdout as appropriate
  case "$opfile" in -) opfile=/dev/stdout ;; esac

  # Now validate the existence of the actual source file
  case "$(builtin echo $src_fname*)" in
    *\*)  lib.console.die 127 "File not found: '$fname'" ;;
  esac 

  # Setup the variable to take the values - and save the defined filename
  declare -gxA $vname ; local -n var=$vname
  #var+=( [fname]="$fname" )

  local line chars=0 ; local -A entry=() ; while IFS= read line ; do
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
  done < $src_fname

  case $chars in
    0)  lib.console.warn "Empty file: '$fname'" ;;
  esac
}

#-------------------------------------------------------------------------------
# Function:     lib.netrc.validate-var-name()
# Description:  Function to list the hosts defined in the given/default env
#               var in the order that they would appear as if in a netrc
#               file i.e. 'default', if defined, is last.
# Opts:         None
# Args:         $1  - specify the env var name, default - $Defaults[VarName]
# Returns:      None
# Env Vars:     $Defaults[VarName] - $NETRC
# Notes:        * The listing is on STDOUT.
#-------------------------------------------------------------------------------
lib.netrc.validate-var-name() {
  local vname=${1:-$Defaults[VarName]}

  # Validate the var name
  local decl="$(declare -p $vname 2>&1)"

  case "$decl" in
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

  lib.netrc.validate-var-name $vname

  local -n var=$vname

  echo ${!var[@]} | sed '/default/s,\(.*\)default\(.*\),\1 \2 default,'
}

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

  lib.netrc.validate-var-name $vname

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
