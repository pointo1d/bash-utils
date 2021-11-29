Include src/main/lib/path.sh
FNAME=lib.path.get-type

Describe $FNAME
  It "GP: $FNAME() /tmp reports directory type"
    When call $FNAME /tmp
    The output should equal d
    The status should equal 0
  End

  It "GP: $FNAME() $0 reports file type"
    When call $FNAME $0
    The output should equal f
    The status should equal 0
  End

  It "BP: $FNAME non-exists - default is fatal"
    run-it() { $FNAME $@ ; }

    When run run-it non-exists
    The stderr should include non-exists
    The output should equal ''
    The status should not equal 0
  End

End
