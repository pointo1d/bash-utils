#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################
FNAME=lib.sinclude.stack
LNAME=src/main/${FNAME//./\/}.sh
STACKNM=SomeStack

Describe "Unit test suite for $FNAME ($LNAME)"
  It "GP: Includes OK"
    When run source $LNAME
    The status should be success
    The stdout should equal ''
    The stderr should equal ''
  End

  Include $LNAME

  FNNAME=$FNAME.init
  Describe "$FNNAME()"
    It "BP - $FNNAME() - throws (no stack name)"
      When run $FNNAME
      The status should not be success
      The stdout should equal ''
      The stderr should include 'No stack name'
    End

    It "GP - $FNNAME() - OK"
      When call $FNNAME $STACKNM
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End
  End

  Describe "stack methods"
    $FNAME.init $STACKNM
    
    Describe "GP - empty stack"
      It "GP - $FNAME.depth()"
        When call $FNAME.depth $STACKNM
        The status should be success
        The stdout should equal 0
        The stderr should equal ''
      End

      It "GP - $FNAME.is-empty()"
        When call $FNAME.is-empty $STACKNM
        The status should be success
        The stdout should equal y
        The stderr should equal ''
      End

      It "GP - $FNAME.peek()"
        When call $FNAME.peek $STACKNM
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
      End

      It "GP - $FNAME.pop()"
        When call $FNAME.pop $STACKNM
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
      End
    End

    It "GP - $FNAME.push() OK" 
      When call $FNAME.push $STACKNM SomeVal
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
      The value $($FNAME.depth $STACKNM) should equal 1
      The value $($FNAME.peek $STACKNM) should equal SomeVal
    End

    It "GP - $FNAME.pop() OK" 
      $FNAME.push $STACKNM SomeVal
      When call $FNAME.pop $STACKNM
      The status should be success
      The stdout should equal SomeVal
      The stderr should equal ''
      The value $($FNAME.depth $STACKNM) should equal 0
    End
  End
End


#### END OF FILE
