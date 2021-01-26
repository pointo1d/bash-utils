#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         tempfile.sh
# Description:  Provides an extended pure bash implementation of tempfile(1) to
#               provide portability since the core tempfile(1) isn't portable -
#               it isn't available on all platforms. The implementation extends
#               core tempfile(1) by supporting the same options with additional options to emulate the ephemerality of the creating/owning process i.e. the existence of the newly created file mirrors that of the creating process (considered to be the "owner".
#               There is also an implementation of the errexit-safe path
#               existence detection routine.
# Variables:    $TMPFILE_DEFAULT_DIR  - env var defining the default directory
#               for created temporary files - uses $TMPDIR if set.
#               $TMPDIR               - standard bash env var
################################################################################

# Early emulation of singleton behaviour
eval ${__shopt_sh_singleton__:-}
export __shopt_sh_singleton__=return

# One-off local definitions of the option type -> option mapping...
declare -A shopts_def
# And the totalizer - to enable fast (and indeed less verbose) option name
# validation
declare all_opts

#-------------------------------------------------------------------------------
# Function:     bash-utils.shell-option.init()
# Description:  Routine providing a simplified means of disabling a shell option
#               whilst facilitating easy restoration of the state.
#               the state of the given options.
# Takes:        -q    - specify quiet i.e. don't report the reset state.
#               -s OP - specify the new state for the opt(s).
# Args:         $*    - zero, or more, shell options, default - all shell opts &
#                       shopts.
# Returns:      A string is echo'ed to STDOUT which, when eval(1)ed, resets the
#               options to their previous state i.e. the state prior to
#               disabling the option.
# Variables:    None
#-------------------------------------------------------------------------------
bash-utils.shell-option.init() {
  shopts_def=(
    [shopt]="$(shopt -p | cut -d\  -f3 | xargs echo -n)"
    [opt]="$(shopt -op | cut -d\  -f3 | xargs echo -n)"
  )
  # And the totalizer - to enable fast (and indeed less verbose) option name
  # validation
  all_opts="${shopts_def[shopt]} ${shopts_def[opt]}"

  # Now ensure they're constants
  readonly shopts_def all_opts
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.shell-option.list()
# Description:  Routine providing a simplified means of disabling a shell option
#               whilst facilitating easy restoration of the state.
#               the state of the given options.
# Takes:        $*  - zero, or more, shell options, default - all shell opts &
#                     shopts.
# Returns:      A string is echo'ed to STDOUT which, when eval(1)ed, resets the
#               options to their state at the time of calling.
# Variables:    None
#-------------------------------------------------------------------------------
bash-utils.shell-option.list() {
  local opt ; for opt in ${@:-${shopts_def[shopt]} ${shopts_def[opt]}} ; do
    case "${shopts_def[shopt]}:${shopts_def[opt]}" in
      *$opt*:*)       shopts+=($opt) ;;
      *:*$opt*)       opts+=($opt) ;;
      *$opt*:*$opt*)  echo "Bad shell option: $opt" >&2 ; exit 1 ;;
      :)              echo "Shell option not found: $opt" >&2 ; exit 1 ;;
    esac
  done

  # Define the 'get current state' command as the basis
  eval ${opts[@]:+shopt -o -p ${opts[@]} ;} ${shopts[@]:+shopt -p ${shopts[@]}}
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.shell-option.change()
# Description:  Routine providing a simplified means of disabling a shell option
#               whilst facilitating easy restoration of the state.
#               the state of the given options.
# Takes:        -q    - specify quiet i.e. don't report the reset state.
#               -s OP - specify the new state for the opt(s).
# Args:         $*    - zero, or more, shell options, default - all shell opts &
#                       shopts.
# Returns:      A string is echo'ed to STDOUT which, when eval(1)ed, resets the
#               options to their previous state i.e. the state prior to
#               disabling the option.
# Variables:    None
#-------------------------------------------------------------------------------
bash-utils.shell-option.change() {
  local OPTARG OPTIND opt state opts=() shopts=() cmd
  while getopts 'qs:' opt ; do
    case $opt in
      q)  quiet=t ;;
      s)  case ${OPTARG,,} in
            enable)   state=s ;;
            disable)  state=u ;;
          esac
          ;;
    esac
  done

  shift $((OPTIND - 1))

  local opt ; for opt in ${@:-${shopts_def[shopt]} ${shopts_def[opt]}} ; do
    case "${shopts_def[shopt]}:${shopts_def[opt]}" in
      *$opt*:*)       shopts+=($opt) ;;
      *:*$opt*)       opts+=($opt) ;;
      *$opt*:*$opt*)  echo "Bad shell option: $opt" >&2 ; exit 1 ;;
      :)              echo "Shell option not found: $opt" >&2 ; exit 1 ;;
    esac
  done

  # Define the 'get current state' command as the basis
  cmd="${opts[@]:+shopt -o -p ${opts[@]} ;} ${shopts[@]:+shopt -p ${shopts[@]}}"

  # and run it if required - generates the required reset/restore string to
  # STDOUT unless running in quiet mode
  case ${quiet:+n} in n) ;; *) eval $cmd ;; esac

  # Now change the state of the selected options
  eval ${cmd//-p/-$state}
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.shell-option.disable()
# Description:  Routine providing a simplified means of disabling a shell option
#               whilst facilitating easy restoration of the state.
#               the state of the given options.
# Takes:        $*  - zero, or more, shell options, default - all shell opts &
#                     shopts.
# Returns:      A string is echo'ed to STDOUT which, when eval(1)ed, resets the
#               options to their previous state i.e. the state prior to
#               disabling the option.
# Variables:    None
#-------------------------------------------------------------------------------
bash-utils.shell-option.disable() {
  bash-utils.shell-option.change disable $@
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.shell-option.enable()
# Description:  Routine providing a simplified means of enabling a shell option
#               whilst facilitating easy restoration of the state.
# Takes:        $*  - zero, or more, shell options, default - all shell opts &
#                     shopts.
# Returns:      A string is echo'ed to STDOUT which, when eval(1)ed, resets the
#               options to their previous state i.e. the state prior to
#               enabling the option.
# Variables:    None
#-------------------------------------------------------------------------------
bash-utils.shell-option.enable() { bash-utils.shell-option.change enable $@ ; }

#-------------------------------------------------------------------------------
# Function:     bash-utils.shell-option.flip()
# Description:  Routine providing a simplified means of enabling a shell option
#               whilst facilitating easy restoration of the state.
# Takes:        $*  - zero, or more, shell options, default - all shell opts &
#                     shopts.
# Returns:      A string is echo'ed to STDOUT which, when eval(1)ed, resets the
#               options to their previous state i.e. the state prior to
#               enabling the option.
# Variables:    None
#-------------------------------------------------------------------------------
bash-utils.shell-option.flip() { bash-utils.shell-option.change enable $@ ; }

#-------------------------------------------------------------------------------
# Function:     bash-utils.shell-option()
# Description:  Routine providing a simplified means of reporting shell
#               option(s).
# Takes:        $*  - zero, or more, shell options, default - all shell opts &
#                     shopts.
# Returns:      A string is echo'ed to STDOUT which, when eval(1)ed, asserts the
#               options to their current (at the time of calling) state.
# Variables:    None
#-------------------------------------------------------------------------------
bash-utils.shell-option() { bash-utils.shell-option.list $@ ; }

bash-utils.shell-option.init

#### END OF FILE
