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
  TEST_SCRIPT TEST_OUT TEST_FAIL_FAST TEST_VERBOSE
  TEST_DEFN TEST_EXIT_CODE TEST_OUTPUT TEST_STDOUT TEST_STDERR
  TEST_RESULTS TEST_RESULTS_COLOURED
)
declare gv ; for gv in ${TestGlobals[@]} ; do
  export $gv
#    local var longest=0 ; for var in ${TestGlobals[@]} ; do
  case $(($GlobalFieldPrintLength - ${#gv})) in
    -*) GlobalFieldPrintLength=${#gv} ;;
  esac
done

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
    TEST_STDERR TEST_STDOUT TEST_FAIL_FAST TEST_VERBOSE TEST_SUBSHELL_RESULTS
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

################################################################################
####  INDIVIDUAL TEST ASSERTIONS
################################################################################
#-------------------------------------------------------------------------------
# Function:     test.assert.ok()
# Description:  Base routine asserting that the given condition holds true,
#               where true is interpreted as either eval'lable code that returns
#               true i.e. 0, when either run or eval'led or an integer value of
#               0.
# Takes:        -t TYP      - option to force the type/nature of the condition
#                             to be explicit - as one of the following (case
#                             insensitive)...
#                             * CODE  - run'lable code.
#                             * EVAL  - eval'lable code.
#                             * INT   - one, or more digits.
#                             * STR   - anything other than the above.
#                             By default, i.e. if '-t TYP' is not used, the
#                             assumption is made that the condition is
#                             eval'lable code.
#               $1          - the condition to be tested.
#               $2          - a description of the test.
#               $3          - optional diagnostic code - eval'led iff the given
#                             code does not hold true i.e. the given assertion
#                             fails.
# Returns:      None.
# Variables:    $TEST_DEFN  - the test data definition.
#-------------------------------------------------------------------------------
test.assert.ok() {
  local OPTARG OPTIND opt cond_type
  while getopts 't:' opt ; do
    case $opt in
      t)  case ${OPTARG,,} in
            int|\
            str|\
            code|\
            eval) cond_type=$OPTARG ;;
          esac
          ;;
    esac
  done

  shift $((OPTIND - 1))

  test.state.init "$1" "$2" "$3"

  test.lib.run-it "$cond_type"

  test.lib.result
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
test.assert.ok() {
  local desc="${1:?'No description'}" code="${2?'No condition code'}" \
    colour=
  case ${PS1:+y}:${TEST_RESULTS_COLOURED:+y} in *y*) colour=t ;; *) ;; esac

  echo -en "$desc"

  local rc=$( set +eE ; eval $code ; echo $? )

  : $((Stats[total] += 1))

  case $rc in
    0)  : $((Stats[passed] += 1))
        colour=${colour:+"\u001b[32m"}
        res=ok
        ;;
    *)  : $((Stats[failed] += 1))
        colour=${colour:+"\u001b[31m"}
        res="not ok"
        ;;
  esac

  echo -e "\r${colour:+$colour}$res - $desc${colour:+\u001b[0m}"

  case "$res" in ok) return ;; esac

  test.diag " Failure condition: $code"
}

test.script.done() {
  echo "1..${Stats[total]}"
}

#-------------------------------------------------------------------------------
# Function:     test.extend-trap()
# Description:  Function to append the given code to the given trap
# Takes:        $1  - signal name or number (integer :)
#               $*  - the code with which to extend the trap for the given
#                     signal
# Returns:      None
# Variables:    None
#-------------------------------------------------------------------------------
test.extend-trap() {
  local sig=${1:?'No sig name or number'} traps=() code=() ; shift

  # Get the current trap defn & extract the code therefrom
  traps=($(trap -p $sig)) ; code="${traps[@]:2:${#traps[@]} - 3}"

  # Now 'do; the update
  eval "trap -- '$@ ;'$code $sig $sig"
}

#-------------------------------------------------------------------------------
# Function:     test.runner.tear-down()
# Description:  Function, as it says on the tin, to perform the/any tear-down
#               required for test.runner.run-command().
# Takes:        None
#               None
# Returns:      None
# Variables:    $TEST_RUNNER  - determines whether test.runner.run-command() was
#                               run in self-contained mode.
#-------------------------------------------------------------------------------
test.runner.tear-down() {
  :
}

#-------------------------------------------------------------------------------
# Function:     test.test-runner.stand-up()
# Description:  Routine, as it says on the tin, to stand-up a self-contained
#               stand-alone test harness environment - typically as created by a
#               call to test.run-command() -t.
# Takes:        None
# Returns:      None
# Variables:    $TEST_RUNNER  - determines whether test.runner.run-command() is
#                               to be run in self-contained mode.
#-------------------------------------------------------------------------------
test.test-runner.stand-up() {
  test.extend-trap EXIT test.runner.tear-down
}

#-------------------------------------------------------------------------------
# Function:     test.run-command()
# Description:  Routine to run the given command in a virgin environment i.e.
#               minimal PATH (as defined by getconf(1)). The exit code, stdout &
#               stderr are all captured in global env vars (see below).
# Takes:        -t  - specify that the command is to be run as a self-contained
#                     test harness i.e. load this library and run the code
#                     using test.* functions. The result of the run will be 
# Returns:      None directly.
# Variables:    TEST_STDOUT           -
#                 Name of the ephemeral stdout capture file.
#               TEST_STDERR           -
#                 Name of the ephemeral stderr capture file.
#               BASH_XTRACEFD         -
#                 if set, defines the file descriptor to which xtrace output is
#                 redirected
#               TEST_SUBSHELL_RESULTS -
#                 FD for the stream to which the results are reported if running
#                 under self-contained test harness i.e. '-t', conditions.
#-------------------------------------------------------------------------------
test.run-command() {
  local OPTARG OPTIND opt
  while getopts 't' opt ; do
    case $opt in
      t)  export TEST_RUNNER=t ;;
    esac
  done

  shift $((OPTIND - 1)) ; local code="${1:?'No code to run'}"

  case ${TEST_RUNNER:+y} in
    y)  code=". $BASH_UTILS_TEST_LIB ; test.test-runner.stand-up ; $code"
        ;;
    *)  shopt="$(shopt -p ; shopt -op)" 
        TEST_STDERR=$(tempfile) TEST_STDOUT=$(tempfile)
        trap "rm -f $TEST_STDERR $TEST_STDOUT" EXIT
  esac

  # Whatever happens, any errors stemming from the following must be handled by
  # the harness, so disable fast-fail until the outcome has been
  # established i.e. later.
  local shopt="$(shopt -op errexit ; shopt -p inherit_errexit)"
  shopt -ou errexit ; shopt -u inherit_errexit

  (
    set +u
    local globals="$(
      PS4="$PS4"
      for gv in ${TestGlobals[@]} ; do echo "$gv='${!gv}'" ; done
    )"

    exec -c \
    env -i PATH=$(getconf PATH) \
      BASH_XTRACEFD=${BASH_XTRACEFD:-} TEST_RUNNER=t $globals \
    bash -$- <<EOC
      exec >${TEST_STDOUT:-/dev/stdout} 2>${TEST_STDERR:-/dev/stderr}

      #echo $TEST_FAIL_FAST >&$TEST_RESULTS
      $code
EOC
  )

  export TEST_EXIT_CODE=$? TEST_STDERR TEST_STDOUT \
    TEST_OUTPUT="$(<${TEST_STDERR:-/dev/null})$(<${TEST_STDOUT:-/dev/null})"

  eval $shopt
}

################################################################################
####  TEST CASE ASSERTIONS
################################################################################
#-------------------------------------------------------------------------------
# Function:     test.case.assert.syntax-ok()
# Description:  Test case asserting the correct syntax for the TEST_OUT.
# Takes:        $1          - optional out path name, default given in/by $TEST_OUT.
# Returns:      None.
# Variables:    $TEST_OUT        - the path name for the TEST_OUT.
#               $TEST_DEFN  - the test data definition,
#-------------------------------------------------------------------------------
test.case.assert.syntax-ok() {
  test.lib.safe-run -qon -ceo "${1:?'No TEST_OUT'}"

  test.assert.ok "test ${TEST_DEFN[rc]} = 0" 'Syntax check - rc' '0'
  test.assert.ok "test '$(< ${TEST_DEFN[stderr]})' = ''" \
    'Syntax check - STDERR' "$(< ${TEST_DEFN[stderr]})"
}

#-------------------------------------------------------------------------------
# Function:     test.case.assert.dots-ok()
# Description:  Test case asserting that the TEST_OUT can be dot'ted/source'd ok.
# Takes:        $1          - optional out path name, default given in/by $TEST_OUT.
# Returns:      None.
# Variables:    $TEST_OUT        - the path name for the TEST_OUT.
#               $TEST_DEFN  - the test data definition,
#-------------------------------------------------------------------------------
test.case.assert.dots-ok() {
  test.lib.safe-run -q -ceo ". ${1:?'No TEST_OUT'}"

  test.assert.ok "test ${TEST_DEFN[rc]} = 0" 'dotted file - rc' '0'
  test.assert.ok "[[ '$(< ${TEST_DEFN[stdout]})' =~ TAP\ Version\ \d+ ]]" \
    'dotted file - STDOUT' "$(<${TEST_DEFN[stdout]})"
  test.assert.ok "test '$(< ${TEST_DEFN[stderr]})'" \
    'dotted file - STDERR' "$(<${TEST_DEFN[stderr]})"
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
test.assert.command.exit-code.success() {
  local extra_desc="${1:-}"
  test.assert.ok \
    "Success exit code${extra_desc:+ - $extra_desc}" \
    "test $TEST_EXIT_CODE = 0"
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
test.assert.command.exit-code.fail() {
  local extra_desc="$1" val=$2
  local desc="Fail exit code${extra_desc:+ - $extra_desc}"

  case ${val:-y} in
    y)  test.assert.ok 'Fail exit code' \
          "test $TEST_EXIT_CODE = $val"
        ;; 
    *)  test.assert.ok '${desc//F/Specific f' \
          "test $TEST_EXIT_CODE != 0"
        ;;
  esac
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
              val=${!var}
              test.diag "$(
                printf '%-'${GlobalFieldPrintLength}'s- %s' $var ${val:-unset}
              )"
            done < <(printf '%s\n' ${TestGlobals[@]} | sort)
        )
        ;;
  esac
}

#-------------------------------------------------------------------------------
# Function:     test.assert.lib._get-file-or-string()
# Description:  Private utility function to determine if the given argument is a
#               plain string or the name of a file and return either the string
#               or the contents of the named file.
# Takes:        $1  - either a string or the name of a file containing a string
# Returns:      the string or the contents of the file via STDOUT
# Variables:    None
#-------------------------------------------------------------------------------
test.assert.lib._get-file-or-string() {
  case $(test.lib.path-exists ${1:?'Neither string or filename'}) in
    y) cat $OPTARG ;; n) echo "$OPTARG" ;;
  esac
}

#-------------------------------------------------------------------------------
# Function:     test.assert.command.output-content()
# Description:  Test runner output related assertion - asserting the expectation
#               WRT the/any generated output on STDERR &/or STDOUT. Note that,
#               if neither is given, then the captures MUST both be empty -
#               which has exactly the same affect as merely calling
#               test.assert.command.output-empty().
# Takes:        -e STR  - if given, STR is either a string or the name of a file
#                         containing a string captured from STDERR.
#               -o STR  - if given, STR is either a string or the name of a file
#                         containing a string captured from STDOUT.
# Returns:      
# Variables:    $TEST_STDERR -
#               $TEST_STDOUT -
#-------------------------------------------------------------------------------
test.assert.command.output-content() {
  local OPTARG OPTIND opt desc=
  local -A streams=( [stderr]='' stdout='' )

  while getopts 'e:o:' opt ; do
    case $opt in
      e)  streams[stderr]="$(test.assert.lib._get-file-or-string $OPTARG)" ;;
      o)  streams[stdout]="$(test.assert.lib._get-file-or-string $OPTARG)" ;;
    esac
  done

  shift $((OPTIND - 1))

  local key ; for key in ${!streams[@]} ; do
    local stream=TEST_${key^^}
    test.assert.ok "Output ${key^^}${1:+ - $1}" \
        "test '$(<${!stream})' = '${streams[$key]}'"
  done
}

#-------------------------------------------------------------------------------
# Function:     test.assert.command.output-empty()
# Description:  Asserts that no generated output was 'seen' on either STDOUT or
#               STDERR.
# Takes:        -s VAR  - if given, specifies the name of the status for which
#                         the results s/b updated, default - $TEST_RESULTS
#               $*      - if given, STDERR & STDOUT capture file names, 
#                         default - $TEST_STDERR $TEST_STDOUT
# Returns:      None
# Variables:    ${!VAR} - the name of the test status containing the assertion
#-------------------------------------------------------------------------------
test.assert.command.output-empty() {
  local OPTARG OPTIND opt desc="Empty STDERR & STDOUT" \
    output="$(<${1:-$TEST_STDERR})$(<${2:-$TEST_STDOUT})"

  test.assert.ok "Empty STDOUT & STDERR${1:+ - $1}" "test '$output' = ''"
}

test.campaign.start

#### END OF FILE
