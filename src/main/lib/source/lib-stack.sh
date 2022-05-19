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
# Env vars:     $BASH_UTILS_PATH     - used to supplement the callers
#                                             $PATH for "places" in which to
#                                             seek included files (when used
#                                             with relative included file
#                                             paths).
#               $BASH_UTILS_SOURCE_VERBOSE  - when set to a integer, this
#                                             determines the verbosity of file
#                                             inclusion reports where the values
#                                             are as follows...
#                                               1 - print a '.' for each file on
#                                                   successful inclusion.
#                                               2 - full ie.e. starting & done,
#                                                   reports.
#               $BASH_UTILS_SOURCE_FORCE    - this variable s/b defined as a
#                                             non-empty value in cases where a
#                                             file is, or files are, required to
#                                             be re-loaded.
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
# * The use of $BASH_UTILS_SOURCE_FORCE_LOAD should be used with great care (for
#   self-evident reasons).
# * With $BASH_UTILS_SOURCE_VERBOSE at level 2, the generated messages occur in
#   the following stages for the given scenarios....
#   * Initial load...
#     1 - 'Source: <fname>: '
#     2 - 'Source: <fname>: Starting ...'
#     3 - 'Source: <fname>: Starting ... Done'
#   * Duplicated load...
#     1 - 'Source: <fname>: '
#     2 - 'Source: <fname>: Loade#   $BASH_UTILS_SOURCE_VERBOSE at level 1...
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
# Note that the values of $BASH_UTILS_SOURCE_VERBOSE equate to the
# instrumentation _type_s in the above EBNF ...
# * 1 - cursory
# * 2 - verbose
################################################################################
# As data definitions with no initial vlaue don't affect the value of the
# variables, define the record of...
#   * The shortcuts list
#   * the totality of included files and ...
#   * the current include stack (for non-quiet announcements)
declare -a IncludeStack
declare -A Attribs=(
  [nm]=             # The library name i.e. the name by which the library was
                    # sourced
  [path]=           # The absolute path for the library - note that an empty
                    # string infimplies non-existence of the sough-after name
  [load_type]=      # The load type for this library
  [has_nested]=     # flag - set when & only when the current lib has nested
                    # lib(s) - now believed redundant
  [fnf]=fatal       # fnf error severity
  [error_code]=     # error code
  [error]=          # error report details
  [initial]=t       # flag - set iff this is the first element
  [caller_lineno]=  # caller lineno
)
declare _IncludeStack="$(declare -p Attribs)"
IncludeStack=( "${_IncludeStack/Attribs/attribs}" )
Attribs[initial]=
readonly Attribs="${_IncludeStack/Attribs/attribs}"

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.set-attribs()
# Description:  Called first for any sourced file, this routine records the
#               name, absolute path and "type" for the given library name &/or
#               path on the included stack.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.update() {
  local OPTARG OPTIND opt idx
  while getopts 'i:' opt ; do
    case $opt in
      i)  idx=$OPTARG ;;
    esac
  done

  shift $(($OPTIND - 1))

  # Get the appropriate entry into scope
  local -A attribs ; eval "${IncludeStack[${idx:-0}]}"

  # Update it
  for attrib ; do attribs[${attrib%=*}]="${attrib#*=}" ; done

  # And save it back
  IncludeStack[${idx:-0}]="$(declare -p attribs)"
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.push()
# Description:  Called first for any sourced file, this routine records the
#               given attribs for the lib and then saves them on the top of the
#               included stack.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.push() {
  : ${#IncludeStack[@]}
  # Define and pre-initialize the new entry
  eval $Attribs

  # Now load the values from the arg list
  local attrib ; for attrib ; do attribs[${attrib%=*}]="${attrib#*=}" ; done

  # Set the default absolute path to the name iff it's not already set and the
  # name is absolute
  case "${attribs[nm]}" in /*) attribs[path]="${attribs[nm]}" ;; esac

  # Finally, save the new record at the top of the included lib stack
  : ${#IncludeStack[@]}
  IncludeStack=( "$(declare -p attribs)" "${IncludeStack[@]}" )
  : ${#IncludeStack[@]}
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.lib-stack.peek()
# Description:  Routine to return the given/default element
# Takes:        $1  - optional set of attribs to return - by default, this is
#               the top set
# Returns:      The requested attrib set.
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.peek() {
  local OPTARG OPTIND opt nm
  while getopts 'n:' opt ; do
    case $opt in
      n)  nm=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  builtin echo "${IncludeStack[${1:-0}]/attribs/${nm:-attribs}}"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.lib-stack.peek()
# Description:  Routine to return the given/default element i.e. the one at the
#               top of the stack.
# Takes:        $1  - optional set of attribs to return - by default, this is
#               the current/top set
# Returns:      The requested attrib set.
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.get-attribs() {
  builtin echo "${IncludeStack[${1:-0}]}"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.lib-stack.get-attrib()
# Description:  Routine to get the set of attribs for the given/default lib.
# Takes:        -i INT  - optional index to attribs to interrogate - by default,
#                         this is the current/top set
# Args:         $1      - the name of attrib of interest
# Returns:      The requested attrib set.
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.get-attrib() {
  local OPTARG OPTIND opt idx
  while getopts 'i:' opt ; do
    case $opt in
      i)  idx=$OPTARG ;;
    esac
  done

  shift $(($OPTIND - 1))

  eval "${IncludeStack[${idx:-0}]}"
  builtin echo ${attribs[${1:?'No attrib name'}]:-}
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.pop()
# Description:  Pops the top element off the include stack - assuming that...
#               * the stack isn't empty - the caller is expected to assert this
#                 via prior call to source.lib-stack.load.announce.is-empty().
#               * if the element to be popped is of interest to the caller, then
#                 the caller has already called bash-utils.source.top() to
#                 inspect/retrieve it.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.pop() {
  : ${#IncludeStack[@]}
  case ${#IncludeStack[@]} in
    1)  echo "FATAL: Cannot call pop on an empty stack!!!" >&2  
        exit 1
        ;;
    *)  IncludeStack=( "${IncludeStack[@]:1}" ) ;;
  esac
  : ${#IncludeStack[@]}
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.pop-attribs()
# Description:  Pops the top element(s) off the include stack - assumes that if
#               if the element(s) to be popped are of interest to the caller,
#               then the caller has already called bash-utils.source.top() to
#               inspect/retrieve them.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.top() {
  : ${#IncludeStack[@]}
  builtin echo "${IncludeStack[0]/attribs/top}"
  : ${#IncludeStack[@]}
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.seek()
# Description:  Pops the top element(s) off the include stack - assumes that if
#               if the element(s) to be popped are of interest to the caller,
#               then the caller has already called bash-utils.source.top() to
#               inspect/retrieve them.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.seek() {
  local found=()
  local k="${1%=*}" v="${1#*=}"

  local e ; for e in "${IncludeStack[@]}" ; do
      eval "$e"
      case "${attribs[initial]:-}" in
        t)  break ;;
        *)  case "${attribs["$k"]}" in "$v") found+=( "$e" ) ;; esac ;;
      esac
  done

  declare -p found
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.pop-attribs()
# Description:  Pops the top element(s) off the include stack - assumes that if
#               if the element(s) to be popped are of interest to the caller,
#               then the caller has already called bash-utils.source.top() to
#               inspect/retrieve them.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.depth() {
  builtin echo $((${#IncludeStack[@]} - 1))
}

bash-utils.source.lib-stack.is-empty() {
  local ret=n ; case $(bash-utils.source.lib-stack.depth) in
    0)  ret=y ;;
  esac

  builtin echo $ret
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.report()
# Description:  Function to report the current lib stack as a string - thence to
#               be reported on the stream as required by the caller.
# Opts:         None
# Args:         $1  - optional start element, default - 0
# Returns:      A list of name & absolute path tuples (newline seperated) for
#               each lib on the current stack.
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.report() {
  local start=${1:-0}

  : ${IncludeStack[@]}
  local lib ; for lib in "${IncludeStack[@]:$start}" ; do
    case "$lib" in *Attribs*) break ;; esac
    eval $lib ; builtin echo "${attribs[nm]}:::${attribs[path]}"
  done
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.lib-stack.new-lib()
# Description:  Function to create a new entry on the stack - if it's not the
#               first then it also updates the current entry with the line
#               number at which the new file is 'called` before add ing the new
#               entry
# Opts:         None
# Args:         $1  - new element
# Returns:      None (atm).
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.lib-stack.new-lib() {
  : ${#IncludeStack[@]}
  # Define and pre-initialize the new entry
  eval $Attribs

  # Now load the values from the arg list
  local attrib ; for attrib ; do attribs[${attrib%=*}]="${attrib#*=}" ; done

  # Set the default absolute path to the name iff it's not already set and the
  # name is absolute
  case "${attribs[nm]}" in /*) attribs[path]="${attribs[nm]}" ;; esac

  # Update the current top of stack iff this isn't the 1st
  : $((0 - $(bash-utils.source.lib-stack.depth)))
  case $((0 - $(bash-utils.source.lib-stack.depth))) in
    -*) bash-utils.source.lib-stack.update \
          caller_lineno=${attribs[caller_lineno]}
        ;;
  esac

  # Ensure the caller_lineno is unset for the new entry
  unset 'atrribs[caller_lineno]'

  # Before saving the new record (at the top of the included lib stack)
  : ${#IncludeStack[@]}
  IncludeStack=( "$(declare -p attribs)" "${IncludeStack[@]}" )
  : ${#IncludeStack[@]}

}


#### END OF FILE
