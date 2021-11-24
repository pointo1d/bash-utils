FNNAME=lib.netrc
LNAME=src/main/${FNNAME//./\/}.sh
Include $LNAME

FNNAME=$FNNAME.exists
Prefix=$(case $(uname -o) in Msys) echo _ ;; esac)
NetRcFile=$HOME/${Prefix}netrc

Describe "Unit test suite for $FNNAME() (in $LNAME)"

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
        declare -Ax ${2:-Netrc}

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
        declare -Ax ${2:-Netrc}
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

FNNAME=${FNNAME//exists/validate-var-name}
Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Describe "reports on variable correctly"
    Parameters
      ''
      MyNetrc
    End

    Example "'${1:-Netrc}' doesn't exist"

      When run $FNNAME
      The status should be failure
      The stdout should equal ''
      The stderr  should include 'Var not found'
    End

    Example "'${1:-Netrc}' is the wrong type"
      invoke-it() { export ${1:-Netrc}=f ; $FNNAME ; }

      When run invoke-it
      The status should be failure
      The stdout should equal ''
      The stderr  should include "Var wrong type "
    End

    Example ''${1:-Netrc}' exists & is valid type'
    invoke-it() {
      declare -A ${1:-Netrc}
      local -n var=${1:-Netrc}
      var=( [some-val]= )
      $FNNAME
    }

      When run invoke-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End
  End
End

#### END OF FILE