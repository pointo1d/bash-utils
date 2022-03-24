FNNAME=bash-utils.console
LNAME=src/main/${FNNAME/bash-utils./lib\/}.sh
Include $LNAME

Describe "Unit test suite for $LNAME)"
  FNNAME=$FNNAME.to-stderr
  Context "$FNNAME()"
    Describe "reports on variable correctly"
      Parameters
        ''
        'SoMe StRiNg'
      End

      Example "'${1:-}' is reported only on STDERR"
        When call $FNNAME $1
        The status should be success
        The stdout should equal ''
        The stderr should equal "$1"
      End
    End
  End

  FNNAME=${FNNAME//.to-stderr/.die}
  Context "$FNNAME()"
    It "reports & aborts correctly"
      When run $FNNAME 'Die Message'
      The status should not be success
      The stdout should equal ''
      The stderr should equal 'Died:: Die Message !!!'
    End
  End

  Context 'log4sh compatible output functions'
    Parameters
      unknown
      fatal
      error
      warn
      info
      debug
      trace
    End

    Example "bash-utils.console.$1() identifies the message correctly"
      invoke-it() { local fn=${FNNAME//.die}.$1 ; eval $fn "${1^^}" ; }

      When run invoke-it $1
      if test $1 = unknown -o $1 = fatal -o $1 = error ; then
        The status should not be success
      else
        The status should be success
      fi

      The stdout should equal ''
      The stderr should include "${1^^}:: ${1^^}"
    End
  End
End


#### END OF FILE
