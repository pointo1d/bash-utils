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
eval ${__test_lib_assert_sh__:-}
export __test_lib_assert_sh__=return

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

  case ${TEST_FAIL_FAST:+y} in
    y)  test.bail-out "Test failed and TEST_FAIL_FAST enabled" ;;
  esac
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

test.assert.command.exit-code.success() {
  local extra_desc="${1:-}"
  test.assert.ok \
    "Success exit code${extra_desc:+ - $extra_desc}" \
    "test $TEST_EXIT_CODE = 0"
}

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
# Function:     test.assert.command.output-content()
# Description:  Assert the content of the given/default output stream(s) is
#               correct. By default i.e. if a stream isn't specified, then that
#               stream MUST be empty - the corollary of which is that if neither
#               of the streams is specified, then both streams MUST be empty.
#               Note that this function is actually 2 calls in one - one for
#               each of the streams.
# Takes:        -e STR  - STR specifies non-empty STDERR expectation, default -
#                         expect STDERR to be empty.
#               -o STR  - STR specifies non-empty STDOUT expectation, default -
#                         expect STDOUT to be empty.
# Returns:      None
# Variables:    
#-------------------------------------------------------------------------------
test.assert.command.output-content() {
  local OPTARG OPTIND opt ; local -A streams=()

  while getopts 'e:o:' opt ; do
    case $opt in
      e)  streams[stderr]="$OPTARG" ;;
      o)  streams[stdout]="$OPTARG" ;;
    esac
  done

  shift $((OPTIND - 1))

  local key ; for key in stdout stderr ; do
    local stream=TEST_${key^^}
    test.assert.ok "Output ${key^^}${1:+ - $1}" \
      "test '$(<${!stream})' = '${streams[$key]:-}'"
  done
}

#### END OF FILE
