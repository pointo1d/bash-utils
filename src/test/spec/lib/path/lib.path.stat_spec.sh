export FNAME=lib.path.stat
Describe $FNAME
  Include ../main/lib/path.sh
  run-it() { $FNAME $@ ; }
  #Include path.sh

  It "BP: $FNAME - i.e. no arg fatal"
    When run run-it
    The stderr should include 'No path to test'
    The status should not equal 0
  End

  It "GP: $FNAME $0 - extant path"
    When call $FNAME $0
    The output should start with "File: $0 "
    The status should equal 0
  End

  It "GP: $FNAME $(dirname $0) - extant dir"
    When call $FNAME $(dirname $0)
    The output should start with "File: $(dirname $0) "
    The status should equal 0
  End

  It "GP: $FNAME $(dirname $0) - non-extant"
    When call $FNAME $(dirname $0)ff
    The output should equal ''
    The status should equal 0
  End

  It "GP: $FNAME $0 - non-default format"
    When call $FNAME -f $0
    The output should start with "File: \"$0\" "
    The status should equal 0
  End
End
