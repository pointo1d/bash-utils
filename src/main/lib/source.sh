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
#               There are 2 aspects to multiple inclusion of the same file:
#               * reload    - the file has loaded successfully and needs to be
#                             reloaded (usually due to the same file being
#                             included from different files) at separate times.
#               * recursion - the same file is included either directly (it
#                             includes itself - all too easily accomplished) or
#                             indirectly (it includes one, or more, other
#                             files, which then include the initial file) during
#                             a single load sequence.
# Doc link:     ../../../docs/source.md
# Env vars:     $BASH_UTILS_PATH     - used to supplement the callers
#                                             $PATH for "places" in which to
#                                             seek included files (when used
#                                             with relative included file
#                                             paths).
#               $BASH_UTILS_SOURCE_ENH_REPORT  - when set to a integer, this
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
# * With $BASH_UTILS_SOURCE_ENH_REPORT at level 2, the generated messages occur in
#   the following stages for the given scenarios....
#   * Initial load...
#     1 - 'Source: <fname>: '
#     2 - 'Source: <fname>: Starting ...'
#     3 - 'Source: <fname>: Starting ... Done'
#   * Duplicated load...
#     1 - 'Source: <fname>: '
#     2 - 'Source: <fname>: Loaded'
#   $BASH_UTILS_SOURCE_ENH_REPORT at level 1...
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
# Note that the values of $BASH_UTILS_SOURCE_ENH_REPORT equate to the
# instrumentation _type_s in the above EBNF ...
# * 1 - cursory
# * 2 - verbose
################################################################################
# As data definitions with no initial vlaue don't affect the value of the
# variables, define the record of...
#   * The shortcuts list
#   * the totality of included files and ...
#   * the current include stack (for non-quiet announcements)
: $@
declare -A BASH_UTILS_SOURCE_SHORTCUTS ; declare -A Included
declare Dependants

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.add-shortcut()
# Description:  Routine to add the given short cut, having checked its existence
# Options:      None (atm)
# Arguments:    <nm>'='<path>'  - a name-value pair specifying a shortcut name
#                                 c/w path to which it refers.
# Returns:      Iff the given path exists
# Variables:    $BASH_UTILS_SOURCE_SHORTCUTS.
# ------------------------------------------------------------------------------
bash-utils.source.fatal-error() {
  local rc ; case "r${1//[0-9]}" in r) rc=$1 ; shift ;; esac
  builtin echo -e "\n${*:-}" >&2
  case ${BASH_UTILS_SOURCE_ENHANCED_ERROR:-n} in
    n)  : ;;
    *)  # Enhanced error reporting enabled, so enhance it (the error)
        ;;
  esac

  # Finally, eixt using given/default rc
  exit ${rc:-1}
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.format-nm-path()
# Description:  Simple routine to report the given message to STDOUT - dependant
#               on the ruling verbosity.
# Takes:        $*  - the message to report
# Returns:      0 always
# Variables:    $BASH_UTILS_SOURCE_ENH_REPORT - defines the ruling verbosity
#                                               level for message reporting
# ------------------------------------------------------------------------------
bash-utils.source.announce.format-nm-path() {
  local nm="${1:-$BASH_SOURCE}" abs="${2:-$PSELF}"
  local out ; case "$nm" in
    "${abs:-}") : ;;
    *)          case "${abs:-n}" in n) : ;; *) out=" ($abs)" ;; esac ;;
  esac

  echo "$nm${out:-}"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.detect-self-load()
# Description:  Routine to add the given short cut, having checked its existence
# Options:      None (atm)
# Arguments:    <nm>'='<path>'  - a name-value pair specifying a shortcut name
#                                 c/w path to which it refers.
# Returns:      Iff the given path exists
# Variables:    $BASH_UTILS_SOURCE_SHORTCUTS.
# ------------------------------------------------------------------------------
bash-utils.source.detect-self-load() {
  eval "${@// /\\ }"

  : ${BASH_SOURCE[*]:2}
  case "${BASH_SOURCE[*]:2}" in
    *"$path"*)
      local nm_path="$(bash-utils.source.announce.format-nm-path)"
      bash-utils.source.fatal-error \
        "$file: line $lineno: $nm_path cannot load itself, use builtin(1)"
      ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.detect-recursive-load()
# Description:  Function to detect a recursive load attempt and generate a fatal
#               error if so.
# Opts:         None
# Args:         named args...
#               path    - the path being attempted
#               file    - the file making the attempt
#               lineno  - the line number in the file at which the attempt is
#                         being made
# ------------------------------------------------------------------------------
bash-utils.source.detect-recursive-load() {
  eval "${@// /\\ }"
  
  # First establish if it's an attempt at a recursive load - use an internal
  # loaded record since BASH_SOURCE can't be relied on - it appears to be
  # updated as soon as a file load starts
  eval $(bash-utils.source.lib-stack.seek path="$path")

  : ${IncludeStack[@]}
  # Return early if the posited file isn't on the stack
  case ${#found[@]} in 0) return ;; esac

  # Otherwise attempt to classify it - as either direct (self -> self) or
  # indirect (self -> other -> self)
  local depth=$(bash-utils.source.lib-stack.depth) el ind
  for ((el=0 ; el<depth ; el++)) ; do
    # Get the next entry
    eval $(bash-utils.source.lib-stack.peek $el)

    # Finished when the current entry is for the given path
    case "${attribs[path]}" in "$path") break ;; esac
  done

  case $el in 0) ;; *) ind='indirect ' ;; esac

  bash-utils.source.fatal-error \
    "$path: line $lineno: ${ind:-}source recursion detected"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.add-shortcut()
# Description:  Routine to add the given short cut, having checked its existence
# Options:      None (atm)
# Arguments:    <nm>'='<path>'  - a name-value pair specifying a shortcut name
#                                 c/w path to which it refers.
# Returns:      Iff the given path exists
# Variables:    $BASH_UTILS_SOURCE_SHORTCUTS.
# ------------------------------------------------------------------------------
bash-utils.source.report-self-load() {
  eval "${@// /\\ }"

  local msg="$(bash-utils.source.announce.format-nm-path "$nm" "$path")"

  bash-utils.source.fatal-error \
    "$file: line $lineno: $msg cannot load itself, use builtin(1)"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.add-shortcut()
# Description:  Routine to add the given short cut, having checked its existence
# Options:      None (atm)
# Arguments:    <nm>'='<path>'  - a name-value pair specifying a shortcut name
#                                 c/w path to which it refers.
# Returns:      Iff the given path exists
# Variables:    $BASH_UTILS_SOURCE_SHORTCUTS.
# ------------------------------------------------------------------------------
bash-utils.source.add-shortcut() {
  local nm="${1%=*}" path="${1##*=}"

  case "$(builtin echo "$path"*)" in
    "$path"*) BASH_UTILS_SOURCE_SHORTCUTS["$nm"]="$path" ;;
    *)        bash-utils.source.fatal-error "shortcut path not found: '$path'"
              ;;
  esac
}

case $(type -t source) in
  builtin)  # Do the first pass stuff - start with the self globals
            # File global containing the absolute path to self
            declare DSELF="$(cd ${BASH_SOURCE%/*} >/dev/null && builtin echo $PWD)"
            declare PSELF="$DSELF/${BASH_SOURCE##*/}" FIRST_PASS=t

            # Declare & load the dependencies
            Dependants=(
              "${BASH_SOURCE%.sh}/lib-stack.sh"
            )

            declare lib ; for lib in ${Dependants[@]} ; do
              declare abs="$(cd ${lib%/*}>/dev/null && builtin echo $PWD)"
              builtin . "$lib"
              Included["$abs/${lib##*/}"]="$lib"
              case "$lib" in
                */lib-stack.sh) # All dependencies loaded, so use them to
                                # attempt to record self-loading - start with
                                # the caller
                                : ${FUNCNAME[@]}
                                : ${BASH_SOURCE[@]}
                                : ${BASH_LINENO[@]}
                                declare caller=( $(caller 0) )

                                bash-utils.source.lib-stack.new-lib \
                                  nm="${BASH_SOURCE[1]}" 
                                  path="${BASH_SOURCE[1]}" load_type=load                                  
                                # Now go on to self
                                bash-utils.source.lib-stack.new-lib \
                                  nm="$BASH_SOURCE" path="$PSELF" \
                                  load_type=load \
                                  caller_lineno="${BASH_LINENO[0]}"
                                ;;
              esac
            done

            bash-utils.source.add-shortcut "bash-utils="$DSELF""
            ;;
  function) bash-utils.source.report-self-load \
              nm="$BASH_SOURCE" path="$PSELF" \
              file="${BASH_SOURCE[1]}" lineno="${BASH_LINENO[0]}"
            ;;
esac

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.is-loaded()
# Description:  Routine to determine if the given path has been loaded during
#               the current onvocation & make a 'y'/'n' report accordingly.
# Takes:        $1  - absolute path.
# Returns:      Updated STDOUT - 'y' iff the given path has already been
#               loaded, 'n' otherwise.
# Variables:    $IncludeStack.
# ------------------------------------------------------------------------------
bash-utils.source.is-loaded() {
  local ret ; case "${1:-n}" in
    n)  ret=n ;;
    *)  #eval "$(bash-utils.source.lib-stack.seek path="$1")"

        #case "${#found[@]}" in
        case "${Included[@]}" in
#          0) : ;;
#          *) ret=y ;;
          *"$path"*)  ret=y ;;
        esac
        ;;
  esac

  builtin echo ${ret:-n}
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.msg()
# Description:  Simple routine to report the given message to STDOUT - dependant
#               on the ruling verbosity.
# Takes:        $*  - the message to report
# Returns:      0 always
# Variables:    $BASH_UTILS_SOURCE_ENH_REPORT - defines the ruling verbosity level for
#                                   message reporting
# ------------------------------------------------------------------------------
bash-utils.source.announce.msg() {
  case ${BASH_UTILS_SOURCE_ENH_REPORT:-n} in 1|2) builtin echo -e "$@" ;; esac
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
# Variables:    $BASH_UTILS_SOURCE_ENH_REPORT
# ------------------------------------------------------------------------------
bash-utils.source.announce.msg-body() {
  eval $(bash-utils.source.lib-stack.get-attribs)

  local hdr=() ; case ${attribs[load_type]}:${BASH_UTILS_SOURCE_ENH_REPORT:-n} in
    *:0|*:n|\
    *:1)   return ;;
    #*:1)        hdr=( "${3:-.}" ) ;;
    *:2)        hdr=(
                  'Source:' 
                  $(
                    bash-utils.source.announce.format-nm-path \
                      "${attribs[nm]}" "${attribs[path]}"
                  )
                )
                ;;
  esac
  
  # shellcheck disable=SC2145
  bash-utils.source.announce.msg "${hdr[@]}\c"
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
  local cond=${FIRST_PASS:-}:${BASH_UTILS_SOURCE_ENH_REPORT:-}:$(bash-utils.source.lib-stack.get-attrib has_nested):$(bash-utils.source.lib-stack.depth)

  case $cond in
    t:*|\
    :1::1|\
    :2:t:*)   bash-utils.source.announce.msg ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.fatal-error()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $BASH_UTILS_SOURCE_ENH_REPORT
# ------------------------------------------------------------------------------
bash-utils.source.announce.fatal-error() {
  local d=${#IncludeStack[@]}
  local e ; for ((e=0 ; e < d ; e+=1)) ; do
    : "$e - ${IncludeStack[$e]}"
  done
  local level depth=$(bash-utils.source.lib-stack.depth) str=''
  for ((level=0 ; level < depth ; level+=1)); do
    local _curr="$(bash-utils.source.lib-stack.peek -n curr $level)" \
          _next="$(bash-utils.source.lib-stack.peek -n next $((level+1)))"
    eval $_curr

    local nm_path="$(bash-utils.source.announce.format-nm-path "${curr[nm]}" "${curr[path]}")"

    case $level in
      0)  # 1st line of report
          str="$nm_path: $*"

          # Done iff enhanced error reporting isn't enabled
          case ${BASH_UTILS_SOURCE_ENHANCED_ERROR:-n} in n) break ;; esac
          ;;
      *)  # Otherwise generate next line of report
          eval $_next
          str+="\nIn ${curr[path]}: line ${curr[caller_lineno]}"
          _curr="$_next"
          ;;
    esac
  done

  : "${str:-}"

  bash-utils.source.fatal-error "$str"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.report-fnf-error()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $BASH_UTILS_SOURCE_ENH_REPORT
# ------------------------------------------------------------------------------
bash-utils.source.announce.report-fnf-error() {
  eval $(bash-utils.source.lib-stack.get-attribs)
  local nm_path="$(bash-utils.source.announce.format-nm-path "${attribs[nm]}" "${attribs[path]}")"
  local level=0 depth=$(bash-utils.source.lib-stack.depth)
  while true ; do
    case $((level-depth)) in
      -*|0) eval $(bash-utils.source.lib-stack.peek $level)
            : $((level+=1))
            ;;
    esac
  done

  exit 22

  local desc='' lib depth=2 ; while read lib ; do
    local path="${lib##*:::}" nm="${lib%%:::*}"
    nm="$(bash-utils.source.announce.format-nm-path "$nm" "$path")"

    desc="$desc$(printf "%${depth}sSourced by '%s'%s\\\n" ' ' "$path" "$nm")"
    : $((depth+=2))
  done < <(bash-utils.source.lib-stack.report 1)

  bash-utils.source.announce.fatal-error \
    ${desc:+-D"$desc"} "Path not found - '${attribs[path]}'"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.load-action()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event ... after 1st determining the reload status.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $BASH_UTILS_SOURCE_ENH_REPORT
# ------------------------------------------------------------------------------
bash-utils.source.announce.load-action() {
  eval $(bash-utils.source.lib-stack.top)
  local nm="${top[nm]}" path="${top[path]}"

  case ${top[error_code]:-n} in
    n)  # No error, nowt to worry about
        ;;
    *)  # Error of some sort, so handle the special case(s) accordingly
        local str ; case ${top[error_code]:-n} in
          n)    : ;;
          fnf)  # File not found error, so determine how to handle it depending
                # on whether it's fatal or permissive
                case ${top[fnf]:-} in
                  perm)   ;;
                  fatal)  str="source(1) target file not found" ;;
                esac
                ;;
          *)    str="${top[error]}" ;;
        esac

        case "${str:-n}" in
          n)  ;;
          *)  bash-utils.source.announce.fatal-error "$str" ;;
        esac
        ;;
  esac
  
  # Determine the attempted load `type'
  # shellcheck disable=SC2155
  local load_type ; case "${top[path]:-n}" in
    n)  load_type=noload ;;
    *)  : ${Included[@]}
        load_type=$(bash-utils.source.is-loaded "${path:-}"):${BASH_UTILS_SOURCE_RELOAD:-n}
        case $load_type in
          n:*)  load_type=load ;;
          y:n)  load_type=noload ;;
          y:*)  load_type=reload ;;
        esac
        ;;
  esac

  bash-utils.source.lib-stack.update load_type=$load_type

  bash-utils.source.announce.new-line

  bash-utils.source.announce.msg-body

  local type msg cont=${BASH_UTILS_SOURCE_ENH_REPORT:-n}:$load_type
  case $cont in
    2:load)   msg=" - Starting ..." ;;
    2:reload) msg=" - Reloading ..." ;;
    *)        return ;;
  esac

  bash-utils.source.announce.msg "$msg\c"
}

# shellcheck disable=SC2128
bash-utils.source.announce.load-action

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.load-done()
# Description:  As it says on the tin - selectively reports the file load/source
#               done event.
# Takes:        $1  - optional not found flag
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $BASH_UTILS_SOURCE_ENH_REPORT
# ------------------------------------------------------------------------------
bash-utils.source.announce.load-done() {
  # shellcheck disable=SC2046
  eval $(bash-utils.source.lib-stack.get-attribs)
  local msg

  local cont=${attribs[load_type]}:${BASH_UTILS_SOURCE_ENH_REPORT:-n}:${attribs[has_nested]:-}
  case $cont in
    noload:1:*) ;;
    *:2:*)      local msg cont=${attribs[load_type]}:${attribs[error_code]:-}
                case "$cont" in
                  noload:*) msg=" Done (already loaded)" ;;
                  load:)    msg=" Done" ;;
                  *:fnf)    msg=" Done (not found)" ;;
                esac

                bash-utils.source.announce.msg "$msg"
                ;;
    *:1:*)      case ${attribs[error_code]:-n} in
                  n)  bash-utils.source.announce.msg ".\c" ;;
                esac
                ;;
    *:2:t)      bash-utils.source.announce.msg-body \
                  "${attribs[nm]}" "${attribs[path]}"
                bash-utils.source.announce.msg " -\c"
                ;;
  esac

  # Record load completion
  Included["${attribs[nm]}"]="${attribs[path]}"

  # Before removing the file from the stack
  case $(bash-utils.source.lib-stack.is-empty) in
    n)  bash-utils.source.lib-stack.pop ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     local-source()
# Description:  Function to attempt to load the given library (script) -
#               reporting the outcome on stderr
# Opts:         None
# Args:         None
# Returns:      Reported on STDOUT is either...
#               * the absolute path to the given library path - lib loaded OK
#               * "ERROR:: fnf" - lib not found
#               * "ERROR:: rec" - recursive inclusion attempted
#               * "ERROR:: syn" - syntax error detected
# Variables:
#               $BASH_SOURCE_SOURCE_MAX_DEPTH - max inclusion depth,
#                                               default - 10
# ------------------------------------------------------------------------------
local-source() {
  : "local-source($@)"
  local caller=( $(caller $caller_idx) )
  : "CALLER::: ${caller[@]}"
  case $caller_idx in 4) caller_idx=1 ;; esac
  case "${caller[-1]}" in
    "$@")  bash-utils.source.fatal-error "direct recursion" ;;
  esac

  case $((count+=1)) in 5) bash-utils.source.fatal-error WTAF ;; esac

  builtin source "$@"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.try-lib-path()
# Description:  Function to attempt to load the given library (script) -
#               reporting the outcome on stderr
# Opts:         None
# Args:         None
# Returns:      Reported on STDOUT is either...
#               * the absolute path to the given library path - lib loaded OK
#               * "ERROR:: fnf" - lib not found
#               * "ERROR:: rec" - recursive inclusion attempted
#               * "ERROR:: syn" - syntax error detected
# Variables:
#               $BASH_SOURCE_SOURCE_MAX_DEPTH - max inclusion depth,
#                                               default - 10
# ------------------------------------------------------------------------------
bash-utils.source.try-lib-path() {
  local path="${1:?'No lib name to try'}"
  local -A outcome=(
    [path]= [error_code]= [error]= [error_code]= [caller_fnm]= [caller_lineno]=
  )

  local count=0 this_dir="${BASH_SOURCE%/*}" caller_idx=4

  # Attempt to use the shell to find/validate path name(s) &/or errors
  local f=() ; mapfile -t f < <(
      exec 2>&1
      trap 'builtin echo $?' 0
      PS4='^${BASH_SOURCE//$this_dir*}####'
      unset BASH_XTRACEFD
      set -x
      source() { local-source "$@" ; }
      .() { local-source "$@" ; }

      . $path
  )

  # Save the current path
  outcome[path]="$path"

  #: ${#f[@]} - "${f[@]}"
  # And the return code
  local rc="${f[-1]##* }" ; unset f[-1]
  #: ${#f[@]} - "${f[@]}"

  # Now attempt to extract the call stack as reported by the xtrace output
  local l error=() ; for l in "${f[@]}" ; do   
    : "$l"
    case "$l" in
      *CALLER:::*)  local caller=( $l )
                    : ${#caller[@]} - "${caller[@]} (${caller[2]//[^0-9]})"
                    eval $(bash-utils.source.lib-stack.top)
                    case "${top[path]}" in
                      "${caller[-1]}")  ;;
                      *)                bash-utils.source.lib-stack.new-lib \
                                          path="${caller[-1]}" \
                                          caller_lineno=${caller[0]}
                                        ;;
                    esac
                    ;;
      *:\ line\ *)  error+=( "$l" )
                    ;;
    esac
  done

  # Now remove non-error reporting lines in error case
  case "${f[*]}" in
    *:\ line\ *)  local _f e ; for e in "${f[@]}" ; do
                    case "$e" in ^*) ;; *) _f+=( "$e" ) ;; esac
                  done

                  f=( "${_f[@]}" )
                  ;;
  esac

  : ${#f[@]} - "${f[@]}"

  case "${error[*]}" in
    *such\ file\ or*)     outcome[error_code]=fnf
                          outcome[error]="$(printf "%s\n" "${error[@]}")"
                          ;;
    *direct\ recursion*)  outcome[error_code]=dr
                          outcome[error]="source recursion attempted"
                          ;;
    *\ syntax\ error\ *)  outcome[error_code]=syn
                          outcome[error]="\n$(printf "%s\n" "${error[@]}")"
                          ;;
  esac
 
  declare -p outcome
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.find-it()
# Description:  Core function to load (source) the given library script file(s)
# Options:      -e          - specify enhanced error reporting
#               -r          - specify forced reload if required
#               -s NM'='VAL - specify an additional shortcut
# Arguments:
# Returns:      
# Variables:     
# ------------------------------------------------------------------------------
bash-utils.source.find-it() {
  local PATH="${BASH_UTILS_PATH:+$BASH_UTILS_PATH:}$PATH"
  PATH="$1:$PWD:$DSELF:${DSELF/lib/bin}:$PATH"

  local _path
  # shellcheck disable=SC2162,SC2086
  while read _path ; do
    local fqpath ; case "$2" in
      /*) fqpath="$2" ;;
      *)  fqpath="$_path/$2" ;;
    esac

    : "$(builtin echo "$fqpath"*)"
    case "$(builtin echo "$fqpath"*)" in
      $fqpath)  path="$fqpath" ; break ;;
      *)        unset fqpath
                case "$2" in /*) break ;; esac
                ;;
    esac
  done < <(builtin echo -e ${PATH//:/\\n})

  echo "${fqpath:-}"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.source-libs()
# Description:  Core function to load (source) the given library script file(s)
# Options:      -e          - specify enhanced error reporting
#               -r          - specify forced reload if required
#               -s NM'='VAL - specify an additional shortcut
# Arguments:
# Returns:      
# Variables:     
# ------------------------------------------------------------------------------
declare count=0
bash-utils.source.source-libs() {
  local OPTARG OPTIND opt
  while getopts 'ers:' opt ; do
    case $opt in
      e)  export BASH_UTILS_SOURCE_ENHANCED_ERROR=t ;;
      r)  export BASH_UTILS_SOURCE_RELOAD=t ;;
      s)  bash-utils.source.add-shortcut "$OPTARG" ;;
    esac
  done

  shift $((OPTIND-1))

  local nm="${1:?'No lib name'}" path="${2:-"$1"}"

  : $((count+=1))

  local error ; case "${path:-n}" in
   !*)   # Unexpanded shortcut, so expand it and go again
          local sc=${nm%%/*} ; sc=${sc/!}
          case ${BASH_UTILS_SOURCE_SHORTCUTS[$sc]:-n} in
            n)  bash-utils.source.announce.fatal-error \
                  "shortcut not found: $sc (in $nm)" ;;
          esac

          # Use the expanded path to go further
          # shellcheck disable=SC2086
          bash-utils.source.source-libs \
            "$nm" "${path/!$sc/${BASH_UTILS_SOURCE_SHORTCUTS[$sc]:-}}"

          return
          ;;
    *\*)  # Apparently wildcarded path, so do the expansion and then do each in
          # turn
          # shellcheck disable=SC2012,SC2162
          ls -1 "$path" | while read path ; do
            bash-utils.source.announce.load-action # "$nm" "$path"
            bash-utils.source.source-libs "$nm" "$path"
            bash-utils.source.announce.load-done
          done
          ;;
  esac
  
  local caller=( $(caller 1) )

  # Shortcut(s) & wildcard(s) now expanded, so attempt to find it
  path="$(bash-utils.source.find-it "${caller[-1]%/*}" "$path")"

  case "${path:-n}" in
    *"$BASH_SOURCE")  bash-utils.source.report-self-load \
                        nm="$nm" path="$path" \
                        file="${BASH_SOURCE[2]}" lineno=${BASH_LINENO[1]}
                      ;;
    n)                : ;;
    *)                bash-utils.source.detect-recursive-load \
                        path="$path" file="${BASH_SOURCE[2]}" \
                        lineno=${BASH_LINENO[1]}
                      ;;
  esac

  # Create the entry for the current lib
  bash-utils.source.lib-stack.new-lib \
    nm="$nm" path="$path" caller_lineno=${caller[0]}

  # Now process the current lib based on whether, or not, it was discovered
  local fnf ; case "${path:-n}" in
    n)  # Determine & flag whether the fnf error is to be treated as fatal or
        # warning/ignored
        local fnf ; case ${FUNCNAME[1]} in *ifsource) fnf=perm ;; esac

        bash-utils.source.lib-stack.update \
          error_code=fnf fnf=${fnf:-fatal} load_type=load
        ;;
    *)  # Attempt to "preload" the given path to determine if there's any error
        # likely to ensue
        eval $(bash-utils.source.try-lib-path "$path")

        bash-utils.source.lib-stack.update \
          load_type=${reload:-} path="${outcome[path]:-"$path"}" \
          fnf=${fnf_cons:-fatal} \
          error_code="${outcome[error_code]:-}" error="${outcome[error]:-}"
        ;;
  esac

  bash-utils.source.announce.load-action
  case $count in 4) exit 11 ;; esac

  case $(bash-utils.source.lib-stack.get-attrib error_code) in
    fnf)  ;;
    *)    builtin . "$path" ;;
  esac

  bash-utils.source.announce.load-done #"${not_found:-}"
}

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
#               $BASH_UTILS_PATH     - supplementary path(s) to prepend
#                                             to $PATH before attempting to load
#                                             the given file(s).
#               $BASH_UTILS_SOURCE_ENH_REPORT  - run verbosely i.e. report loading
#                                             & loaded messages
# Notes:        * The 'bin' & 'lib' subdirectories of the repository containing
#                 this script are auto-magically prepended to
#                 BASH_UTILS_PATH itself.
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
bash-utils.source() { bash-utils.source.source-libs "$@" ; }

# ------------------------------------------------------------------------------
# Function:     bash-utils.ifsource()
# Description:  Function to supplement the core 'source' command by providing a
#               means of accepting the non-existance of a posited included file.
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
#               $BASH_UTILS_PATH     - supplementary path(s) to prepend
#                                             to $PATH before attempting to load
#                                             the given file(s).
#               $BASH_UTILS_SOURCE_ENH_REPORT  - run verbosely i.e. report loading
#                                             & loaded messages
# Notes:        * The 'bin' & 'lib' subdirectories of the repository containing
#                 this script are auto-magically prepended to
#                 BASH_UTILS_PATH itself.
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
bash-utils.ifsource() { bash-utils.source.source-libs "$@" ; }

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
#               $BASH_UTILS_PATH     - supplementary path(s) to prepend
#                                             to $PATH before attempting to load
#                                             the given file(s).
#               $BASH_UTILS_SOURCE_ENH_REPORT  - run verbosely i.e. report loading
#                                             & loaded messages
# Notes:        The directory containing this script is auto-added to PATH
#               itself.
# ------------------------------------------------------------------------------
.() { bash-utils.source.source-libs "$@" ; }

# ------------------------------------------------------------------------------
# Function:     .()
# Description:  Function to override the core 'source' command (by calling the
#               overridden '.' command :-)
# Opts:         None
# Args:         $*  -  one, or more, files to include
# Returns:      0 iff all files were included successfully
# Variables:    $IncludeStack - see above :-)
# ------------------------------------------------------------------------------
source() { bash-utils.source.source-libs "$@" ; }

# Reset the first pass flag - by defining the externally accessible function
# ------------------------------------------------------------------------------
# Function:     .()
# Description:  Function providing an externally accessible function allowing
#               dependant callers to determine if the core library has already
#               been loaded i.e. the dependencies have already been met, since
#               if this routine is called and it doesn't exist ...
# Opts:         None
# Args:         None
# Returns:      0
# Variables:    None
# ------------------------------------------------------------------------------
bash-utils.is-loaded() { : ; }

# Ensure the loaded message is generated for this lib (if appropriate)
# shellcheck disable=SC2119
bash-utils.source.announce.load-done

unset FIRST_PASS

: ${#IncludeStack[@]}
# shellcheck disable=SC1090,SC2086
declare incl ; for incl ; do . $incl ; done

#### END OF FILE
