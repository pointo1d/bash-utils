#! /usr/bin/env bash
################################################################################
# File:		path.sh
# Description:	Shell script implementing library path related functions
################################################################################
# shellcheck disable=SC2086
eval ${LIB_PATH_SH:-} ; export LIB_PATH_SH=return

# shellcheck disable=SC1090
. ${BASH_SOURCE/.sh}/error.sh
. ${BASH_SOURCE/.sh}/update-var.sh

# ------------------------------------------------------------------------------
# Function:     bash-utils.path.stat()
# Description:  Library function to return the stat details for the given path,
#               if it exists.
# Options:      As per stat(1), terse ('t') by default
# Args:         $1  - specify the path to test.
# Returns:      The stat(1) output on STDOUT iff it (the given path) exists,
#               empty string otherwise
# ------------------------------------------------------------------------------
bash-utils.path.stat() {
  # Load the full opt & arg list
  local args=( "$@" )

  # Separate the opts & the path
  local opts=( "${args[@]::${#args[@]}-1}" ) path=${args[-1]:?'No path to test'}

  # Now do the stat(1) in a sub-shell to save groking the ruling i.e. call time,
  # shopt
  # shellcheck disable=SC2046,SC2068
  builtin echo $(stat ${opts[@]:-'-t'} $path 2>/dev/null)
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.path.exists()
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
bash-utils.path.exists() {
  local OPTARG OPTIND opt quiet sev=f
  while getopts 'qs:' opt ; do
    # shellcheck disable=SC2220
    case $opt in
      q)  quiet=t ;;
      s)  case o${OPTARG//[fw]} in
            o)  sev=$OPTARG ;;
            *)  bash-utils.console.fatal "Unknown severity: $sev" ;;
          esac
          ;;
    esac
  done

  shift $((OPTIND - 1))

  # 1st - determine if the path exists - but do nothing yet about the outcome
  # shellcheck disable=SC2155
  local exists="$(builtin echo ${1:-'No path to test'}*)"

  # Now reduce it to the last char, removing the star (if present)
  exists=${exists:-1} ; exists=${exists/\*}

  : "${exists:+y}:${quiet:-n}:${sev}"
  case "${exists:+y}:${quiet:-n}:${sev}" in
    y:n:*)  builtin echo $1 ;;
    *:n:i|\
    y:t:*)  ;;
    :*:*)   bash-utils.path.error.not-found -s$sev "$1" ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.path.type()
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
bash-utils.path.type() {
  local path=${1:-'No path to test'}

  # Non-existence of the path is always fatal!!
  bash-utils.path.exists $path

  # Determine the type
  type=$(ls -ald $path) ; type=${type:0:1}

  # ... and post-process it
  case $type in
    d)  # It'#s a directory, extra work involved to determine if there's a Git
        # context
        # shellcheck disable=SC2155
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

  builtin echo $type
}

################################################################################
# Function:     bash-utils.path.is-type()
# Description:  Core function to determine if the type of the given path is the
#               same as expected i.e. as given.
# Opts:         None
# Args:         $1  - the expected type, default - 'f' i.e. plain file
#               $2  - the path to check
# Returns:      0 on STDOUT iff the types match exists, '' if not, fatal if the
#               file doesn't exist.
# To do:        Validate the given 'type'
################################################################################
bash-utils.path.is-type() {
  local type=${1:-f} path="${2:?'No path to test'}" match=

  bash-utils.path.exists -qsf $path
  
  # Exists, so continue by attempting to determine if the type matches
  case "$(ls -ald $path)" in ${type/f/-}*) match=y ;; esac

  # And report it
  builtin echo $match
}


################################################################################
# Function:     bash-utils.path.is-type()
# Description:  Core function to determine if the type of the given path is the
#               same as expected i.e. as given.
# Opts:         None
# Args:         $1  - the expected type, default - 'f' i.e. plain file
#               $2  - the path to check
# Returns:      0 on STDOUT iff the types match exists, '' if not, fatal if the
#               file doesn't exist.
# To do:        Validate the given 'type'
###############################################################################
bash-utils.path.is-dir() {
  bash-utils.path.is-type d "${1:?'No path to test'}"
}

################################################################################
# Function:     bash-utils.path.is-type()
# Description:  Core function to determine if the type of the given path is the
#               same as expected i.e. as given.
# Opts:         None
# Args:         $1  - the expected type, default - 'f' i.e. plain file
#               $2  - the path to check
# Returns:      0 on STDOUT iff the types match exists, '' if not, fatal if the
#               file doesn't exist.
# To do:        Validate the given 'type'
###############################################################################
bash-utils.path.is-file() {
  bash-utils.path.is-type f "${1:?'No path to test'}"
}

################################################################################
# Function:     bash-utils.path.get-type()
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
bash-utils.path.get-type() {
  bash-utils.path.exists -qsf "${1:?'No path to test'}"
  # shellcheck disable=SC2155
  local type="$(ls -ld $1)" ; type=${type:0:1} ; type=${type/-/f}

  case $type in
    d)  # a directory may need extra handling (it might be a Git repo element)
        # shellcheck disable=SC2155
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

  builtin echo $type
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.path.get-absolute()
# Description:  Routine to take a path and return its fully pathed equivalent.
# Takes:        $1  - path.
# Returns:      Fully pathed equivalent of the given path on STDOUT
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.path.get-absolute() {
  local path="${1:?'No path to convert'}" dir file

  # Extract the directory element iff its not a directory
  case $(bash-utils.path.is-dir "$path") in
    y)  dir="$path" ;;
    *)  dir="${path%/*}" ; file="${path##*/}" ;;
  esac

  # shellcheck disable=SC2086
  case "${1:?'No path to convert'}" in
    */*)  ( cd ${dir}>/dev/null && builtin echo $PWD${file:+/$file} ) ;;
    *)    builtin echo $PWD/$1 ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.path.is-absolute()
# Description:  Routine to take a path and determined if it's an absolute path.
# Takes:        $1  - path.
#               $2  - if given, specifies that a non-absolute path is fatal.
# Returns:      Updated STDOUT - 'y' iff the given path is absolue, 'n'
#               otherwise.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.path.is-absolute() {
  local ret ; case "${1:?'No path to test'}" in /*) ret=y ;; esac
  case ${ret:-n}:${2:-n} in
    n:n)  ;;
    n:*)  bash-utils.console.fatal "Path isn't absolute: '$1'" ;;
  esac

  builtin echo ${ret:-}
}

#### END OF FILE
