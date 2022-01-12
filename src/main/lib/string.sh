#! /usr/bin/env bash
################################################################################
# File:		lib.string.sh
# Description:	Bash library providing console related routines in a stricture
#               compliant manner i.e. tests are performed in a manner which
#               won't trigger errexit, nounset or ???? shell traps if set.
################################################################################

eval ${LIB_STRING_SH:-}
export LIB_STRING_SH=return

# ------------------------------------------------------------------------------
# Function:     lib.string.is-empty()
# Description:  String library function to determine if the given string is an
#               unsigned integer (or not) i.e. an integer with a leading '+' or
#               '-'.
# Takes:        -f  - generate fatal error if the given string isn't an unsigned
#                     integer, default - non-fatal (error handling left to
#                     caller).
# Args:         STRING  - the string to be tested.
# Returns:      Either 'y' or 'n' on STDOUT
# Env vars:     None
# ------------------------------------------------------------------------------
lib.string.is-empty() {
  local OPTARG OPTERR= OPTIND opt fatal=
  while getopts 'f' opt 2>/dev/null ; do
    case $opt in
      f)  fatal=t ;;
      ?)  echo n ; return ;;
    esac
  done

  shift $((OPTIND - 1))

  case "${1:-y}" in
    y)  echo y ;;
    *)  case ${fatal:-n} in
          n)  echo n ;;
          *)  lib.console.to-stderr "FATAL!!! Not an unsigned integer: $*"
              exit 1
              ;;
        esac
        ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.string.is-non-empty()
# Description:  String library function to determine if the given string is an
#               unsigned integer (or not) i.e. an integer with a leading '+' or
#               '-'.
# Takes:        -f  - generate fatal error if the given string isn't an unsigned
#                     integer, default - non-fatal (error handling left to
#                     caller).
# Args:         STRING  - the string to be tested.
# Returns:      Either 'y' or 'n' on STDOUT
# Env vars:     None
# ------------------------------------------------------------------------------
lib.string.is-non-empty() {
  local OPTARG OPTERR= OPTIND opt fatal=
  while getopts 'f' opt 2>/dev/null ; do
    case $opt in
      f)  fatal=t ;;
      ?)  echo n ; return ;;
    esac
  done

  shift $((OPTIND - 1))

  case "${@:+y}" in
    y)  echo y ;;
    *)  case ${fatal:-n} in
          n)  echo n ;;
          *)  lib.console.to-stderr "FATAL!!! Not an unsigned integer: $*"
              exit 1
              ;;
        esac
        ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.string.is-unsigned-int()
# Description:  String library function to determine if the given string is an
#               unsigned integer (or not) i.e. an integer with a leading '+' or
#               '-'.
# Takes:        -f  - generate fatal error if the given string isn't an unsigned
#                     integer, default - non-fatal (error handling left to
#                     caller).
# Args:         STRING  - the string to be tested.
# Returns:      Either 'y' or 'n' on STDOUT
# Env vars:     None
# ------------------------------------------------------------------------------
lib.string.is-unsigned-int() {
  local OPTARG OPTERR= OPTIND opt fatal=
  while getopts 'f' opt 2>/dev/null ; do
    case $opt in
      f)  fatal=t ;;
      ?)  echo n ; return ;;
    esac
  done

  shift $((OPTIND - 1))

  case "u${*//[0-9]/}" in
    u)  echo y ;;
    *)  case ${fatal:-n} in
          n)  echo n ;;
          *)  lib.console.to-stderr "FATAL!!! Not an unsigned integer: $*"
              exit 1
              ;;
        esac
        ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.string.is-signed-int()
# Description:  String library function to determine if the given string is an
#               unsigned integer (or not).
# Takes:        -f  - generate fatal error if the given string isn't a +ve
#                     integer, default - non-fatal (error handling left to
#                     caller).
# Args:         STRING  - the string to be tested.
# Returns:      Either 'y' or 'n' on STDOUT
# Env vars:     None
# ------------------------------------------------------------------------------
lib.string.is-signed-int() {
  local OPTARG OPTIND opt fatal=
  while getopts 'f' opt ; do
    case $opt in
      f)  fatal=t ;;
    esac
  done

  shift $((OPTIND - 1))

  case "$*" in
    [-+]*)  case "$(lib.string.is-unsigned-int "${*/[-+]/}")" in
              y)  echo y
                  return
                  ;;
            esac
  esac

  case ${fatal:-n} in
    n)  echo n ;;
    *)  lib.console.to-stderr "FATAL!!! Not a signed integer: $*" ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.string.is-+ve-int()
# Description:  String library function to determine if the given string is a
#               positive integer (or not).
# Takes:        -f  - generate fatal error if the given string isn't a +ve
#                     integer, default - non-fatal (error handling left to
#                     caller).
# Args:         STRING  - the string to be tested.
# Returns:      Either 'y' or 'n' on STDOUT
# Env vars:     None
# ------------------------------------------------------------------------------
lib.string.is-+ve-int() {
  local OPTARG OPTIND opt fatal=
  while getopts 'f' opt ; do
    case $opt in
      f)  fatal=t ;;
    esac
  done

  shift $((OPTIND - 1))

  case i${*//[0-9]/} in
    i|i+)  echo y ;;
    *)    case ${fatal:-n} in
            n)  echo n ;;
            *)  lib.console.to-stderr "FATAL!!! Not an integer: $*"
                exit 1
                ;;
          esac
          ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.string.is--ve-int()
# Description:  String library function to determine if the given string is a
#               positive integer (or not).
# Takes:        -f  - generate fatal error if the given string isn't a +ve
#                     integer, default - non-fatal (error handling left to
#                     caller).
# Args:         STRING  - the string to be tested.
# Returns:      Either 'y' or 'n' on STDOUT
# Env vars:     None
# ------------------------------------------------------------------------------
lib.string.is--ve-int() {
  local OPTARG OPTIND opt fatal=
  while getopts 'f' opt ; do
    case $opt in
      f)  fatal=t ;;
    esac
  done

  shift $((OPTIND - 1))

  case ${*//[0-9]/} in
    -)  echo y ;;
    *)  case ${fatal:-n} in
          n)  echo n ;;
          *)  lib.console.to-stderr "FATAL!!! Not an integer: $*"
              exit 1
              ;;
        esac
        ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     lib.string.is-int()
# Description:  String library function to determine if the given string is an
#               integer, unsigned or otherwise, (or not).
# Takes:        -f  - generate fatal error if the given string isn't a +ve
#                     integer, default - non-fatal (error handling left to
#                     caller).
#               -s SEV  - specify the severity of the response if the string is
#                         not an integer
# Args:         STRING  - the string to be tested.
# Returns:      Either 'y' or 'n' on STDOUT
# Env vars:     None
# ------------------------------------------------------------------------------
lib.string.is-int() {
  local OPTARG OPTIND opt fatal=
  while getopts 'f' opt ; do
    case $opt in
      f)  fatal=t ;;
    esac
  done

  shift $((OPTIND - 1))
  local val=${1:?'No string'}

  case $(lib.string.is-unsigned-int ${val/[-+]}) in
    y)  echo y ;;
    *)  case ${fatal:-n} in
          n)  echo n ;;
          *)  lib.console.to-stderr "FATAL!!! Not an integer: $*"
              exit 1
              ;;
        esac
        ;;
  esac
}

#### END OF FILE
