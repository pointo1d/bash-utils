FNAME=lib.string
LNAME=${FNAME//./\/}

Describe "Unit test suite for $FNAME ($LNAME.sh)"
  Include src/main/$LNAME.sh

  FNNAME=$FNAME.is-empty
  Context "$FNNAME()"
    It "BP: $FNNAME - true"
      When call $FNNAME 
      The output should equal "y"
    End

    It "BP: $FNNAME '' - true"
      When call $FNNAME ''
      The output should equal "y"
    End

    It "BP: $FNNAME someVal - false"
      When call $FNNAME someVal
      The output should equal "n"
    End
  End

  FNNAME=$FNAME.is-non-empty
  Context "$FNNAME()"
    It "BP: $FNNAME - false"
      When call $FNNAME 
      The output should equal "n"
    End

    It "BP: $FNNAME '' - false"
      When call $FNNAME ''
      The output should equal "n"
    End

    It "BP: $FNNAME someVal - true"
      When call $FNNAME someVal
      The output should equal "y"
    End
  End

  FNNAME=$FNAME.is-int
  Context "$FNNAME()"
    It "BP: $FNNAME <STRING> - false"
      When call $FNNAME hello
      The output should equal "n"
    End

    It "BP: $FNNAME <FLOAT> - false"
      When call $FNNAME 123E4
      The output should equal "n"
    End

    It "GP: $FNNAME -- <-VE INT> - true"
      When call $FNNAME -- -123
      The output should equal "y"
    End

    It "GP: $FNNAME <+VE INT> - true"
      When call $FNNAME +123
      The output should equal "y"
    End

    It "GP: $FNNAME -- <+VE INT> - true"
      When call $FNNAME -- +123
      The output should equal "y"
    End
  End

  FNNAME=$FNAME.is-unsigned-int
  Context "$FNNAME()"
    It "BP: $FNNAME <STRING> - false"
      When call $FNNAME hello
      The output should equal "n"
    End

    It "BP: $FNNAME <+VE INT> - false"
      When call $FNNAME +123
      The output should equal "n"
    End

    It "BP: $FNNAME -- <-VE INT> - false"
      When call $FNNAME -- -123
      The output should equal "n"
    End

    It "BP: $FNNAME <-VE INT> - fatal"
      When call $FNNAME -123
      The output should equal "n"
    End

    It "GP: $FNNAME <INT> - false"
      When call $FNNAME 123
      The output should equal "y"
    End
  End

  FNNAME=$FNAME.is-signed-int
  Context "$FNNAME()"
    It "BP: $FNNAME <STRING> - false"
      When call $FNNAME hello
      The output should equal "n"
    End

    It "BP: $FNNAME <-VE INT> - fatal"
      When call $FNNAME -123
      The stderr should include "illegal option"
      The output should equal "n"
    End

    It "BP: $FNNAME <INT> - false"
      When call $FNNAME 123
      The output should equal "n"
    End

    It "GP: $FNNAME <+VE INT> - false"
      When call $FNNAME +123
      The output should equal "y"
    End

    It "GP: $FNNAME -- <-VE INT> - false"
      When call $FNNAME -- -123
      The output should equal "y"
    End
  End

  FNNAME=$FNAME.is--ve-int
  Context "$FNNAME()"
    It "BP: $FNNAME <STRING> - false"
      When call $FNNAME hello
      The output should equal "n"
    End

    It "BP: $FNNAME <FLOAT> - false"
      When call $FNNAME 123E4
      The output should equal "n"
    End

    It "GP: $FNNAME -- <-VE INT> - true"
      When call $FNNAME -- -123
      The output should equal "y"
    End

    It "GP: $FNNAME <+VE INT> - true"
      When call $FNNAME 123
      The output should equal "n"
    End

    It "GP: $FNNAME -- <+VE INT> - true"
      When call $FNNAME -- +123
      The output should equal "n"
    End
  End

  FNNAME=$FNAME.is-+ve-int
  Context "$FNNAME()"
    It "BP: $FNNAME <STRING> - false"
      When call $FNNAME hello
      The output should equal "n"
    End

    It "BP: $FNNAME <FLOAT> - false"
      When call $FNNAME 123E4
      The output should equal "n"
    End

    It "GP: $FNNAME -- <-VE INT> - true"
      When call $FNNAME -- -123
      The output should equal "n"
    End

    It "GP: $FNNAME <+VE INT> - true"
      When call $FNNAME 123
      The output should equal "y"
    End

    It "GP: $FNNAME -- <+VE INT> - true"
      When call $FNNAME -- +123
      The output should equal "y"
    End
  End
End
