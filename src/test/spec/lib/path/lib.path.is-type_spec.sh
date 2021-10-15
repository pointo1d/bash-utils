Include ../main/lib/path.sh
FNAME=lib.path.is-type

Describe $FNAME
  Parameters
    d /tmp  y
    f $0    y
    f /tmp  ''
  End

  Example "GP: $FNAME() $1 $2 reports '$3'"
    When call $FNAME $1 $2
    The output should equal "$3"
    The status should equal 0
  End
End
