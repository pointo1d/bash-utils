#!/usr/bin/env bash
# vim: ai columns=80 et fo+=rt sw=2 sts=2 tw=80
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################

# Load the internal library code, passing on the CLI options, if any
#. ${SHELLSPEC_SPECFILE%/test/*}/main/lib/lib.sh 

#test.script.start $BU_MAIN_LIB_DIR/getopts.sh
declare GitHookFwk=src/main/githook-fwk
declare \
  OUT=$GitHookFwk/hooks/pre-commit \
  EnrolMeSh=$GitHookFwk/enrol-me.sh \
  TEST_DATA_DIR=${SHELLSPEC_SPECFILE%/*}/test-data \
  TestRepoRoot=$SHELLSPEC_WORKDIR/TestRepo

Describe "$OUT"
  declare SrcMain="${SHELLSPEC_PROJECT_ROOT}/src/main"

  Describe "Invocation"
    Parameters
      failed.lint.md
      passed.lint.md
      failed.syntax.pl
      failed.syntax.pm
      failed.syntax.sh
      failed.lint.sh
      passed.lint.sh
      passed.syntax.sh
    End

    Describe "independent file test"
      It "handles $TEST_DATA_DIR/$1 correctly"
        When run bash $OUT $TEST_DATA_DIR/$1

        if test ${1/passed.} != $1; then
          The status should be success
          The stderr should match pattern \
            "*Pre-commit: Check* passed for file: '$TEST_DATA_DIR/$1'*"
        else
          The status should not be success
          The stderr should match pattern \
            "*Pre-commit: Check* failed for file: '$TEST_DATA_DIR/$1'*"
        fi
      End
    End

    Describe "commit hook (in '$TestRepoRoot')"
      stand-up() {
        git init -q $TestRepoRoot
        bash $EnrolMeSh -d $TestRepoRoot
      }

      tear-down() {
        rm -fr $TestRepoRoot
      }

      run-it() {
        rm -f $TestRepoRoot/*.*
        cp $1 $TestRepoRoot
        git -C $TestRepoRoot add .
        git -C $TestRepoRoot commit -qm"."
      }

      BeforeRun stand-up
      AfterRun tear-down

      It "handles $TEST_DATA_DIR/$1 correctly in $TestRepoRoot"
        When run run-it $TEST_DATA_DIR/$1

        if test ${1/passed.} != $1; then
          The status should be success
          The stderr should match pattern \
            "*Pre-commit: Check* passed for file: '$1'*"
        else
          The status should not be success
          The stderr should match pattern \
            "*Pre-commit: Check* failed for file: '$1'*"
        fi
      End
    End
  End
End

#### END OF FILE
