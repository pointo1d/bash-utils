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
eval ${BASH_UTILS_ROOT_DIR:+return}

# Next, as this is a test library, ensure that the test code always runs under
# and indeed can properly handle, maximum strictures i.e. fails fast - the test
# code is (s/b :-)) written defensively such that SIGERR always causes failure
# and $TEST_FAIL_FAST determines the strategy for the test(s) being run
set -e

# Start by loading the xtrace test library; Note that this attempts a context
# sensitive auto-setting dependant on the context i.e. either default or test
# runner/harness - if the former, then the calling function will be 'main'
. ${BASH_SOURCE/lib.sh/xtrace.sh}

# Load the trap related definitions
. ${BASH_SOURCE/lib.sh/trap.sh}

# Having done that, ensure that the strictures are enforced for the test code
shopt -so errexit errtrace nounset pipefail ; shopt -s inherit_errexit

export BASH_UTILS_ROOT_DIR=$(git -C ${BASH_SOURCE%/*} rev-parse --show-toplevel)
export BASH_UTILS_SRC_DIR=$BASH_UTILS_ROOT_DIR/src
export BASH_UTILS_MAIN_DIR=$BASH_UTILS_SRC_DIR/main
export BASH_UTILS_MAIN_LIB_DIR=$BASH_UTILS_MAIN_DIR/lib
export BASH_UTILS_TEST_DIR=$BASH_UTILS_SRC_DIR/test
export BASH_UTILS_TEST_LIB_DIR=$BASH_UTILS_TEST_DIR/lib
export BASH_UTILS_TEST_LIB=$BASH_UTILS_TEST_LIB_DIR/lib.sh

# Test harness global list
declare GlobalFieldPrintLength=0 TestGlobals=(
  TEST_ROOT_PID=$BASHPID
  TEST_SCRIPT TEST_OUT TEST_FAIL_FAST TEST_VERBOSE
  TEST_DEFN TEST_EXIT_CODE TEST_OUTPUT TEST_STDOUT_CAPTURE TEST_STDERR_CAPTURE
  TEST_RUNNER_CONTEXT TEST_RESULTS TEST_RESULTS_COLOURED
)
# Having now defined the test globals, ensure that both they're exported and
# their lenght is known (for formatted printing/reporting
declare gv ; for gv in ${TestGlobals[@]} ; do
  export $gv
  case $(($GlobalFieldPrintLength - ${#gv})) in
    -*) GlobalFieldPrintLength=${#gv} ;;
  esac
done

# Ensure the field print length is properly asjusted and constant
((GlobalFieldPrintLength += 2))
readonly GlobalFieldPrintLength

# Internal globals
declare -A Stats TEST_DEFN=(
    [num]= [desc]= [diag]= [run-candidate]= [updated]= [code-to-run]=
    [outcome]= [result]= [stdout]= [stderr]=
)
Stats=( [total]=0 [passed]=0 [failed]=0 [skipped]=0 [todo]=0 )
declare Tests=("$@") Strictures= TapVersion=13

#-------------------------------------------------------------------------------
# Function:     test.diag()
# Description:  Emulating perls' Test::More::diag(), given one, or more lines of
#               text, this function reports each in a TAP compliant manner i.e.
#               with a leading '#' prefix
#-------------------------------------------------------------------------------
test.diag() { echo -e "# $*" ; }

#-------------------------------------------------------------------------------
# Function:     test.bail-out()
# Description:  An extension to perls' Test::bail_out(), this function also
# allows 
#-------------------------------------------------------------------------------
test.bail-out() {
  local OPTARG OPTIND opt kill
  while getopts 'k' opt ; do
    case $opt in
      k)  kill=t ;;
    esac
  done

  shift $((OPTIND - 1))

  echo -e "Bail out! $*" >&2
  case ${kill:+y} in y) kill -9 $$ ;; *) exit 1 ;; esac
}

#-------------------------------------------------------------------------------
# Function:     test.strictures.unapply()
# Description:  
#-------------------------------------------------------------------------------
test.strictures.unapply() {
  Strictures="$(shopt -po errexit errtrace nounset)"
  shopt -ou errexit errtrace nounset
}

#-------------------------------------------------------------------------------
# Function:     test.strictures.restore()
# Description:  
#-------------------------------------------------------------------------------
test.strictures.restore() { eval $Strictures ; }

#-------------------------------------------------------------------------------
# Function:     test.lib.tempfile()
# Description:  Routine to provide wrapper round tempfile(1) such that the file
#               is auto-deleted when the shell exits for whatever reason.
# Takes:        $1  - optional name of a variable in which to record the name of
#                     the temporary file.
# Returns:      The name of the temp file on STDOUT iff $1 is not given.
#-------------------------------------------------------------------------------
test.lib.tempfile() {
  local fname=$(tempfile) vname=${1:-}

  local sigs=(EXIT HUP INT TERM)

  local sig ; for sig in ${sigs[@]} ; do
    local code="$(trap -p $sig | sed -n "s,[^']* '\(.*\)' .*,\1,p")"

    case ${#code} in
      0)  code="rm $fname" ;;
      *)  code="$code $fname" ;;
    esac

    trap "$code" $sig
  done

  case v$vname in
    v)  echo $fname ;;
    *)  eval export $vname=$fname ;;
  esac
}

test-runner.propagate-vars() {
  local var_names=(
    BASH_XTRACEFD
    TEST_STDERR_CAPTURE TEST_STDOUT_CAPTURE TEST_FAIL_FAST TEST_VERBOSE TEST_SUBSHELL_RESULTS
  )

  local var val ; for var in ${var_names[@]} ; do
    local -n vname=$var ; echo "$var='${vname:-}'"
  done
}

##-------------------------------------------------------------------------------
## Function:     test.lib.safe-run()
## Description:  Routine to provide wrapper round tempfile(1) such that the file
##               is auto-deleted when the shell exits for whatever reason.
## Takes:        $1  - optional name of a variable in which to record the name of
##                     the temporary file.
## Returns:      The name of the temp file on STDOUT iff $1 is not given.
##-------------------------------------------------------------------------------
#test.lib.safe-run() {
#  local OPTARG OPTIND opt silent opts=()
#  while getopts 'c:qo:' opt ; do
#    case $opt in
#      c)  local idx ; for idx in $(seq 0 ${#OPTARG[@]}) ; do
#            local char=${OPTARG:$idx:1} ftype=
#
#            case $char in
#              e)  ftype=stderr ;;
#              o)  ftype=stdout ;;
#              *)  test.bail-out "Unknown capture type: $OPTARG" ;;
#            esac
#
#            : $ftype
#            test.lib.tempfile tmp
#            TEST_DEFN[$ftype]=$tmp
#          done
#          ;;
#      o)  bash_opts+=($OPTARG) ;;
#      q)  silent=t ;;
#    esac
#  done
#
#  shift $(( OPTIND - 1 ))
#
#  local code="${TEST_DEFN[code-to-run]:="$@"}"
#
#  #test.strictures.unapply
#
#  (
#    exec env -i \
#      "PS4='$PS4'" "PATH=$PATH" \
#      bash ${bash_opts:+"-${bash_opts[@]}"}
#      <<!
#${code:?'No condition code'}
#$@
#!
#  )
#  TEST_DEFN[rc]=$?
#
##typeset -p TEST_DEFN
#
#  test.strictures.restore
#
#  case "$silent" in t) ;; *) echo ${TEST_DEFN[rc]} ;; esac
##typeset -p TEST_DEFN
#}
#
##-------------------------------------------------------------------------------
## Function:     test.state.init()
## Description:  
##-------------------------------------------------------------------------------
#test.state.init() {
#  local key val ; for key in ${!TEST_DEFN[@]} ; do
#    case $key in
#      num)            val=$(( Stats[total] + 1 )) ;;
#      desc)           val="${2:?'Missing test description'}" ;;
#      diag)           val="$3" ;;
#      code-to-run)    val="${1:?'Missing code to run'}" ;;
#      std*)           continue ;;
#      result|\
#      updated|\
#      run-candidate)  val='' ;;
#    esac
#
#    TEST_DEFN[$key]="$val"
#  done
#}
#
##-------------------------------------------------------------------------------
## Function:     test.lib.set-run-candidacy()
## Description:  
##-------------------------------------------------------------------------------
#test.lib.set-run-candidacy() {
#  # Don't bother if the update has already been run
#  case "${TEST_DEFN[updated]}" in t) return ;; esac
#
#  # Assume all are candidates unless otherwise stated - either individually
#  # selected on the CLI or de-selected (via the description)
#  case "$TEST_DEFN[desc],,}" in
#    \#\ todo\ *)  # Individually marked as todo
#                  TEST_DEFN[run-candidate]=todo
#                  ;;
#    \#\ skip\ *)  # Individually marked as skip
#                  TEST_DEFN[run-candidate]=skip
#                  ;;
#    *)            # Not individually marked, so see if it's been deselected on
#                  # the CLI
#                  local num=${TEST_DEFN[num]}
#
#                  case ${#Tests[@]}:"$(echo ${Tests[@]} | grep -wo $num)" in
#                    0:)     # No CLI selection criteria or selected via CLI, so
#                            # flag it accordingly
#                            TEST_DEFN[run-candidate]=run
#                            ;;
#                    *:$num) # Selected via CLI, so flag it accordingly
#                            TEST_DEFN[run-candidate]=run
#                            ;;
#                    *:)     # Deselected via CLI, so flag it accordingly
#                            TEST_DEFN[run-candidate]=skip-cli
#                            ;;
#                  esac
#                  ;;
#  esac
#}
#
##-------------------------------------------------------------------------------
## Function:     test.lib.run-it()
## Description:  
##-------------------------------------------------------------------------------
#test.lib.run-it() {
#  local cond_type="$1"
#
#  # Update the candidacy
#  test.lib.set-run-candidacy
#
#  echo -ne "${TEST_DEFN[num]} ${TEST_DEFN[desc]}"
#
#  # Now act on the updated candidacy i.e. run the test accordingly
#  case ${TEST_DEFN[run-candidate]} in
#    run)      case "cond_type" in
#                num)  ;;
#                str)  ;;
#                # eval) test.lib.safe-eval ;;
#                *)    test.lib.safe-run ;;
#              esac
#              ;;
#    todo)     : $(( TEST_DEFN[todo]++ ))
#              ;;&
#    skip-cli) TEST_DEFN[desc]="# skipped (not selected on CLI) - ${TEST_DEFN[desc]}"
#              ;;&
#    skip)     : $(( Stats[skipped]++ ))
#              TEST_DEFN[outcome]=ok
#              ;;
#  esac
#
#  # Now record the outcome
#  case "${TEST_DEFN[outcome]}" in
#    ok) : $(( Stats[passed]++ )) ;;
#    *)  : $(( Stats[failed]++ )) ;;
#  esac
#
#
#  # Finally, update the totaliser
#  : $(( Stats[total]++ ))
#}
#
##-------------------------------------------------------------------------------
## Function:     test.lib.result()
## Description:  
##-------------------------------------------------------------------------------
#test.lib.result() {
#  echo -e "\r${TEST_DEFN[outcome]} ${TEST_DEFN[num]} ${TEST_DEFN[desc]}"
#}

run-command() {
  # Get the code of the arg stack
  local code="${1:?'No code to excute'}"

  export TEST_STDERR_CAPTURE=$(tempfile) TEST_STDOUT_CAPTURE=$(tempfile)
  trap "rm -f $TEST_STDERR_CAPTURE $TEST_STDOUT_CAPTURE" EXIT

  # Now the current state of the strictures ... following which, disable them in
  # order to facilitate handling of errors at this level. - use shopt(1) for
  # readability (don't need to specify +o for each option as would be the case
  # with set(1))
  local strictures="$(shopt -po errexit errtrace nounset pipefail)"
  shopt -uo errexit errtrace nounset pipefail
  
  (
    exec -c \
    env -i \
      PATH=$(getconf PATH) \
      BASH_XTRACEFD=${BASH_XTRACEFD:-} \
      TEST_STDERR_CAPTURE=$TEST_STDERR_CAPTURE \
      TEST_STDOUT_CAPTURE=$TEST_STDOUT_CAPTURE \
      strictures="$strictures" \
    bash <<EOC
      trap -p
      exec 1>$TEST_STDERR_CAPTURE 2>$TEST_STDOUT_CAPTURE
      eval $strictures

      $code
EOC
  )

  export TEST_EXIT_CODE=$?

  # Having now setup the environment for the callers' testing, re-assert the
  # strictures
  eval $Strictures
}

#-------------------------------------------------------------------------------
# Function:     test.campaign.init()
# Description:  
#-------------------------------------------------------------------------------
test.campaign.init() {
  # Coz it's nice to be nice, the consumer gets the TEST_OUT definition for free :)
  export TEST_OUT="$1"

#  case ${#STDOUT} in
#    0)  STDOUT=$(tempfile) STDERR=$(tempfile)
#        trap "set -x ; rm -f $STDOUT $STDERR" 0 1 2 15
#        ;;
#  esac

  # Disable loading of xtrace library where appropriate i.e. if not already done
  # and xtrace.sh is not the TEST_OUT
  case "$TEST_OUT":${#__XTRACE_SH} in
    */xtrace.sh:) ;;
    *.sh:)        export __XTRACE_SH=t ;;
    :*)           test.bail-out "No TEST_OUT" ;;
  esac
}

#-------------------------------------------------------------------------------
# Function:     test.campaign.start()
# Description:  
#-------------------------------------------------------------------------------
test.campaign.start() {
  case ${TEST_OUT:+y} in y) return ;; esac
  echo "TAP Version $TapVersion"
}

#-------------------------------------------------------------------------------
# Function:     test.campaign.done()
# Description:  
#-------------------------------------------------------------------------------
test.campaign.done() {
  local total=${Stats[total]} failed=${Stats[failed]} passed=${Stats[passed]}

  local okay=$(printf "%2.2f" $(( ( passed * 100 / total * 100 ) / 100 )))
  local skipped=$(case $passed in $total) echo ${Stats[skipped]} ;; esac)

  echo -e "
1..$total
Failed $failed/$total tests, ${okay}% okay
"
}

test.script.done() {
  echo "1..${Stats[total]}"
}


#-------------------------------------------------------------------------------
# Function:     test.script.start()
# Description:  Function to perform the activities required at each test script
#               start-up - including, but not limited to,...
#               * Reporting the values of all global env vars having an impact
#                 on the test and how it's conducted
# Takes:        None
# Returns:      None
# Variables:    $TEST_VERBOSE - the variables are reported iff the verbosity is
#                               set to anything higher than default i.e. /v+/
#               Defined in/by $TestGlobals
#-------------------------------------------------------------------------------
test.script.start() {
  declare -g TEST_OUT="$1" TEST_SCRIPT="${BASH_SOURCE[1]}"

  case ${TEST_VERBOSE:-n} in
    v*)  (
            set +ueE
            local var ; while read var ; do
              local val=unset
              : $var
              case "${var:-n}" in
                n)    continue ;;
                *=*)  val=${var#*=}
                      var=${var%=*}
                      ;;
                *)    val=${!var}
                      ;;
              esac

              test.diag "$(
                printf '%-'${GlobalFieldPrintLength}'s- %s' \
                  $var ${val:-unset}
              )"
            done < <(printf '%s\n' ${TestGlobals[@]} | sort)
        )
        ;;
  esac
}

. ${BASH_SOURCE//lib./assert.}

test.campaign.start

#### END OF FILE
