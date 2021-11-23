FNNAME=lib.netrc
LNAME=src/main/${FNNAME//./\/}.sh
FNNAME=$FNNAME.lookup
Prefix=$(case $(uname -o) in Msys) echo _ ;; esac)

Describe "Unit test suite for $FNNAME() (in $LNAME)"
  Include $LNAME

  call-it() {
    read d ; eval $d
    $FNNAME $@
  }

  Describe 'Normal i.e. GP, behaviours'
    Describe 'empty + no default'
      Describe 'merge disabled'
        It 'quiet'
          Data "Netrc=([somehost]=)"

          When call call-it -qnh somehost 
          The status should be success
          The stdout should equal ''
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]=)"

          When call call-it -nh somehost 
          The status should be success
          The stdout should equal ''
          The stderr should include "Empty definition for 'somehost'"
        End
      End

      Describe 'merge enabled'
        It 'quiet'
          Data "Netrc=([somehost]=)"

          When call call-it -qh somehost 
          The status should be success
          The stdout should equal ''
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]=)"

          When call call-it -h somehost 
          The status should be success
          The stdout should equal ''
          The stderr should include "Empty definition for 'somehost'"
        End
      End
    End

    Describe 'empty + default'
      Describe 'merge disabled'
        It 'quiet'
          Data "Netrc=([somehost]= [default]='[login]=duser [password]=dpasswd')"

          When call call-it -qnh somehost 
          The status should be success
          The stdout should equal ''
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]= [default]='[login]=duser [password]=dpasswd')"

          When call call-it -nh somehost
          The status should be success
          The stdout should equal ''
          The stderr should include "Empty definition for 'somehost'"
        End
      End

      Describe 'merge enabled'
        It 'quiet'
          Data "Netrc=([somehost]= [default]='[login]=duser [password]=dpasswd')"

          When call call-it -qh somehost 
          The status should be success
          The stdout should equal 'duser:dpasswd'
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]= [default]='[login]=duser [password]=dpasswd')"

          When call call-it -h somehost
          The status should be success
          The stdout should equal 'duser:dpasswd'
          The stderr should include "Empty definition for 'somehost'"
        End
      End
    End

    Describe 'partial + default'
      Describe 'merge disabled'
        It 'quiet'
          Data "Netrc=([somehost]='[login]=suser' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -qnh somehost
          The status should be success
          The stdout should equal 'suser'
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]='[login]=suser' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -nh somehost
          The status should be success
          The stdout should equal 'suser'
          The stderr should equal ''
        End
      End

      Describe 'merge enabled'
        It 'quiet'
          Data "Netrc=([somehost]='[login]=suser' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -qh somehost
          The status should be success
          The stdout should equal 'suser:dpasswd'
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]='[login]=suser' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -h somehost
          The status should be success
          The stdout should equal 'suser:dpasswd'
          The stderr should equal ''
        End
      End
    End

    Describe 'full + default i.e. no merge needed'
      Describe 'merge disabled'
        It 'quiet'
          Data "Netrc=([somehost]='[login]=suser [password]=spasswd' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -qnh somehost
          The status should be success
          The stdout should equal 'suser:spasswd'
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]='[login]=suser [password]=spasswd' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -nh somehost
          The status should be success
          The stdout should equal 'suser:spasswd'
          The stderr should equal ''
        End
      End

      Describe 'merge enabled'
        It 'quiet'
          Data "Netrc=([somehost]='[login]=suser [password]=spasswd' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -qh somehost
          The status should be success
          The stdout should equal 'suser:spasswd'
          The stderr should equal ''
        End

        It 'not quiet'
          Data "Netrc=([somehost]='[login]=suser [password]=spasswd' [default]='[login]=duser [password]=dpasswd')"

          When call call-it -h somehost
          The status should be success
          The stdout should equal 'suser:spasswd'
          The stderr should equal ''
        End
      End
    End
  End
End

#### END OF FILE
