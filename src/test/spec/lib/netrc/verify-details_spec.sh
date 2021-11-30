FNNAME=lib.netrc
LNAME=src/main/${FNNAME//./\/}.sh
FNNAME=$FNNAME.verify-details

Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Skip 'Skip all tests undefined due to probs mocking the read(1) builtin'
End
