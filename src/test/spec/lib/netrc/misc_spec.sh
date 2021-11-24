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
      When call $FNNAME $1 ${2:+"-v $2"}

      if [ "$1" ]; then
        The stdout should include "${2:-Netrc}: not found"
      else
        The stdout should equal 'n'
      fi
    End

    Example "$FNNAME $1 $2 reports empty"
      invoke-it() {
        declare -A ${2:-Netrc}

        $FNNAME $1 ${2:+"-v $2"}
      }

      When call invoke-it "$1" "$2"

      if [ "$1" ]; then
        The stdout should include "-A ${2:-Netrc}"
      else
        The stdout should equal 'e'
      fi

    End

    Example "$FNNAME $1 $2 reports populated"
      invoke-it() {
        declare -A ${2:-Netrc}
        local -n var=${2:-Netrc}
        var[a]=

        $FNNAME $1 ${2:+"-v $2"}
      }

      When call invoke-it "$1" "$2"


      if [ "$1" ]; then
        The stdout should include "${2:-Netrc}="
      else
        The stdout should equal 'p'
      fi

    End

    Example "$FNNAME $1 $2 reports fully"
      When call $FNNAME $1 ${2:+"-v $2"}

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

FNNAME=${FNNAME//validate-var-name/ls-hosts}
Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Describe "reports on variable correctly"
    Parameters
      ''
      MyNetrc
    End

    Example "'${1:-Netrc}' is empty"
      invoke-it() {
        declare -A ${1:-Netrc}
        local -n var=${1:-Netrc}
        var=()
        $FNNAME
      }

      When call invoke-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End

    Describe "'${1:-Netrc}' isn't empty"
      Example "- no default"
        invoke-it() {
          declare -A ${1:-Netrc}
          local -n var=${1:-Netrc}
          var=( [one]= [two]= [zed]= )
          
          $FNNAME | sort
        }

        When call invoke-it
        The status should be success
        The stdout should equal 'zed two one'
        The stderr should include ''
      End

      Example "- default included"
        invoke-it() {
          declare -A ${1:-Netrc}
          local -n var=${1:-Netrc}
          var=( [default]= [a]= [b]= [z]= )
          $FNNAME
        }

        default_last() {
          case ${default_last:?} in *\ default) return 0 ;; *) return 1 ;; esac
        }

        When call invoke-it
        The status should be success
        The stdout should satisfy default_last
        The stderr should equal ''
      End
    End
  End
End



#### END OF FILE
