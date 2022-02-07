#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         sinclude.sh
# Description:  Pure bash(1) script to provide a recursive inclusion avoiding
#               file inclusion capability whilst providing a simpler interface
#               such that the caller need only know a directory under which the
#               sourced file exists, so for example, this file may be included
#               merely as `. sinclude` or even the help sub-library of console
#               may be included as `. console/help` - in these casaes this is
#               because the directory containing these elements is automgically
#               included in the PATH for free.
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
#     1 - 'Load: <fname>: '
#     2 - 'Load: <fname>: Starting ...'
#     3 - 'Load: <fname>: Starting ... Done'
#   * Duplicated load...
#     1 - 'Load: <fname>: '
#     2 - 'Load: <fname>: Loaded'
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
################################################################################

# As data definitions with no initial vlaue don't affect the value of the variables, define the record of...
#   * the totality of included files and ...
#   * the current include stack (for non-quiet announcements)
declare -a Included IncludeStack
: ${Included[@]}
: ${IncludeStack[@]}

# Early definition of routines on which the announce library depends - multiple
# definitions of which won't affect globals

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.add-lib()
# Description:  Routine to ensure that the inclusion of a library is recorded
#               once & once only.
# Takes:        $1  - the library name/or path
# Returns:      0 always
# Variables:    $Included - the array is updated, with absolute version of the
#                           given path, iff the given path isn't already on the
#                           list
# ------------------------------------------------------------------------------
lib.sinclude.add-lib() {
  local lib="${1:?'No lib to add'}"

  # Go back if already present
  case "${Included[@]}" in
    "$lib") # Already present, nowt to do
            ;;
    *)      # Otherwise, push the lib
            Included+=( "$lib" )
            ;;
  esac
}

lib.sinclude.announce.msg() {
  case ${SINCLUDE_VERBOSE:-n} in 1|2) builtin echo -e "$@" ;; esac
}

lib.sinclude.announce.warning() { builtin echo -e "WARNING !!! $@" >&2 ; }

lib.sinclude.announce.fatal() { builtin echo -e "FATAL !!! $@" >&2 ; }

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.abs-path()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - path.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.abs-path() {
  case "${1:?'No path to convert'}" in
    /*)   builtin echo $1 ;;
    */*)  ( cd ${1%/*}>/dev/null && builtin echo $PWD/${1##*/} ) ;;
    *)    builtin echo $PWD/$1 ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.get-load-action()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - path.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.get-load-action() {
  local abs="$(lib.sinclude.abs-path "${1:?'No abs path'}")"

  : "${Included[@]}:${SINCLUDE_RELOAD:+y}"
  case "${Included[@]}:${SINCLUDE_RELOAD:+y}" in
    $abs:y|\
    $abs\ *:y)  # Already loaded and reload enabled
                ret=reload
                ;;
    $abs:*|\
    $abs\ *:*)  # Already loaded, but reload not enabled
                ret=noload
                ;;
    *)          # Not yet loaded
                ret=load
                ;;
  esac

  builtin echo $ret
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.announce.action-msg()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - path.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.action-msg() {
  local \
    nm="${1:?'No lib name/path'}" \
    abs="$(lib.sinclude.abs-path "${2:-"$1"}")"

  case ${SINCLUDE_VERBOSE:-0} in
    1)  lib.sinclude.announce.msg ".\c" ;;
    2)  local ret="Load: '$nm'"
        case $nm in $abs) ;; *) ret="$ret ('$abs')" ;;  esac

        lib.sinclude.announce.msg "$ret\c"
        ;;
  esac
}

# File global containing the absolute path to self
declare Pself="$(lib.sinclude.abs-path $BASH_SOURCE)"

# Implement in-line version of load-header to announce the start, or otherwise,
# of load of this file
declare action=$(lib.sinclude.get-load-action $Pself) ; case $action in
  noload) case ${SINCLUDE_NOWARN:-n} in
            n)  lib.sinclude.announce.warning \
                  "'$BASH_SOURCE' ('$Pself') already loaded"
                ;;
          esac
          return
          ;;
esac

# Update the inclusion stack for load of this file - which will already be
# present if already loaded
#Included+=( "$Pself" )
lib.sinclude.add-lib "$Pself"
IncludeStack+=( "$BASH_SOURCE::$Pself" )
lib.sinclude.announce.action-msg "$BASH_SOURCE" "$Pself"
case ${SINCLUDE_VERBOSE:-} in
  2) lib.sinclude.announce.msg " - Starting ..." ;;
esac

# Now load the announce sub-library - which should self-announce
. ${BASH_SOURCE//.sh}/announce.sh # $action

lib.sinclude.path-exists() {
  local path="${1:?'No path to confirm'}" ret=n
  case "$(builtin echo $path*)" in *\*) ;; *) ret=y ;; esac
  builtin echo $ret
}

# ------------------------------------------------------------------------------
# Function:     lib.sinclude()
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
# Variables:    $IncludeStack - see above :-)
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
lib.sinclude() {
set -e
  case $# in 0) lib.sinclude.announce.fatal 'Nothing to load/include' ;; esac

  # Before anything else, append the bash-utils bin & lib subdirectories in this
  # repository to SINCLUDE_PATH
  local dself=${Pself%/*}
  SINCLUDE_PATH="${SINCLUDE_PATH:+$SINCLUDE_PATH:}$dself:${dself%/lib}/bin"

  #local PATH="$dself:${dself%/lib}/bin:${SINCLUDE_PATH:+$SINCLUDE_PATH:}$PATH"

  # Now extend it using the directory contaiing the caller, if not already
  # present
  : "$# - $@"
  local lib nm dir fqlib ; for lib in ${@:?'No library'} ; do
    # Prefix a local copy of PATH with the callers i.e. including file,
    # containing dir
    : ${BASH_SOURCE[@]}

    local callers_dir=1 # Assume direct call

    # Update the caller index iff not direct
    case ${FUNCNAME[1]} in source|.) callers_dir=2 ;; esac

    callers_dir="${BASH_SOURCE[$callers_dir]%/*}"
    callers_dir="$(lib.sinclude.abs-path $callers_dir)"
    : $callers_dir, $PWD, $lib
    
    # Now selectively attempt to find the lib name - using the included files
    # name/path
    local fqlib= ; case "$lib" in
      /*)   # Absolutely pathed
            fqlib="$lib"
            ;;
      */*)  # Relative to the callers path, so iterate thro' SINCLUDE_PATH and
            # then PATH itself
            local all_paths="$callers_dir:$PWD:$PATH"
            while read fqlib ; do
              : $fqlib, $lib
              fqlib="$fqlib/$lib"
              case "$(lib.sinclude.path-exists $fqlib*)" in y) break ;; esac
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

    : fqlib - ${fqlib:-unset}, SINCLUDE_VERBOSE - ${SINCLUDE_VERBOSE:-unset}, IncludeStack[@] - ${IncludeStack[@]:-}

    case "${fqlib:-n}" in
      unset)  lib.sinclude.announce.fatal \
                "File not found: '$lib' - '${fqlib:-unset}'"
              ;;
    esac

    lib.sinclude.announce.load-header "$lib" "$fqlib"

    case "${Included[@]:-}" in
      *)      lib.sinclude.announce.load-starting
              : $# - $*
              builtin . $fqlib
              lib.sinclude.add-lib "$fqlib"
              #local incl="${IncludeStack[$$]:+"${IncludeStack[$$]:-}:"}$fqlib"
              #eval ${SINCLUDE_NO_RECORD:-IncludeStack+=( "$incl::$fqlib" )}
              lib.sinclude.announce.load-done
              ;;
      $fqlib) case ${SINCLUDE_RELOAD:-n} in
                n)  lib.sinclude.announce.already-loaded ;;
                *)  lib.sinclude.announce.re-loaded ;;
              esac
              ;;
    esac
  done
}

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
.() { lib.sinclude $@ ; }

# ------------------------------------------------------------------------------
# Function:     .()
# Description:  Function to override the core 'source' command (by calling the
#               overridden '.' command :-)
# Opts:         None
# Args:         $*  -  one, or more, files to include
# Returns:      0 iff all files were included successfully
# Variables:    $IncludeStack - see above :-)
# ------------------------------------------------------------------------------
source() { lib.sinclude $@ ; }

# ensure the loaded message is generated (if appropriate)
lib.sinclude.announce.load-done

: "$# - '$@'"

# Before including the/any given files
declare incl ; for incl in $@ ; do . $incl ; done

:

#### END OF FILE
