FNNAME=lib.netrc
LNAME=src/main/${FNNAME//./\/}.sh
FNNAME=$FNNAME.exists
Prefix=$(case $(uname -o) in Msys) echo _ ;; esac)
NetRcFile=$HOME/${Prefix}netrc

Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Include $LNAME

  Describe "reports condition correctly"
    Parameters
      ''
      -l
      '' MyNetrc
      -l  MyNetrc
    End

    Example "$FNNAME $1 $2 reports non-existance"
      When call $FNNAME $1 $2

      if [ "$1" ]; then
        The stdout should include "${2:-Netrc}: not found"
      else
        The stdout should equal 'n'
      fi
    End

    Example "$FNNAME $1 $2 reports empty"
      invoke-it() {
        eval declare -Ax ${2:-Netrc}

        $FNNAME $1 $2
      }

      When call invoke-it "$1" "$2"

      if [ "$1" ]; then
        The stdout should include "-Ax ${2:-Netrc}"
      else
        The stdout should equal 'e'
      fi

    End

    Example "$FNNAME $1 $2 reports populated"
      invoke-it() {
        eval declare -Ax ${2:-Netrc}
        local -n var=${2:-Netrc}
        var[a]=

        $FNNAME $1 $2
      }

      When call invoke-it "$1" "$2"


      if [ "$1" ]; then
        The stdout should include "${2:-Netrc}="
      else
        The stdout should equal 'p'
      fi

    End

    Example "$FNNAME $1 $2 reports fully"
      When call $FNNAME $1 $2

      if [ "$1" ]; then
        The stdout should include "${2:-Netrc}: not found"
      else
        The stdout should equal 'n'
      fi

    End
  End
End
