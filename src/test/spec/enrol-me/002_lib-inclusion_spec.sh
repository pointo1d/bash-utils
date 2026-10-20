#!/usr/bin/env bash
# vim: ai columns=80 et fo+=rt sw=2 sts=2 tw=80
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################

# Load the internal library code, passing on the CLI options, if any
#. ${SHELLSPEC_SPECFILE%/test/*}/main/lib/lib.sh 

#test.script.start $BU_MAIN_LIB_DIR/getopts.sh
declare EnrolMe=$PWD/enrol-me.sh

Describe "Lib inclusion - bash-utils ($SHELLSPEC_SPECFILE)"
  stand-up() {
    . $EnrolMe
  }

  run-it() {
    eval "$@"
    return $?
  }

  BeforeCall stand-up
  BeforeRun stand-up

  Parameters
    .
    source
  End

  Describe "BP"
    It "$1() aborts when nothing to include"
      When run run-it $1
      The status should not be success
      The stderr should include "Nothing to include"
    End
  
    It "$1() aborts for non-extant library"
      When run run-it $1 not-exist
      The status should not be success
      The stderr should include "File not found for library: 'not-exist'"
    End
  End

  Describe "GP"
    It "$1() succeeds for bash-utils constituent lib"
      When call run-it $1 getopts
      The status should be success
      The stderr should eq ""
    End

    It "$1() succeeds for caller lib"
      Skip "NYI"
    End
  End
End

#### END OF FILE
