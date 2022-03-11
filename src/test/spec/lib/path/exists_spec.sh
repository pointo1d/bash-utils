FNAME='bash-utils.path.exists'
Describe "$FNAME"
  Include src/main/lib/path.sh

  Describe "$FNAME"
    call-it() { $FNAME $@ ; }

    It "$FNAME /tmp - /tmp to STDOUT"
      When call $FNAME $PWD
      The output should equal $PWD
    End

    It "$FNAME /tmp - reports /tmp to STDOUT"
      When call $FNAME /tmp
      The output should equal /tmp
    End

    It "$FNAME - reports file not found"
      When run call-it $SHELLSPEC_TMPBASE.not-exists
      The stderr should include "not found: $SHELLSPEC_TMPBASE.not-exists"
      The status should not equal 0
    End
  End
End
