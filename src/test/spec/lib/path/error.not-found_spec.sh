FNAME='bash-utils.path.error.not-found'
Describe "$FNAME"
  Include src/main/lib/path/error.sh

  Describe "$FNAME"
    call-it() { $FNAME $@ ; }

    It "GP: $FNAME error.sh - default i.e. fatal"
      When run $FNAME error.sh
      The status should not equal 0
      The stderr should include error.sh
    End

    It "GP: $FNAME -sf error.sh - fatal"
      When run $FNAME -sf error.sh
      The status should not equal 0
      The stderr should include error.sh
    End

    It "GP: $FNAME -sw error.sh - warning"
      When call $FNAME -sw error.sh
      The status should equal 0
      The stderr should include error.sh
    End

    It "BP: $FNAME -st error.sh - unknown severity"
      When run $FNAME -st error.sh
      The status should not equal 0
      The stderr should include 'Unknown severity: t'
    End
  End
End
