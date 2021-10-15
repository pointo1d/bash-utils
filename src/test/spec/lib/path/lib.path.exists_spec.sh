Describe 'lib.path'
  Include ../main/lib/path.sh

  Describe 'lib.path.exists'
    call-it() { lib.path.exists $@ ; }

    It 'lib.path.exists /tmp - /tmp to STDOUT'
      When call lib.path.exists $PWD
      The output should equal $PWD
    End

    It 'lib.path.exists /tmp - reports /tmp to STDOUT'
      When call lib.path.exists /tmp
      The output should equal /tmp
    End

    It 'lib.path.exists - reports file not found'
      When run call-it $BASH_SOURCE.not-exists
      The stderr should include "not found: $BASH_SOURCE.not-exists"
      The status should not equal 0
    End
  End
End
