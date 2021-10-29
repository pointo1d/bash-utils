#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         sinclude.sh
# Description:  Pure bash(1) script to provide a recursive inclusion avoiding
#               file inclusion capability.
###############################################O################################

# Use bespoke recursive inclusion in here only
#eval ${_LIB_SINCLUDE_SH_:-}
#export _LIB_SINCLUDE_SH_=return

# Define the inclusion record - whose initial value is this file itself
declare -A Included

sinclude.to-stderr() { builtin echo -e "$@" >&2 ; }

# Define the loading announcer 1st and very early since it may be used
# internally i.e. as this script is loading
# ------------------------------------------------------------------------------
# Function:     sinclude.announce-loading()
# Description:  
# Takes:        $1  - lib short name
#               $2  - lib path
# Returns:      
# Variables:    
# ------------------------------------------------------------------------------
sinclude.announce-loading() {
  case ${SINCLUDE_VERBOSE:+y} in
    y)  local name="$1" path="$2"
        builtin echo -e "Load lib: $name ($path) - Starting... \c"
        ;;
  esac
}

abs-path() { echo $(cd $(dirname $1)>/dev/null && pwd)/${1##*/} ; }

# Define shorthands for self
declare "sself=${BASH_SOURCE##*/}" pself="$(abs-path $BASH_SOURCE)"
declare dself="${pself%/*}"

# And use 'em to update PATH for this session
export PATH="$dself:$PATH"
sinclude.announce-loading "$pself"

# ------------------------------------------------------------------------------
# Function:     sinclude.announce-loaded()
# Description:  
# Takes:        $1  - lib short name
#               $2  - lib path
# Returns:      
# Variables:    None..
# # ------------------------------------------------------------------------------
sinclude.announce-loaded() {
  case ${SINCLUDE_VERBOSE:+y} in
    y)  local name="$1" path="$2"
        builtin echo -e Done
        ;;
  esac
}

sinclude.fatal() { sinclude.to-stderr "FATAL!!! $@" ; exit 1 ; }

# ------------------------------------------------------------------------------
# Function:     lib.sinclude()
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
lib.sinclude() {
  : $#
  case $# in 0) sinclude.fatal 'Nothing to load/include' ;; esac
  #pself="$(abs-path $BASH_SOURCE)"
  #PATH=${pself%/*}:$PATH
  local lib nm dir ; for lib in ${@:?'No library'} ; do
    : $lib

    case $lib in
      /*) # Absolutely pathed, so nowt else to do
            fpath=$lib
            ;;
      *)    # Else use a locally updated PATH - if there's anything with which
            # to update it ;-)
            #local self_path="$(cd ${BASH_SOURCE%/*} >/dev/null && pwd)"
            local path IFS=':'
            PATH=${SINCLUDE_PATH:+$SINCLUDE_PATH:}$PATH:EOL
            for path in $PATH ; do
              : $path
              case $path in
                EOL)  sinclude.fatal "Library not found: $lib" ;;
              esac

              local _lib="$(ls -ld $path/$lib* 2>/dev/null| sed -n '/^-/s,.* /,/,p' )"
              : $lib, "${_lib:-n}"
              case "${_lib:-n}" in
                n)        # Not found on the current path
                          continue
                          ;;
                *$lib|\
                *$lib.sh) # Found one, so use it 
                          fpath="$_lib"
                          break
                          ;;
              esac
            done
            ;;
    esac

    : SINCLUDE_VERBOSE - ${SINCLUDE_VERBOSE:-unset}
    case "${Included[$BASHPID]}" in
      *$lib)  sinclude.announce-loaded $lib $fpath ;;
      *)      sinclude.announce-loading $lib $fpath 
              builtin . $fpath
              Included+=( [$BASHPID]=$fpath )
              sinclude.announce-loaded $lib $fpath
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

# Finally initialise the loaded record (with this file) ...
Included=( [$BASHPID]=$(abs-path $BASH_SOURCE) )

# and ensure the loaded message is generated if aapropriate
sinclude.announce-loaded "$sself" "$pself"

#### END OF FILE
