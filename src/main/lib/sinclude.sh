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
# Env vars:     $SINCLUDE_PATH      - used to supplement the callers $PATH for
#                                     "places" in which to seek included files
#                                     (when used with relative included file
#                                     paths).
#               $SINCLUDE_VERBOSE   - when set to a integer, this determines the
#                                     verbosity of file inclusion reports where
#                                     the values are as follows...
#                                       1 - print a '.' for each file on
#                                           successful inclusion.
#                                       2 - full ie.e. starting & done, reports.
#               $SINCLUDE_NO_RECORD - there are instances when files might need
#                                     to be included multiple times, this flag
#                                     should be set (to non-empty) in such
#                                     circumstances. It actually prevents the
#                                     updating of the anti-recursive inclusion
#                                     record for the callers shell (and all
#                                     sub-shells thereof).
# Notes:
# * There are a number of variables...
#   * The pathing - which may be...
#     * fully pathed.
#     * simple relative.
#     * complex relative.
#   * The extension which may, or may not, be present - if not present, then it
#     has to be guessed at (no file has to have an extension - and on Windoze
#     the absence of an extensiona appears to remove the execution status of the
#     file), so the 1st guess is always the extensionless file name).
# * The use of $SINCLUDE_NO_RECORD should be used with great care (for
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
################################################################################

eval ${_LIB_SINCLUDE_SH_:-}
export _LIB_SINCLUDE_SH_=return

# Include stack whose elements are each of the form <name>':::'<path>
declare IncludeStack=()

lib.sinclude.to-stdout() { builtin echo -e "$@" ; }

lib.sinclude.to-stderr() { builtin echo -e "$@" >&2 ; }

lib.sinclude.path.push() {
  : ${#IncludeStack[@]}, ${IncludeStack[@]}
  IncludeStack+=( ${1:?'No path to push'} )
  : ${#IncludeStack[@]}
}

lib.sinclude.path.peek() {
  case ${#IncludeStack[@]} in 0 ) ;; *) echo ${IncludeStack[-1]:-} ;; esac
}

lib.sinclude.path.peek.name() {
  local ret=$(lib.sinclude.path.peek)
  builtin echo ${ret%%:::*}
}

lib.sinclude.path.peek.path() {
  local ret=$(lib.sinclude.path.peek)
  builtin echo ${ret##*:::}
}

lib.sinclude.path.pop() {
  local ret="$(lib.sinclude.path.peek)"
  : ${#IncludeStack[@]}
  case ${#IncludeStack[@]} in 0 ) ;; *) unset IncludeStack[-1] ;; esac
  : ${#IncludeStack[@]}
  builtin echo $ret
}

lib.sinclude.path.depth() { echo ${#IncludeStack[@]} ; }

lib.sinclude.path.is-empty() {
  local ret=n
  case ${#IncludeStack[@]} in 0) ret=y ;; esac
  builtin echo $ret
}

# ------------------------------------------------------------------------------
# Function:     sinclude.load.announce.load-header()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.load-header() {
  : ${SINCLUDE_VERBOSE:-unset}
  case ${SINCLUDE_VERBOSE:-n} in n|0|1) return ;; esac

  local nm=$(lib.sinclude.path.peek.name) path=$(lib.sinclude.path.peek.path)

  local msg=() ; case "$nm" in
    $path)  msg+=( $path ) ;;
    *)      msg+=( "$nm, file: '$path'" ) ;;
  esac

  lib.sinclude.to-stdout "Load: ${msg[@]}\c"
}

# ------------------------------------------------------------------------------
# Function:     sinclude.load.announce-starting()
# Description:  As it says on the tin - selectively reports the file load/source
#               start event.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Iff enabled, the message on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.announce.load-starting() {
  local nm=${1:?'No name'} path=${2:?'No path'}

  # Save the actual path irrespective of verbosity (might be needed later for
  # error reporting purposes)
  lib.sinclude.path.push "$nm:::$path"
  
  : ${SINCLUDE_VERBOSE:-unset}
  case ${SINCLUDE_VERBOSE:-n} in n|0|1) return ;; esac

  case $(lib.sinclude.path.is-empty) in n) lib.sinclude.to-stdout ;; esac

  lib.sinclude.to-stdout "$(lib.sinclude.announce.load-header) - Starting ... \c"
}

lib.sinclude.announce.load-done() {
  : ${SINCLUDE_VERBOSE:-unset}
  local path="$(lib.sinclude.path.peek)" msg=
  lib.sinclude.path.pop >/dev/null

  : ${SINCLUDE_VERBOSE:-n}
  case ${SINCLUDE_VERBOSE:-n} in n|0) return ;; esac

  case ${SINCLUDE_VERBOSE:-n} in 1) msg="." ;; 2) msg=Done ;; esac

  # Continue line iff appropriate i.e. a nested include
  case $(lib.sinclude.path.is-empty) in
    n)  msg="$msg\c" ;;
    y)  msg="$msg\n" ;;
  esac

  lib.sinclude.to-stdout "$msg"
}

# ------------------------------------------------------------------------------
# Function:     sinclude.announce.already-loaded()
# Description:  As it says on the tin - selectively reports the file load/source
#               loaded event.
# Takes:        None
# Returns:      
# Variables:    None..
# ------------------------------------------------------------------------------
lib.sinclude.announce.already-loaded() {
  local path="$(lib.sinclude.path.peek)" msg=
  lib.sinclude.path.pop >/dev/null

  case ${SINCLUDE_VERBOSE:-n} in
    n|0|1) return ;;
    2)      lib.sinclude.announce.load-header "$nm" "$path"
            lib.sinclude.to-stdout ' - Already loaded'
            ;;
  esac
}

#. ${BASH_SOURCE%.sh}/announce.sh
#
#: "$# - '$@', SINCLUDE_PATH: ${SINCLUDE_PATH:-}"

# Define the inclusion record - whose initial value is this file itself
declare -A Included=()

lib.sinclude.to-stderr() { builtin echo -e "$@" >&2 ; }

# ------------------------------------------------------------------------------
# Function:     lib.sinclude.abs-path()
# Description:  Routine to take a path and return its fully pathed euivalent.
# Takes:        $1  - path.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    $SINCLUDE_VERBOSE
# ------------------------------------------------------------------------------
lib.sinclude.abs-path() { echo $(cd $(dirname $1)>/dev/null && pwd)/${1##*/} ; }

# Define shorthands for self
declare \
  sself="${BASH_SOURCE##*/}" \
  pself="$(lib.sinclude.abs-path $BASH_SOURCE)"
declare dself="${pself%/*}"

# And use 'em to update PATH for this session
export PATH="$dself:$PATH"
lib.sinclude.announce.load-starting "$pself" "$pself"

lib.sinclude.fatal() { lib.sinclude.to-stderr "FATAL!!! $@" ; exit 1 ; }

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
# Variables:    $Included - see above :-)
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
# ------------------------------------------------------------------------------
lib.sinclude() {
  case $# in 0) lib.sinclude.fatal 'Nothing to load/include' ;; esac

  #: $(declare -p FUNCNAME BASH_SOURCE LINENO)

  # ----------------------------------------------------------------------------
  # Function:     lib.sinclude.try-it()
  # Description:  Private routine to "try" the given path
  # Opts:         None
  # Args:         $1  - the posited file name
  # Returns:      The normalized path on STDOUT iff it can be normalized, empty
  #               string otherwise.
  # ----------------------------------------------------------------------------
  lib.sinclude.try-it() {
    local posited="${1:?'Nothing to try'}"

    local outcome=()
    readarray -t outcome < <(
      #set +x
      exec 2>&1
      declare PS4='+${BASH_SOURCE}#'
      export BASH_XTRACEFD=2
      .() { builtin . "$@" ; }
      set -ex
      export SHELLOPTS
      . $posited
      : $?
    )
    
    : $(declare -p outcome)
    case "${outcome[-1]}" in
      *0) # Appears to have been successful, so do the necessary
          builtin echo ${outcome[4]} | sed -n "s,++*\(.*$posited\)#.*,\1,p"
          ;;
      *)  # Summat up, so attempt to see if it was ENOEXIST or otherwise
          builtin echo "EERROR:${outcome[-1]}"
          ;;
    esac  
  }

  # ----------------------------------------------------------------------------
  # Function:     lib.sinclude.fpath.normalize()
  # Description:  Private routine to "normailze" the given path - by which is
  #               meant the ...
  #                 * Conversion to a fully pathed file.
  #                 * .
  # Opts:         None
  # Args:         $1  - the posited file name
  # Returns:      The normalized path on STDOUT iff it can be normalized, empty
  #               string otherwise.
  # ----------------------------------------------------------------------------
  lib.sinclude.fpath.normalize() {
    local fnm=${1:?'No path to try'}

    case "$fnm" in
      /*)   # Fully pathed already, nowt to do
            lib.sinclude.try-it "$fnm"
            ;;
      */*)  # Complex relative path - find needed
            local path= $try= ; for path in $(echo ${PATH//:/$'\n'}) ; do
              try="$path/$fnm"
              : $path, $fnm, $try

              case "$(lib.sinclude.try-it $try)" in
                :*|EERROR:*)  break ;;
                *)            try= ;;
              esac
            done

            builtin echo "$try"
            ;;
      *)    # Simple relative path - so let the shell take the strain
            lib.sinclude.try-it "$fnm"
            ;;
    esac
  }

  # Before anything else, update the PATH to include the bin & lib
  # subdirectories in this repository + any paths defined using $SINCLUDE_PATH
  local PATH="$dself:${dself%/lib}/bin:${SINCLUDE_PATH:+$SINCLUDE_PATH:}$PATH"

  : "$# - $@"
  local lib nm dir ; for lib in ${@:?'No library'} ; do
    : $lib

    local norm="$(lib.sinclude.fpath.normalize "$lib")"
    
    : ${norm:-n}, $lib
    local msg= ; case "${norm:-n}" in
      EERROR:*) lib.sinclude.fatal "Problem found in file: $lib -\n$norm" ;;
    esac

    : SINCLUDE_VERBOSE - ${SINCLUDE_VERBOSE:-unset}
    : Included[$$] - ${Included[$$]:-}
    
    : ${norm:-n}, $lib
    case "${Included[$$]:-n}" in
      *$norm*) lib.sinclude.announce.already-loaded $lib $norm ;;
      *)      lib.sinclude.announce.load-starting $lib $norm
              builtin . $norm
              local incl="${Included[$$]:+"${Included[$$]:-}:"}$norm"
              eval ${SINCLUDE_NO_RECORD:-"Included[$$]='$incl'"}
              lib.sinclude.announce.load-done $lib $norm
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
# Variables:    $Included - see above :-)
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
# Variables:    $Included - see above :-)
# ------------------------------------------------------------------------------
source() { lib.sinclude $@ ; }

# Initialise the loaded record (with this file) ...
Included=( [$BASHPID]=$(lib.sinclude.abs-path $BASH_SOURCE) )

# ensure the loaded message is generated (if appropriate)
lib.sinclude.announce.load-done

: "$# - '$@'"

# Before including the/any given files
declare incl ; for incl in $@ ; do . $incl ; done

:

#### END OF FILE
