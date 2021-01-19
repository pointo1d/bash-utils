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

declare -rA PS4_PROMPTS=(
  [default]='+	main ($BASHPID $$, $PPID) [${BASH_SOURCE#'$PWD'/}, $LINENO]	${FUNCNAME:-main}():	'
  [test-runner]='+	runner ($BASHPID, $$, $PPID) [${BASH_SOURCE#'$PWD'/}, $LINENO]	${FUNCNAME:-main}():	'
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
        declare -p BASH_SOURCE LINENO FUNCNAME

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
