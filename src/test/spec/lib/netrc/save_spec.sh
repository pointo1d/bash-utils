FNNAME=lib.netrc
LNAME=src/main/${FNNAME//./\/}.sh
FNNAME=$FNNAME.save
Prefix=$(case $(uname -o) in Msys) echo _ ;; esac)
NetRcFile=$HOME/${Prefix}netrc

TmpFile=$SHELLSPEC_TMPBASE/netrc
prep() {
  cat<<EOT>$TmpFile
machine somehost
  login     suser
  password  spasswd

default
  login     duser
  password  dpasswd

EOT
}

%logger "Unit test suite for $FNNAME() (in $LNAME)"
Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Include $LNAME

  Describe 'Off-norm i.e. bad path, behaviours'
    It '- non-extant var'
      When run $FNNAME
      The status should be failure
      The stdout should equal ''
      The stderr should include "Var not found: 'Netrc'"
    End

    It '- empty var'
      invoke-it() {
        declare -A Netrc=()
        $FNNAME
      }

      When run invoke-it
      The status should be success
      The stdout should equal ''
      The stderr should include "Empty struct in var: 'Netrc'"
    End

    It '- file exists, no overwrite'
      invoke-it() {
        prep
        declare -A MyNetrc=([test-host]=)
        $FNNAME -v MyNetrc $TmpFile
      }

      When run invoke-it
      The status should be failure
      The stdout should equal ''
      The stderr should include "File exists, no overwrite: '$TmpFile'"
    End
  End

  Describe 'Norm i.e. good path, behaviours'
    It '- simple output to STDOUT'
      invoke-it() {
        prep
        declare -A MyNetrc=([test-host]=)
        mapfile -t t < <($FNNAME -fv MyNetrc)
        declare -p t
      }

      When run invoke-it
      The status should be success
      The stdout should include '[0]="machine test-host" [1]=""'
      The stderr should equal ''
    End

    It "- simple output to $TmpFile"
      invoke-it() {
        prep
        declare -A MyNetrc=([test-host]=)
        $FNNAME -fv MyNetrc $TmpFile
      }

      When run invoke-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
      The value "$(mapfile -t t < $TmpFile ; declare -p t)" should include '[0]="machine test-host" [1]=""'
    End

    It "- complex output to $TmpFile"
      invoke-it() {
        prep
        declare -A MyNetrc=(
          [test-host]='[login]="tuser"'
          [default]='[login]="duser" [password]="dpasswd"'
        )

        $FNNAME -fv MyNetrc $TmpFile
      }

      When run invoke-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
      The value "$(mapfile -t t < $TmpFile ; declare -p t)" should include \
'[0]="machine test-host" [1]="  login tuser" [2]="" [3]="default" [4]="  login duser" [5]="  password dpasswd" [6]=""'
    End

    It "- output to $TmpFile"
      invoke-it() {
        prep
        declare -A MyNetrc=(
          [test-host]='[login]="tuser"'
          [default]='[login]="duser" [password]="dpasswd"'
        )
        export Datum=$SHELLSPEC_TMPBASE/datum
        cat << EOF > $Datum
machine test-host
  login tuser

default
  login duser
  password dpasswd

EOF
        $FNNAME -fv MyNetrc $TmpFile
      }

      When call invoke-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
      The value "$(diff $Datum $TmpFile)" should equal ''
    End
  End
End
