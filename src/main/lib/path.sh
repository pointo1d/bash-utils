#! /usr/bin/env bash
################################################################################
# File:		path.sh
# Description:	Shell script implementing library path related functions
################################################################################

eval ${LIB_PATH_SH:-} ; export LIB_PATH_SH=return
. ${BASH_SOURCE/.sh}/error.sh

# ------------------------------------------------------------------------------
# Function:     lib.path.stat()
# Description:  Library function to return the stat details for the given path,
#               if it exists.
# Options:      As per stat(1), terse ('t') by default
# Args:         $1  - specify the path to test.
# Returns:      The stat(1) output on STDOUT iff it (the given path) exists,
#               empty string otherwise
# ------------------------------------------------------------------------------
lib.path.stat() {
  # Load the full opt & arg list
  local args=( $@ )

  # Separate the opts & the path
  local opts=${args[@]::${#args[@]}-1} path=${args[-1]:?'No path to test'}

  # Now do the stat(1) in a sub-shell to save groking the ruling i.e. call time,
  # shopt
  echo $(stat ${args[@]:-'-t'} $path 2>/dev/null ; return 0)
}

# ------------------------------------------------------------------------------
# Function:     lib.path.exists()
# Description:  Path library routine to whether, or not, the given path exists
#               in an errexit compliant fashion i.e. the non-existence of the
#               path does not cause the consuming script to automatically abort
#               if that self-same consuming script is running under errexit
#               conditions i.e. '-e' has been set.
# Takes:        -s SEV  - specify the severity of a non-extant path as one of...
#                         'f' - fatal
#                         'w' - warning
#               -q  - specify quiet response when the path exists
# Args:         PATH  - mandatory path to test
# Returns:      The given path/empty string on STDOUT iff '-q' has not been
#               specified. If the
# Env vars:     None
# Notes:        '-q' implies '-f'
# ------------------------------------------------------------------------------
lib.path.exists() {
  local OPTARG OPTIND opt quiet= sev=f
  while getopts 'qs:' opt ; do
    case $opt in
      q)  quiet=t ;;
      s)  case o${OPTARG//[fw]} in
            o)  sev=$OPTARG ;;
            *)  lib.console.fatal "Unknown severity: $sev" ;;
          esac
          ;;
    esac
  done

  shift $((OPTIND - 1))

  # 1st - determine if the path exists - but do nothing yet about the outcome
  local exists="$(builtin echo ${1:-'No path to test'}*)"

  # Now reduce it to the last char, removing the star (if present)
  exists=${exists: -1} ; exists=${exists/\*}

  : "${exists:+y}:${quiet:-n}:${sev}"
  case "${exists:+y}:${quiet:-n}:${sev}" in
    y:n:*)  echo $1 ;;
    *:n:i|\
    y:t:*)  ;;
    :*:*)   lib.path.error.not-found -s$sev "$1" ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.path.type()
# Description:  Path library routine to determine the 'type' of the given path
#               as determined by the the first character output from an
#               'ls -al PATH' command with 3 provisos...
#                 *   '-' becomes 'f'.
#                 *   a non-extant path results in an empty string iff the '-f'
#                     (fatal) option has not been specified
#                 *   iff the directory is associated with a Git repository 'd'
#                     is translates as follows...
#                     * 'gp'  - iff the path is a Git path i.e. a path within a
#                               git repo.
#                     * 'gr'  - iff the path is a git repo root directory.
#                     * 'gS'  - iff the path is a git submodule within a git
#                               repo.
#                     * 'gs'  - iff the path is a git submodule path i.e. a path
#                               within a a submodule (within a git repo).
# Takes:        None
# Args:         PATH  - mandatory path to test
# Returns:      The 'type' of the path on STDOUT iff the path exists. If the
#               path doesn't exist and '-f' has not been specified, then an
#               empty string is echoed to STDOUT, otherwise i.e. if '-f' has
#               been specified, then a non-extant file will result in no
#               return and a fatal error report on STDERR.
# Env vars:     None
# ------------------------------------------------------------------------------
lib.path.type() {
  local path=${1:-'No path to test'}

  # Non-existence of the path is always fatal!!
  lib.path.exists $path

  # Determine the type
  type=$(ls -ald $path) ; type=${type:0:1}

  # ... and post-process it
  case $type in
    d)  # It'#s a directory, extra work involved to determine if there's a Git
        # context
        local git="$(git -C $path rev-parse --show-toplevel 2>/dev/null | sed 's,\(.\):,\L/\1,')"
        git=${git//$HOME\/}

        case "${git:-n}" in
          n)  ;;
          $path|\
          */$path)  type=gr ;;
          $path/*)  type=gp ;;
          $path/*)  type=gs ;;
          $path/*)  type=gS ;;
        esac
        ;;
  esac

  echo $type
}

################################################################################
# Function:     lib.path.is-type()
# Description:  Core function to determine if the type of the given path is the
#               same as expected i.e. as given.
# Opts:         None
# Args:         $1  - the expected type, default - 'f' i.e. plain file
#               $2  - the path to check
# Returns:      0 on STDOUT iff the types match exists, '' if not, fatal if the
#               file doesn't exist.
# To do:        Validate the given 'type'
################################################################################
lib.path.is-type() {
  local type=${1:-f} path="${2:?'No path to test'}" match=

  lib.path.exists -qsf $path
  
  # Exists, so continue by attempting to determine if the type matches
  case "$(ls -ald $path)" in ${type/f/-}*) match=y ;; esac

  # And report it
  echo $match
}

################################################################################
# Function:     lib.path.get-type()
# Description:  Core function to determine and return on STDOUT, the 'type' of
#               the given path as reported by ls -al with 3 provisos...
#                 *   '-' becomes 'f'.
#                 *   a non-extant path results in an empty string iff the '-f'
#                     (fatal) option has not been specified
#                 *   iff the directory is associated with a Git repository 'd'
#                     is translates as follows...
#                     * 'gp'  - iff the path is a Git path i.e. a path within a
#                               git repo.
#                     * 'gr'  - iff the path is a git repo root directory.
#                     * 'gS'  - iff the path is a git submodule within a git
#                               repo.
#                     * 'gs'  - iff the path is a git submodule path i.e. a path
#                               within a a submodule (within a git repo).
#
# Opts:         None
# Args:         $1  - the path to check.
# Returns:      0 iff the path exists or path does exist when existence is
#               non-fatal.
################################################################################
lib.path.get-type() {
  lib.path.exists -qsf "${1:?'No path to test'}"
  local type="$(ls -ld $1)" ; type=${type:0:1} ; type=${type/-/f}

  case $type in
    d)  # a directory may need extra handling (it might be a Git repo element)
        local git="$(git -C $1 rev-parse --show-toplevel 2>/dev/null | sed 's,\(.\):,\L/\1,')"
        git=${git//$HOME\/}

        : ${git:-n}
        case "${git:-n}" in
          n)  ;;
          $path|\
          */$path)  type=gr ;;
          $path/*)  type=gp ;;
          $path/*)  type=gs ;;
          $path/*)  type=gS ;;
        esac
        ;;
  esac

  echo $type
}

#### END OF FILE
