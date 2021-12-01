FNNAME=lib.netrc
LNAME=src/main/${FNNAME//./\/}.sh
FNNAME=$FNNAME.load
Prefix=$(case $(uname -o) in Msys) echo _ ;; esac)
NetRcFile=$HOME/${Prefix}netrc

TmpFile=$SHELLSPEC_TMPBASE/netrc

prep() {
  cat<<EOT>$TmpFile
# some machines
machine somehost
  login     suser
  password  spasswd

# Some defaults
default
  login     duser
  password  dpasswd

EOT
}

Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Include $LNAME

  Describe 'Off-norm i.e. bad path, behaviours'
    It '- non-extant file'
      When run $FNNAME $SHELLSPEC_TMPBASE/non-extant
      The status should be failure
      The stdout should equal ''
      The stderr should include \
        "File not found: '$SHELLSPEC_TMPBASE/non-extant'"
    End

    Describe 'empty file'
      It "- physical file - $SHELLSPEC_TMPBASE/extant"
        invoke-it() {
          > $SHELLSPEC_TMPBASE/extant
          $FNNAME -v MyNetrc $SHELLSPEC_TMPBASE/extant
        }

        When call invoke-it
        The status should be success
        The stdout should equal ''
        The stderr should include \
          "Empty file: '$SHELLSPEC_TMPBASE/extant'"
      End

      It "- implicit stdin - '-'"
        invoke-it() { $FNNAME -v MyNetrc < /dev/null ; }
        When call invoke-it
        The status should be success
        The stdout should equal ''
        The stderr should include "Empty file: '-'"
      End

      It "- explicit stdin - '-'"
        invoke-it() { $(echo) | $FNNAME -v MyNetrc ; }
        When call invoke-it
        The status should be success
        The stdout should equal ''
        The stderr should include "Empty file: '-'"
      End
    End
  End

  Describe 'Norm i.e. good path, behaviours'
    report-struct() { declare -p $1 | sed 's,.*(\([^)]*\) ).*,\1,' ; }

    BeforeAll prep
    invoke-it() {
      $FNNAME $TmpFile
      report-struct Netrc
    }

    Describe 'Non-empty input'
      It 'standard file'
        When call invoke-it 
        The status should be success
        The stdout should equal \
          '[default]="[password]=\"dpasswd\" [login]=\"duser\"" [somehost]="[password]=\"spasswd\" [login]=\"suser\""'
        The stderr should equal ''
      End

      It "implicit POSIX stdin"
        invoke-it() {
          $FNNAME < $TmpFile
          report-struct Netrc
        }

        When run invoke-it
        The status should be success
        The stdout should equal \
          '[default]="[password]=\"dpasswd\" [login]=\"duser\"" [somehost]="[password]=\"spasswd\" [login]=\"suser\""'
        The stderr should equal ''
      End

      It 'explicit POSIX stdin stdin ('-')'
        invoke-it() {
          $FNNAME - < $TmpFile
          report-struct Netrc
        }

        When run invoke-it
        The status should be success
        The stdout should equal \
          '[default]="[password]=\"dpasswd\" [login]=\"duser\"" [somehost]="[password]=\"spasswd\" [login]=\"suser\""'
        The stderr should equal ''
      End
    End
  End
End
