#!/usr/bin/env bash
# vim: ai columns=80 et fo+=rt sw=2 sts=2 tw=80
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################

# Load the internal library code, passing on the CLI options, if any
#. ${SHELLSPEC_SPECFILE%/test/*}/main/lib/lib.sh 

declare OUT=${SHELLSPEC_SPECFILE%/test/*}/main/lib/getopts.sh

#test.script.start $OUT

Include $OUT

Describe "002 - Entry definition ($SHELLSPEC_SPECFILE)"
  Describe 'BP - No args (entry definition) - '
    declare Func=getopts.define-arg
    Describe "$Func()"
      It 'reports being called without a definition'
        When run $Func
        The status should not be success
        The stderr should match pattern \
          'Failed assertion: Entry definition - No arg entry !!!'
      End
    End

    declare Func=getopts.define-opt
    Describe "$Func()"
      It 'reports being called without a definition'
        When run $Func
        The status should not be success
        The stderr should match pattern \
          'Failed assertion: Entry definition - No opt entry !!!'
      End
    End
  End

  declare Func=getopts.define-opt

  Describe "$Func()"
    Describe 'BP - Missing (mandatory) args - '
      It 'reports when called without any definition'
        When run $Func
        The status should not be success
        The stderr should match pattern \
          'Failed assertion: Entry definition - No opt entry !!!'
      End

      It 'reports when called without a definition'
        When run $Func var=fred
        The status should not be success
        The stderr should match pattern \
          'Failed assertion: Entry definition - Missing mandatory key(s): short long !!!'
      End
    End

    Describe 'GP - Extant mandatory) args - '
      It 'reports no error with default opts'
        Skip 'Proven in/by 001_inclusion_sourcing_spec.sh:43'
      End

      It 'reports no error with bespoke opts'
        When run $Func short=fred var=fred
        The status should be success
        The output should eq ""
      End
    End
  End
End

#### END OF FILE
