#!/usr/bin/env bash
# vim: ai columns=80 et fo+=rt sw=2 sts=2 tw=80
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################

# Load the internal library code, passing on the CLI options, if any
#. ${SHELLSPEC_SPECFILE%/test/*}/main/lib/lib.sh 

#test.script.start $BU_MAIN_LIB_DIR/getopts.sh
declare OUT=./enrol-me.sh

Describe "$OUT"
  declare SrcMain="${SHELLSPEC_PROJECT_ROOT}/src/main"

  Describe "Invocations"
    Parameters
      root  BASH_UTILS_ROOT_DIR   $SrcMain
      bin   BASH_UTILS_BIN_DIR    $SrcMain/bin
      lib   BASH_UTILS_LIB_DIR    $SrcMain/lib
      sbin  BASH_UTILS_SBIN_DIR   $SrcMain/sbin
    End

    Describe  ".|source $OUT"
      It "$2 - variable set correctly, no output"
        When call . $OUT
        The status should be success
        The output should eq ""
        The variable $2 should eq "$3"
      End

      It "$2 - PATH updated correctly"
        When call . $OUT
        The status should be success
        The output should eq ""

        if test $1 != "lib"; then
          The variable PATH should include $3
        else
          The variable PATH should not include $3
        fi

      End
    End

    Describe  "bash $OUT"
      It "$2 - variable not set, correct output"
        When run bash $OUT
        The status should be success
        The output should include "$2=$3"
        The variable $2 should not be defined
      End

      It "$2 - PATH updated correctly"
        When run bash $OUT
        The status should be success
        The output should not eq ""
        The variable PATH should not include $3
      End
    End
  End
End

#### END OF FILE
