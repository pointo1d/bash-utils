Include src/main/lib/path.sh

FNAME=bash-utils.path.get-type

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

FNAME=${FNAME/get/is}
Describe "$FNAME()"
  Parameters
    $SHELLSPEC_TMPBASE  d
    $0                  f
  End

  Example "$1 - $2"
    When call $FNAME "$2" "$1"
    The status should be success
    The stdout should equal y
    The stderr should equal ''
  End
End

FNAME=${FNAME/is*/is-dir}
Describe "$FNAME()"
  Parameters
    $SHELLSPEC_TMPBASE  y
    $0                  ''
  End

  Example "$FNAME $1 - ${2:-}"
    When call $FNAME $1
    The status should be success
    The stdout should equal ${2:-''}
    The stderr should equal ''
  End
End

FNAME=${FNAME/-dir/-file}
Describe "$FNAME()"
  Parameters
    $SHELLSPEC_TMPBASE  ''
    $0                  y
  End

  Example "$FNAME $1 - ${2:-}"
    When call $FNAME $1
    The status should be success
    The stdout should equal ${2:-''}
    The stderr should equal ''
  End
End

