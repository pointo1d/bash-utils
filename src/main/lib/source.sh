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
#     2 - 'Source: <fname>: Loaded'
#   $BASH_UTILS_SOURCE_VERBOSE at level 1...
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
: $# - $@
# As data definitions with no initial vlaue don't affect the value of the
# variables, define the record of...
#   * The shortcuts list
#   * the totality of included files and ...
#   * the current include stack (for non-quiet announcements)
declare -A BASH_UTILS_SOURCE_SHORTCUTS Included ; declare -a IncludeStack

# File global containing the absolute path to self
# shellcheck disable=SC2155,SC2128,SC2086
declare PSELF

case $(type -t source) in
  builtin)  # Do the first pass stuff
            builtin . ${BASH_SOURCE/source/path}
            builtin . ${BASH_SOURCE/source.sh}/path/update-var.sh
            builtin . ${BASH_SOURCE/source/console}

            # shellcheck disable=SC2128
            PSELF="$(bash-utils.path.get-absolute "$BASH_SOURCE")"
            DSELF="${PSELF%/*}"
            FirstPass=t
            declare -A attribs
            attribs=( [abs]='' [nm]='' [type]='' [has_nested]='' )
            IncludeStack=( "$(declare -p attribs)" )

            declare d=${BASH_SOURCE%/*} ; d=${d:-=n}
            # shellcheck disable=SC2164,SC2086
            BASH_UTILS_SOURCE_SHORTCUTS["bash-utils"]="$(cd $d>/dev/null ; echo $PWD)"
            ;;
  *)        FirstPass= ;;
esac

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.is-loaded()
# Description:  Routine to determine if the given path has already been loaded.
# Takes:        $1  - absolute path, fatal if not.
# Returns:      Updated STDOUT - 'y' iff the given path has already been
#               loaded, 'n' otherwise.
# Variables:    $Included.
# ------------------------------------------------------------------------------
bash-utils.source.is-loaded() {
  bash-utils.path.is-absolute "${1:?'No lib path to test'}" t >/dev/null

  local ret=n ; case ${Included["$1"]:+y} in y) ret=y ;; esac
  builtin echo $ret
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.msg()
# Description:  Simple routine to report the given message to STDOUT - dependant
#               on the ruling verbosity.
# Takes:        $*  - the message to report
# Returns:      0 always
# Variables:    $BASH_UTILS_SOURCE_VERBOSE - defines the ruling verbosity level for
#                                   message reporting
# ------------------------------------------------------------------------------
bash-utils.source.announce.msg() {
  case ${BASH_UTILS_SOURCE_VERBOSE:-n} in 1|2) builtin echo -e "$@" ;; esac
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
# Variables:    $BASH_UTILS_SOURCE_VERBOSE
# ------------------------------------------------------------------------------
bash-utils.source.announce.msg-body() {
  local -A attribs
  # shellcheck disable=SC2046
  eval $(bash-utils.source.announce.get-attribs)

  local hdr=() ; case ${attribs[type]}:${BASH_UTILS_SOURCE_VERBOSE:-n} in
    *:0|*:n|\
    *:1)   return ;;
    #*:1)        hdr=( "${3:-.}" ) ;;
    *:2)        hdr=( 'Source:' ) ; case "${attribs[nm]}" in
                  ${attribs[abs]})  hdr+=( "'${attribs[abs]}'" ) ;;
                  *)              hdr+=( "'${attribs[nm]}' ('${attribs[abs]}')" ) ;;
                esac
                ;;
  esac
  
  # shellcheck disable=SC2145
  bash-utils.source.announce.msg "${hdr[@]}\c"
}

# ------------------------------------------------------------------------------
# Function:     source.load.announce.set-attribs()
# Description:  Called first for any sourced file, this routine records the
#               name, absolute path and "type" for the given library name &/or
#               path on the included stack.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.announce.set-attribs() {
  local nm=${1:?'No name'}
  bash-utils.path.is-absolute "$2" t >/dev/null

  # Perform recursive inclusion detection before doing anything else
  local entry
  for entry in "${!IncludeStack[@]}" ; do
    local -A attribs
    # shellcheck disable=SC2086
    eval ${IncludeStack[$entry]}
    case ${attribs[abs]} in
      "$2") local imm=Direct ; case $entry in 0) ;; *) imm=Indirect ;; esac
            bash-utils.console.fatal "$imm recursive inclusion detected in '$2'"
            ;;
    esac
  done

  # shellcheck disable=SC2155
  local type=$(bash-utils.source.is-loaded "$2"):${BASH_UTILS_SOURCE_RELOAD:-n}
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
  local -A attribs
  case ${#IncludeStack[@]} in
    1)  ;;
    *)  # shellcheck disable=SC2086
        eval ${IncludeStack[0]}
        attribs[has_nested]=t
        IncludeStack[0]="$(declare -p attribs)"
        case ${BASH_UTILS_SOURCE_VERBOSE:-} in 2) bash-utils.source.announce.msg ;; esac
        ;;
    esac

  attribs=( [nm]="$nm" [abs]="$2" [type]="${type}" )
  IncludeStack=( "$(declare -p attribs)" "${IncludeStack[@]}" )
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.get-attribs()
# Description:  Routine to get the set of attribs for the given/default lib.
# Takes:        $1  - optional set of attribs to return - by default, this is
#               the current/top set
# Returns:      The requested attrib set.
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.source.announce.get-attribs() {
  builtin echo "${IncludeStack[${pos:-0}]}"
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
  local -A attribs
  # shellcheck disable=SC2046
  eval $(bash-utils.source.announce.get-attribs)
  local cond=${FirstPass:-}:${BASH_UTILS_SOURCE_VERBOSE:-}:${attribs[has_nested]:-}:${#IncludeStack[@]}

  case $cond in
    t:*|\
    :1::1|\
    :2:t:*)   bash-utils.source.announce.msg ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.source.announce.load-action()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $BASH_UTILS_SOURCE_VERBOSE
# ------------------------------------------------------------------------------
bash-utils.source.announce.load-action() {
  local nm="${1:?'No lib name'}" abs="${2:-$1}"
  bash-utils.source.announce.new-line

  bash-utils.source.announce.set-attribs "$nm" "$abs"
  
  bash-utils.source.announce.msg-body "$nm" "$abs" #la
  local -A attribs
  # shellcheck disable=SC2046
  eval $(bash-utils.source.announce.get-attribs)

  local type msg cont=${BASH_UTILS_SOURCE_VERBOSE:-n}:${attribs[type]}
  case $cont in
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
# Takes:        $1  - optional not found flag
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $BASH_UTILS_SOURCE_VERBOSE
# ------------------------------------------------------------------------------
bash-utils.source.announce.load-done() {
  local not_found="${1:-}" ; local -A attribs
  # shellcheck disable=SC2046
  eval $(bash-utils.source.announce.get-attribs)
  local msg

  local cont=${attribs[type]}:${BASH_UTILS_SOURCE_VERBOSE:-n}:${attribs[has_nested]:-}
  case $cont in
    noload:1:*) ;;
    *:2:*)      local msg cont=${attribs[type]}:${not_found:-}
                case "$cont" in
                  noload:*) msg=" Done (already loaded)" ;;
                  load:)    msg=" Done" ;;
                  *:t)      msg=" Done (not found)" ;;
                esac

                bash-utils.source.announce.msg "$msg"
                ;;
    *:1:*)      : ${not_found:-n}
                case ${not_found:-n} in
                  n)  bash-utils.source.announce.msg ".\c" ;;
                esac
                ;;
    *:2:t)      bash-utils.source.announce.msg-body \
                  "${attribs[nm]}" "${attribs[abs]}"
                bash-utils.source.announce.msg " -\c"
                ;&
    *:2:*)      bash-utils.source.announce.msg " Done" ;;
  esac

  case ${#IncludeStack[@]} in
    1)  ;;
    *)  IncludeStack=( "${IncludeStack[@]:1}" ) ;;
  esac
}

# shellcheck disable=sc2128
bash-utils.source.announce.load-action "$BASH_SOURCE" "$PSELF"

# ------------------------------------------------------------------------------
# Function:     try-lib-path()
# Description:  
# Takes:        
# Returns:      
# ------------------------------------------------------------------------------
try-lib-path() {
  local path="${1:?'No lib name to try'}"
  : $PATH

  # finally attempt to use the shell to find the name
  local f=() ; mapfile -t f < <(
    exec 2>&1
    ps4='#$BASH_SOURCE '
    unset BASH_XTRACEFD
    set -x
    builtin . "$path"
  )

  declare -p f
}

# ------------------------------------------------------------------------------
# Function:     detect-recursive-inclusion()
# Description:  
# Takes:        
# Returns:      
# ------------------------------------------------------------------------------
detect-recursive-inclusion() {
  local path="${1:?'No lib path to validate'}"

  case "$PSELF" in
    *"/$path")  bash-utils.console.fatal \
                  "'$nm' ('$PSELF') cannot load itself, use builtin(1)"
                ;;
  esac

  : $path, ${BASH_SOURCE[2]}
  case "${BASH_SOURCE[@]}" in
    *$path*)  bash-utils.console.fatal \
                "Recursive inclusion detected in '$nm'"
              ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     load-it()
# Description:  
# Takes:        Named args as <name>=<val> pairs
#                 nm              - lib name
#                 path            - lib path
#                 inclusion depth - nesting depth
# Returns:      
# ------------------------------------------------------------------------------
load-it() {
  local nm="${1:?'No lib name'}" path="${2:-"$1"}" depth=${3:-0} # ; eval "$@"

  detect-recursive-inclusion "$path"
 
  case "${path:-n}" in
   !*)   # Unexpanded shortcut, so expand it and go again
          local sc=${nm%%/*} ; sc=${sc/!}
          case ${BASH_UTILS_SOURCE_SHORTCUTS[$sc]:-n} in
            n)  bash-utils.console.fatal "shortcut not found: $sc (in $nm)" ;;
          esac

          # Use the expanded path to go further
          load-it \
            "$nm" \
            "${path/!$sc/${BASH_UTILS_SOURCE_SHORTCUTS[$sc]:-}}" \
            $depth

          return
          ;;
    *\*)  # Apparently wildcarded path, so do the expansion and then do each in
          # turn
          ((depth+=1)) ; : $depth

          ls -1 "$path" | while read path ; do
            bash-utils.source.announce.load-action "$nm" "$path"
            load-it "$nm" "$path" $depth
            bash-utils.source.announce.load-done
          done
          ;;
    /*)   # Path is an absolutely pathed file, so only now need to validate it
          # before using it ... but 1st, ensure it isn't this file
          ;;
    *)    # it's not yet absolute, so attempt to make it so ... by attempting
          # to discover the absolute equivalent by searching in PATH
          # supplemented by additional sub-paths
          # Start by updating the PATH by localizing and then prefixing it with
          # the appropriate directories .... including BASH_UTILS_PATH
          #: ${BASH_SOURCE[@]}
          #: $PATH
          local PATH="${BASH_UTILS_PATH:+$BASH_UTILS_PATH:}$PATH"
          PATH="${BASH_SOURCE[3]%/*}:$PWD:$DSELF:${DSELF/lib/bin}:$PATH"
          case "$nm" in
            */*)  path=
                  local _path ; while read _path ; do
                  local fqpath="$_path/$nm"
                  case "$(bash-utils.path.exists "$fqpath")" in
                    $fqpath)  path="$_path/$nm"
                              break
                              ;;
                  esac
                done < <(builtin echo -e ${PATH//:/\\n})
                ;;
            *)  # finally attempt to use the shell to find the name
                local f=() ; mapfile -t f < <(
                  set +x
                  exec 2>&1
                  unset BASH_XTRACEFD
                  PS4='$BASH_SOURCE####'
                  set -x
                  builtin . "$path"
                )

                path="${f[2]%####*}"
                ;;
          esac

          case ${path:-n} in n) not_found=t ;; esac
          ;;
  esac

  bash-utils.source.announce.load-action "$nm" "$path"

  local not_found ; case "$(bash-utils.path.exists "$path"*)" in
    "$path")  builtin . "$path" ;;
    *)        not_found=t ;;
  esac

  bash-utils.source.announce.load-done "${not_found:-}"
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
#               $BASH_UTILS_SOURCE_VERBOSE  - run verbosely i.e. report loading
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
bash-utils.source() {
  local nm
  for nm in "${@:?'No library to include'}" ; do load-it "$nm" ; done
}

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
#               $BASH_UTILS_SOURCE_VERBOSE  - run verbosely i.e. report loading
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
bash-utils.ifsource() { bash-utils.source "$@" ; }

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
#               $BASH_UTILS_SOURCE_VERBOSE  - run verbosely i.e. report loading
#                                             & loaded messages
# Notes:        The directory containing this script is auto-added to PATH
#               itself.
# ------------------------------------------------------------------------------
.() { bash-utils.source "$@" ; }

# ------------------------------------------------------------------------------
# Function:     .()
# Description:  Function to override the core 'source' command (by calling the
#               overridden '.' command :-)
# Opts:         None
# Args:         $*  -  one, or more, files to include
# Returns:      0 iff all files were included successfully
# Variables:    $IncludeStack - see above :-)
# ------------------------------------------------------------------------------
source() { bash-utils.source "$@" ; }

# Reset the first pass flag
unset FirstPass

# Ensure the loaded message is generated for this lib (if appropriate)
# shellcheck disable=SC2119
bash-utils.source.announce.load-done

# Before including the/any given files
declare incl

# shellcheck disable=SC1090,SC2086
for incl ; do . $incl ; done

#### END OF FILE
