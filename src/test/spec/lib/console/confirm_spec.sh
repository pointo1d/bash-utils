FNNAME=lib.console.confirm
LNAME=src/main/${FNNAME//./\/}.sh
Include $LNAME
#lib.console.die() { builtin echo -e "$@" >&2 ; exit 1 ; }

Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Skip 'Skipped whilst read(1) builtin not mockable'
End

#### END OF FILE
