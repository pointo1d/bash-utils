Include src/main/lib/path.sh

FNAME=bash-utils.path.is-absolute
Describe "$FNAME()"
  Parameters
    $SHELLSPEC_TMPBASE  y
    $PWD                y
    fred                ''
    ../not-exists       ''
  End

  Example "GP: $FNAME $1 - ${2:-}"
    When call $FNAME $1
    The status should be success
    The stdout should equal ${2:-''}
    The stderr should equal ''
  End
End

FNAME=${FNAME/is-/get-}
Describe "$FNAME()"
  mk-it() { > fred ; }
  rm-it() { rm fred ; }
  BeforeEach mk-it
  AfterEach rm-it

  Parameters
    $SHELLSPEC_TMPBASE  $SHELLSPEC_TMPBASE
    $PWD/..             ${PWD%/*}
    $PWD/.              $PWD
    ./fred              $PWD/fred
    fred                $PWD/fred
  End

  Example "GP: $FNAME $1 - ${2:-}"
    When call $FNAME $1
    The status should be success
    The stdout should equal ${2:-''}
    The stderr should equal ''
  End
End



