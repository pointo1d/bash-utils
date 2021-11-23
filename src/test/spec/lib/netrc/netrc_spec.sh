FNNAME=lib.netrc
LNAME=src/main/${FNNAME//./\/}.sh
Prefix=$(case $(uname -o) in Msys) echo _ ;; esac)
NetrcFile=$HOME/${Prefix}netrc

Describe "integration test for $FNNAME (in $LNAME)"
  Context 'Include source'
    It "GP: includes without error"
      When run source $LNAME
      The status should equal 0
      The stdout should equal ''
      The stderr should equal ''
    End

    It "GP: includes with correct defaults"
      When run source $LNAME
      The status should equal 0
      The variable Netrc should not be defined
    End
  End
End
