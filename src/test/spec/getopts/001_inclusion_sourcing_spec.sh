#!/usr/bin/env bash
# vim: ai columns=80 et fo+=rt sw=2 sts=2 tw=80
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################

# Load the internal library code, passing on the CLI options, if any
#. ${SHELLSPEC_SPECFILE%/test/*}/main/lib/lib.sh 

#test.script.start $BU_MAIN_LIB_DIR/getopts.sh
declare \
  OUT=${SHELLSPEC_SPECFILE%/test/*}/main/lib/getopts.sh \
  FUNC=getopts

Describe "001 - File inclusion/source(1)ing ($SHELLSPEC_SPECFILE)"
  It "BP - Fails to load with wrong arg(s)"
    When run . $OUT -w fred
    The status should not be success
    The stderr should match pattern "Unknown option: 'w'*"
  End

  It "GP - Load: Default(s)"
    When call . $OUT
    The status should be success
    The output should eq ""
    The value "${Lists[ArgsListVarName]}" should eq 'ArgsList:a'
    The value "${Lists[OptsListVarName]}" should eq 'OptsList:A'
    The value "${#ArgsList[@]}" should eq 0
    The value "${#OptsList[@]}" should eq 0
  End

  It "GP - Load: Default list names with default opts"
    When call . $OUT -d
    The status should be success
    The output should eq ""
    The value "${Lists[ArgsListVarName]}" should eq 'ArgsList:a'
    The value "${Lists[OptsListVarName]}" should eq 'OptsList:A'
    The value "${#ArgsList[@]}" should eq 0
    The value "${#OptsList[@]}" should eq 3
  End

  It "GP - Load: Alternate list names"
    When call . $OUT -a TestArgs -o TestOpts
    The status should be success
    The output should eq ""
    The value "${Lists[ArgsListVarName]}" should eq 'TestArgs:a'
    The value "${Lists[OptsListVarName]}" should eq 'TestOpts:A'
    The value "${#TestArgs[@]}" should eq 0
    The value "${#TestOpts[@]}" should eq 0
  End

  It "GP - Load: Alternate list names with default opts"
    When call . $OUT -da TestArgs -o TestOpts
    The status should be success
    The output should eq ""
    The value "${Lists[ArgsListVarName]}" should eq 'TestArgs:a'
    The value "${Lists[OptsListVarName]}" should eq 'TestOpts:A'
    The variable ArgsList should not be defined
    The variable OptsList should not be defined
    The value "${#TestArgs[@]}" should eq 0
    The value "${#TestOpts[@]}" should eq 3
  End
End

#### END OF FILE
