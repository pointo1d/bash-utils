export FNAME=bash-utils.path.stat
Describe $FNAME
  Include src/main/lib/path.sh
  run-it() { $FNAME $@ ; }
  #Include path.sh

  It "BP: $FNAME - i.e. no arg fatal"
    When run run-it
    The stderr should include 'No path to test'
    The status should not equal 0
  End

  It "GP: $FNAME $0 - extant path"
    When call $FNAME $0
    The output should start with "$0 "
    The status should equal 0
  End

  It "GP: $FNAME $(dirname $0) - extant dir"
    When call $FNAME $SHELLSPEC_TMPBASE
    The output should start with "$SHELLSPEC_TMPBASE "
    The status should equal 0
  End

  It "GP: $FNAME $(dirname $0) - non-extant"
    When call $FNAME ${SHELLSPEC_TMPBASE}ff
    The output should equal ''
    The status should equal 0
  End

  It "GP: $FNAME $0 - non-default format"
    When call $FNAME -f $0
    The output should start with "File: \"$0\" "
    The status should equal 0
  End
End
