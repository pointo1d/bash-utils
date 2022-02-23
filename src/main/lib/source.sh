#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         source.sh
# Description:  Pure bash(1) script to provide a recursive inclusion avoiding
#               file inclusion capability whilst providing a simpler interface
#               such that the caller need only know a directory under which the
#               sourced file exists, so for example, this file may be included
#               merely as `. source` or even the help sub-library of console
#               may be included as `. console/help` - in these casaes this is
#               because the directory containing these elements is automgically
#               included in the PATH for free.
# Doc link:     ../../../docs/source.md
# Env vars:     $SINCLUDE_PATH    - used to supplement the callers $PATH for
#                                   "places" in which to seek included files
#                                   (when used with relative included file
#                                   paths).
#               $SINCLUDE_VERBOSE - when set to a integer, this determines the
#                                   verbosity of file inclusion reports where
#                                   the values are as follows...
#                                     1 - print a '.' for each file on
#                                         successful inclusion.
#                                     2 - full ie.e. starting & done, reports.
#               $SINCLUDE_FORCE   - this variable s/b defined as a non-empty
#                                   value in cases where a file is, or files
#                                   are, required to be re-loaded.
# Notes:
# * There are a number of variables at play...
#   * The pathing - which may be...
#     * fully pathed.
#     * simple relative.
#     * complex relative.
#   * The extension which may, or may not, be present - if not present, then it
#     has to be guessed at (no file has to have an extension - and on Windoze
#     the absence of an extensiona appears to remove the execution status of the
#     file), so the 1st guess is always the extensionless file name).
# * The use of $SINCLUDE_FORCE_LOAD should be used with great care (for
#   self-evident reasons).
# * With $SINCLUDE_VERBOSE at level 2, the generated messages occur in the
#   following stages for the given scenarios....
#   follows...
#   * Initial load...
#     1 - 'Source: <fname>: '
#     2 - 'Source: <fname>: Starting ...'
#     3 - 'Source: <fname>: Starting ... Done'
#   * Duplicated load...
#     1 - 'Source: <fname>: '
#     2 - 'Source: <fname>: Loaded'
#   $SINCLUDE_VERBOSE at level 1...
#   * Initial load...
#     1 - '.'
#   * Duplicated load...
#     1 - ''
#
#   Each inclusion needs 2 record updates - one each for the...
#     * Recursive inclusion avoidance record - `Included'
#     * Announcement stack - 'IncludeStack` - to ensure correct output when
#       verbally reporting - specifically to cater for nested inclusion.
#
# When enabled, instrumentation reporting is defined by the following EBNF...
#   report            = ? new line ? , ( cursory | verbose ) ;
#   cursory           = simple cursory | nested cursory ;
#   simple cursory    = simple begin | simple end | simple no action ;
#   nested cursory    = simple cursory { simple cursory } ;
#   simple begin      = "." ;
#   simple end        = "." ;
#   simple no action  = "" ;
#   verbose           = simple verbose | nested verbose ;
#   simple verbose    = body , start msg , end msg ;
#   nested verbose    = body , start msg , report , { report } , end msg ;
#   body              = "Source:" , lib details ;
#   lib details       = abs msg | rel msg ;
#   abs msg           = "'" abs path "'" ;
#   rel msg           = "'" lib name "'" , "(" abs lib ")" ;
#   begin msg         = begin action | no begin action ;
#   begin action      = "- " , ( "Starting" | "Reloading" ) , "..." ;
#   no begin action   = "" ;
#   end msg           = "Done" | "Already loaded" ;
#
# Note that the values of $SINCLUDE_VERBOSE equate to the instrumentation
# _type_s in the above EBNF ...
# * 1 - cursory
# * 2 - verbose
################################################################################

# As data definitions with no initial vlaue don't affect the value of the
# variables, define the record of...
#   * the totality of included files and ...
#   * the current include stack (for non-quiet announcements)
declare -A Included ; declare -a IncludeStack
declare FirstPass=$(type -t source) ; case "${FirstPass//function}" in
  builtin)  FirstPass=t
            declare -A attrs
            attrs=( [abs]='' [nm]='' [type]='' [has_nested]='' )
            IncludeStack=( "$(declare -p attrs)" )
            ;;
  *)        FirstPass= ;;
esac
: "${#IncludeStack[@]} - ${IncludeStack[@]}"

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.warning()
# Description:  Simple routine to report the given message, as a warning,
#               irrespective of the ruling verbosity.
# Takes:        $*  - the message to report
# Returns:      0 always
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.source.warning() { builtin echo -e "WARNING !!! $@" >&2 ; }

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.fatal()
# Description:  Simple routine to report the given message as a fatal error -
#               irrespective of the ruling verbosity.
# Takes:        $1  - either required rc or the first token in the message to
#                     report
#               $*  - the rest of the message to report
# Returns:      Never - message reported to STDOUT, exit with default (1)/given
#               rc
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.source.fatal() {
  # Extract the posited return code - if any
  local rc=1 ; case i"${1//[0-9]}" in i) rc=$1 ; shift ;; esac

  # Now make the report and exit with the given code
  builtin echo -e "FATAL !!! $@" >&2 ; exit $rc
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.is-abs-path()
# Description:  Routine to take a path and determined if it's an absolute path.
# Takes:        $1  - path.
#               $2  - if given, specifies that a non-absolute path is fatal.
# Returns:      Updated STDOUT - 'y' iff the given path is absolue, 'n'
#               otherwise.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.source.is-abs-path() {
  local ret=n ; case "${1:?'No path to test'}" in /*) ret=y ;; esac
  case $ret:${2:-n} in
    n:n)  ;;
    n:*)  bash-utils.source.fatal "Path isn't absolute: '$1'" ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.abs-path()
# Description:  Routine to take a path and return its fully pathed equivalent.
# Takes:        $1  - path.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.source.abs-path() {
  case "${1:?'No path to convert'}" in
    /*)   builtin echo $1 ;;
    */*)  ( cd ${1%/*}>/dev/null && builtin echo $PWD/${1##*/} ) ;;
    *)    builtin echo $PWD/$1 ;;
  esac
}

# File global containing the absolute path to self
declare Pself="$(bash-utils.source.abs-path $BASH_SOURCE)"

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.is-loaded()
# Description:  Routine to determine if the given path has already been loaded.
# Takes:        $1  - absolute path, fatal if not.
# Returns:      Updated STDOUT - 'y' iff the given path has already been
#               loaded, 'n' otherwise.
# Variables:    $Included.
# ------------------------------------------------------------------------------
bash-utils.source.is-loaded() {
  bash-utils.source.is-abs-path ${1:?'No lib path to test'} t

: ${!Included[@]}, ${Included["$1"]:+y}
  local ret=n ; case ${Included["$1"]:+y} in y) ret=y ;; esac
  builtin echo $ret
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.msg()
# Description:  Simple routine to report the given message to STDOUT - dependant
#               on the ruling verbosity.
# Takes:        $*  - the message to report
# Returns:      0 always
# Variables:    $SINCLUDE_VERBOSE - defines the ruling verbosity level for
#                                   message reporting
# ------------------------------------------------------------------------------
bash-utils.source.announce.msg() {
  case ${SINCLUDE_VERBOSE:-n} in 1|2) builtin echo -e "$@" ;; esac
}

# ------------------------------------------------------------------------------
# Function:     source.load.announce.msg-body()
# Description:  As it says on the tin - selectively generates the appropriate
#               file loading/source 'ing message.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed equivalent of the given lib name
#               $3  - string to replace the default '.' when reporting in
#                     cursory level
# Returns:      The generated string on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
bash-utils.source.announce.msg-body() {
  #local nm=${1:?'No name'}
  #bash-utils.source.is-abs-path "$2" t ; local abs="$2"
  local -A attrs ; eval $(bash-utils.source.announce.get-attrs)

  : ${attrs[type]}:${SINCLUDE_VERBOSE:-n}
  local hdr=() ; case ${attrs[type]}:${SINCLUDE_VERBOSE:-n} in
    *:0|*:n|\
    noload:1)   return ;;
    *:1)        hdr=( "${3:-.}" ) ;;
    *:2)        hdr=( 'Source:' ) ; case "${attrs[nm]}" in
                  ${attrs[abs]})  hdr+=( "'${attrs[abs]}'" ) ;;
                  *)              hdr+=( "'${attrs[nm]}' ('${attrs[abs]}')" ) ;;
                esac
                ;;
  esac
  
  bash-utils.source.announce.msg "${hdr[@]}\c"
}

# ------------------------------------------------------------------------------
# Function:     source.load.announce.add-lib()
# Description:  Called first for any sourced file, this routine records the
#               name, absolute path and "type" for the given library name &/or
#               path on the included stack.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.announce.add-lib() {
  local nm=${1:?'No name'}
  bash-utils.source.is-abs-path "$2" t

  # Perform recursive inclusion detection before doing anything else
  local entry ; for entry in "${!IncludeStack[@]}" ; do
    local -A attrs ; eval ${IncludeStack[$entry]}
    case ${attrs[abs]} in
      "$2") local imm=Direct ; case $entry in 0) ;; *) imm=Indirect ;; esac
            bash-utils.source.fatal "$imm recursive inclusion detected in '$2'"
            ;;
    esac
  done

  local type=$(bash-utils.source.is-loaded "$2"):${SINCLUDE_RELOAD:-n}
  case $type in
    n:*)  # not (yet) loaded, reload immaterial
          type=load
          ;;
    y:n)  # loaded & reload forced
          type=noload
          ;;
    y:*)  # loaded & reload forced
          type=reload
          ;;
  esac

  # Save the actual path irrespective of verbosity (might be needed later for
  # error reporting purposes)
  local -A attrs
  : ${#IncludeStack[@]}
  case ${#IncludeStack[@]} in
    1)  ;;
    *)  eval ${IncludeStack[0]}
        attrs[has_nested]=t
        IncludeStack[0]="$(declare -p attrs)"
        case ${SINCLUDE_VERBOSE:-} in 2) bash-utils.source.announce.msg ;; esac
        ;;
    esac

  attrs=( [nm]="$nm" [abs]="$2" [type]="${type}" )
  IncludeStack=( "$(declare -p attrs)" "${IncludeStack[@]}" )
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.new-line()
# Description:  Routine to be called prior to generating a report whose purpose
#               is to determine if a newline is required and if so, generate one
#               on STDOUT. The determination of whether, or not, one is needed
#               is any of the following, verbosity specific, conditions are
#               met...
#               2 -
#                 * A non-nested file is to be sourced.
#                 * A nested file is to be sourced.
#               1 -
#                 * A new, non-nested, file is to be sourced.
# Takes:        None.
# Returns:      <CR><NL> on STDOUT iff necessary
# ------------------------------------------------------------------------------
bash-utils.source.announce.new-line() {
  : ${IncludeStack[@]}
  local -A attrs ; eval $(bash-utils.source.announce.get-attrs)
  local cond=${FirstPass:-}:${SINCLUDE_VERBOSE:-}:${attrs[has_nested]:-}:${#IncludeStack[@]}

  case $cond in
    t:*|\
    :1::1|\
    :2:t:*)   bash-utils.source.announce.msg ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.get-attrs()
# Description:  Routine to get the set of attribs for the given/default lib.
# Takes:        $1  - optional set of attribs to return - by default, this is
#               the current/top set
# Returns:      The requested attrib set.
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.announce.get-attrs() {
  local ret="${IncludeStack[${pos:-0}]}"
  #case "$ret" in
  #  0)  bash-utils.source.fatal "Cannot return the last element" ;;
  #esac

  builtin echo "$ret"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.load-action()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
bash-utils.source.announce.load-action() {
  local nm="${1:?'No lib name'}" abs="${2:-$1}"
  bash-utils.source.announce.new-line

  bash-utils.source.announce.add-lib "$nm" "$abs"
  
  bash-utils.source.announce.msg-body "$nm" "$abs" #la
  local -A attrs ; eval $(bash-utils.source.announce.get-attrs)

  local type= msg= ; case ${SINCLUDE_VERBOSE:-n}:${attrs[type]} in
    2:load)   msg=" - Starting ..." ;;
    2:reload) msg=" - Reloading ..." ;;
  esac

  # Update the inclusion record
  Included["$abs"]=t

  case "${msg:-n}" in n) return ;; esac

  bash-utils.source.announce.msg "$msg\c"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.load-done()
# Description:  As it says on the tin - selectively reports the file load/source
#               done event.
# Takes:        none
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
bash-utils.source.announce.load-done() {
  : ${IncludeStack[@]}
  local msg=
  local -A attrs ; eval $(bash-utils.source.announce.get-attrs)
  : ${IncludeStack[@]}

  local cont=${attrs[type]}:${SINCLUDE_VERBOSE:-n}:${attrs[has_nested]:-}
  case $cont in
    noload:1:*) ;;
    noload:2:*) bash-utils.source.announce.msg " - Already loaded" ;;
    *:1:*)      bash-utils.source.announce.msg "${1:-.}\c" ;;
    *:2:t)      bash-utils.source.announce.msg-body "${attrs[nm]}" "${attrs[abs]}"
                bash-utils.source.announce.msg " -\c"
                ;&
    *:2:*)      bash-utils.source.announce.msg " Done" ;;
  esac

  : ${#IncludeStack[@]} - ${#IncludeStack[@]}
  case ${#IncludeStack[@]} in
    1)  ;;
    *)  IncludeStack=( "${IncludeStack[@]:1}" ) ;;
  esac
  : ${#IncludeStack[@]} - ${IncludeStack[@]}
}

bash-utils.source.announce.load-action "$BASH_SOURCE" "$Pself"

# ------------------------------------------------------------------------------
# Function:     bash-utils.source()
# Description:  Function to override the core '.' command
# Opts:         None
# Args:         $*  - one, or more, libraries - each of which specified as one
#                     of the following (for each of which omitting the file
#                     extension e.g. '.sh' isn't an option) ...
#                     * fully i.e. absolutely, pathed files in this case.
#                     * relatively pathed - In this case, the default libraries
#                       c/w the/ any supplemental directories are searched for
#                       the library name (with '.sh' appended)
#                     * a simple library name i.e. the basename. In this case,
#                       the default libraries + the/any supplemental directories
#                       are searched for the library name (as specified).
# Returns:      Iff the library is found and can be loaded.
# Returns:      0 iff all files were included successfully
# Variables:    $IncludeStack - sl0ee above :-)
#               $SINCLUDE_PATH    - supplementary path(s) to prepend to $PATH
#                                   before attempting to load the given file(s).
#               $SINCLUDE_VERBOSE - run verbosely i.e. report loading & loaded
#                                   messages
# Notes:        * The 'bin' & 'lib' subdirectories of the repository containing
#                 this script are auto-magically prepended to SINCLUDE_PATH
#                 itself.
#               * There are 3 use cases...
#                 * A fully pathed file.
#                 * A simple file name (for which the shell can be used to
#                   detect).
#                 * A complex file name i.e. a relative path to a file which the
#                   shell cannot be used to validate since the shell considers
#                   anything other than the above to actually be a relative path
#                   to a file, so must be searched for.
#
#
#
#
# .|source <file>       - PATH + dir(<file>)
# .|source <dir>/<file> - PATH + dir(<file>)/<dir>
# .|source <abs path>   - N/A
# ------------------------------------------------------------------------------
bash-utils.source() {
  case $# in 0) bash-utils.source.fatal 'Nothing to load/include' ;; esac

  # Before anything else, append the bash-utils bin & lib subdirectories in this
  # repository to SINCLUDE_PATH
  local dself=${Pself%/*}
  SINCLUDE_PATH="${SINCLUDE_PATH:+$SINCLUDE_PATH:}$dself:${dself%/lib}/bin"

  : "$# - $@"
  local lib nm dir fqlib ; for lib in ${@:?'No library'} ; do
    # Determine the callers directory and prepend SINCLUDE_PATH with it
    local callers_dir=1 # Assume direct call
    # Update the caller index iff not direct
    case ${FUNCNAME[1]} in source|.) callers_dir=2 ;; esac

    callers_dir="${BASH_SOURCE[$callers_dir]%/*}"
    callers_dir="$(bash-utils.source.abs-path $callers_dir)"
    : $callers_dir, $PWD, $lib
    
    # Now selectively attempt to find the lib name - using the included files
    # name/path
    local fqlib= ; case "$lib" in
      /*)   # Absolutely pathed, so nowt else to do other than record it
            fqlib="$lib"
            ;;
      */*)  # Relative to the callers path, so iterate thro' SINCLUDE_PATH and
            # then, possibly, PATH itself
            local all_paths="$callers_dir:$PWD:$PATH"
            while read fqlib ; do
              : $fqlib, $lib
              fqlib="$fqlib/$lib"

              case "$(builtin echo $fqlib*)" in $fqlib) break ;; esac
            done < <(builtin echo -e ${all_paths//:/\\n})

            : ${fqlib:-unset}
            ;;
      *)    # Completely relative, so nowt else to do since the containing
            # directory MUST be on the PATH, accordingly prefix a local copy of
            # it ($PATH) it with $SINCLUDE_PATH
            local PATH=${SINCLUDE_PATH:+$SINCLUDE_PATH:}$PATH
            fqlib="$lib"
            ;;
    esac

    # All ready to go, so announce it
    bash-utils.source.announce.load-action "$lib" "$fqlib"

    case "$(builtin echo ${fqlib:-}*)" in
      *\*)  case ${FUNCNAME[1]} in
              *.ifsource) case ${SINCLUDE_VERBOSE:-n} in
                            2)  bash-utils.source.announce.msg " Not found" ;;
                          esac

                          continue
                          ;;
              *)          bash-utils.source.fatal \
                            "File not found: '$lib' - '${fqlib:-unset}'"
                          ;;
            esac
            ;;
    esac

    # Load it as required i.e. iff (re)loading
    local -A attrs ; eval $(bash-utils.source.announce.get-attrs)
    case ${attrs[type]} in load|reload) builtin . $fqlib ;; esac

    # Now announce completion
    bash-utils.source.announce.load-done #"$fqlib "
  done
}

bash-utils.ifsource() { bash-utils.source $@ ; }

# ------------------------------------------------------------------------------
# Function:     .()
# Description:  Function to override the core '.' command
# Opts:         None
# Args:         $*  - one, or more, libraries - each of which specified as one
#                     of the following...
#                     * fully i.e. absolutely, pathed files (must be a full spec
#                       i.e. omitting '.sh' isn't an option in this case.
#                     * relatively pathed - which may, or may not, have '.sh'
#                       appended. In this case, the default libraries c/w
#                       the/ any supplemental directories are searched for the
#                       library name (with '.sh' appended)
#                     * a simple library name i.e. the basename, again with, or
#                       without, '.sh' appended. In this case, the default
#                       libraries + the/any supplemental directories are
#                       searched for the library name (with '.sh' appended).
# Returns:      Iff the library is found and can be loaded.
# Returns:      0 iff all files were included successfully
# Variables:    $IncludeStack - see above :-)
#               $SINCLUDE_PATH    - supplementary path(s) to prepend to $PATH
#                                   before attempting to load the given file(s).
#               $SINCLUDE_VERBOSE - run verbosely i.e. report loading & loaded
#                                   messages
# Notes:        The directory containing this script is auto-added to PATH
#               itself.
# ------------------------------------------------------------------------------
.() { bash-utils.source $@ ; }

# ------------------------------------------------------------------------------
# Function:     .()
# Description:  Function to override the core 'source' command (by calling the
#               overridden '.' command :-)
# Opts:         None
# Args:         $*  -  one, or more, files to include
# Returns:      0 iff all files were included successfully
# Variables:    $IncludeStack - see above :-)
# ------------------------------------------------------------------------------
source() { bash-utils.source $@ ; }

# Reset the first pass flag
unset FirstPass

# Ensure the loaded message is generated for this lib (if appropriate)
bash-utils.source.announce.load-done #fl

# Before including the/any given files
: "$# - '$@'"
declare incl ; for incl in $@ ; do . $incl ; done

:

#### END OF FILE
