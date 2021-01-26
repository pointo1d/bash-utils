#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         lib.sh
# Description:  Betteredge specific test library routines - as with Betteredge
#               itself, a test campaign comprises one, or more, test cases, each
#               of which comprises one, or more, inidivdual tests. Note
#               that the code herein, although having the same foundations as
#               the Betteredge code, aren't copied & pasted from the Betteredge
#               code. Moreover, wheresoever appropriate, individual test
#               routines i.e. test.*(), mirror those made available via the Perl
#               Test::More module.
#               Since this repo was borne out of improving readability of,
#               whilst reducing c&p within betteredge there's a certain element
#               of copy & paste of from betteredge itself (to avoid unwanted,
#               inadvertent, recursion).
################################################################################
eval ${__lib_xtrace_sh__:-}
export __lib_xtrace_sh__=return

declare -rA EscapeSeqs=(
  ['bf']='$BASH_SOURCE'
  ['bs']='${BASH_SOURCE/$PWD/}'
  ['fn']='${FUNCNAME:-main}()'
  ['pa']='$BASHPID'
  ['pi']='$$'
  ['pp']='$PPID'
  ['tab']='	'
)
declare sed_cmd='' key ; for key in ${!EscapeSeqs[@]} ; do
  sed_cmd="${sed_cmd:+$sed_cmd ; } s,\\\\$key,${EscapeSeqs[$key]},g"
done
#declare -rp sed_cmd

#-------------------------------------------------------------------------------
# Function:     xtrace.set-prompt()
# Description:  Function to, as it says on the tin, set the prompt string using
#               the standard i.e. system defined, escape sequences as defined
#               here (https://tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html) supplemented by a set of extension escape sequences ...
#               \bf     - current BASH_SOURCE (full path)
#               \bs     - current BASH_SOURCE (shortened) - the fully pathed
#                         current working directory is replaced by './'
#               \fn     - the function name (with '()' appended) - where
#                         'script-main()' is used when there is no function name
#                         e.g. when running outside a function.
#               \pa     - the current actual PID (equates to/shortform of
#                         $BASHPID).
#               \pi     - the current PID (equates to/shortform of $$).
#               \pp     - the parent PID (equates to/shortform of $PPID).
#               \tab    - a tab character
# Takes:        -v NAM  - specify the name of an alternate variable to take the
#                         generated string, default - TEST_PROMPT
#               $*      - the token(s) which will form the prompt string.
# Returns:      The prompt in either the named or default ($TEST_PS4_PROMPT)
#               env var.
# Variables:    NAM     - the named/default variable to take the generated
#                         string.
#-------------------------------------------------------------------------------
xtrace.set-prompt() {
  local OPTARG OPTIND opt var=TEST_PS4_PROMPT
  while getopts 'v:' opt ; do
    case $opt in
      v)  var=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  $var="$(echo $@ | sed '')"
}

source-locn() {
  local loc=${BASH_SOURCE[1]:-}
  echo "${loc#$PWD/}"
}

#-------------------------------------------------------------------------------
# Function:     xtrace.gen-prompt()
# Description:  Function to generate the PS4 prompt (in the absence of
#               PROMPT_COMMAND operating for anything other than PS1). The
#               prompt is generated in line with either the default format or
#               the format defined using xtrace.set-prompt().
# Takes:        None
# Returns:      The prompt on $BASH_XTRACEFD
# Variables:    $BASH_XTRACEFD  - the FD on which to generate the prompt; Note
#                                 that nothing is generated if BASH_XTRACEFD is
#                                 unset/undefined.
#               $TEST_PROMPT    - the format string for the prompt.
#-------------------------------------------------------------------------------
xtrace.gen-prompt() {
  # Early bath if the xtrace FD is undefined/unset
  case ${BASH_XTRACEFD:-n} in n) return ;; esac

  local prompt= cws=${BASH_SOURCE:-main}
  echo "$prompt [${cws#'$PWD'/}]"
}

declare -rA PS4_PROMPTS=(
[default]='+	harness ($BASHPID $$, $PPID) [$(source-locn), line $LINENO]	${FUNCNAME:-main}():	'
[test-runner]='+	runner ($BASHPID, $$, $PPID) [$(source-locn), line $LINENO]	${FUNCNAME:-main}():	'
)
declare -g LAST_PS4

# Attempt to ensure that running under xtrace is both as helpful as possible and
# also STDERR is unsullied by it ... iff xtrace is currently in effect and the
# redirection hasn't already happened. Note that, once set, xtrace output is
# redirected to the FD defined in/by $BASH_XTRACEFD (well, that's the plan :-) )
case $-:"${BASH_XTRACEFD:-}" in
  *x*:) # xtrace enabled, but logging not (yet) set up, so do it
        exec {BASH_XTRACEFD}>&2
        export BASH_XTRACEFD
        set -o functrace
        ;;&
  *x*)  # xtrace is enabled, so set/update it according to context
        #declare -p BASH_SOURCE LINENO FUNCNAME

        # Save the prompt - for restoration at shell exit
        export LAST_PS4="$PS4"
        trap 'set -x ; PS4="$OLD_PS4"' EXIT

        case ${TEST_RUNNER:-n} in
          n)  # All outward appearances suggest a call from script level
              PS4="${PS4_PROMPTS[default]}"
              ;;
          *)  # Call appears to have test runner provence
              PS4="${PS4_PROMPTS[test-runner]}"
              ;;
        esac
        ;;
esac

#### END OF FILE
