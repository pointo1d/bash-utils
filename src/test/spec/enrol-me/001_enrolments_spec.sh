#!/usr/bin/env bash
# vim: ai columns=80 et fo+=rt sw=2 sts=2 tw=80
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################

# Load the internal library code, passing on the CLI options, if any
#. ${SHELLSPEC_SPECFILE%/test/*}/main/lib/lib.sh 

#test.script.start $BU_MAIN_LIB_DIR/getopts.sh
declare \
  OUT=enrol-me.sh FUNC=bash-utils.enrol-me

Describe "Enrolment ($SHELLSPEC_SPECFILE)"
  It "GP - Default i.e. no caller enrolment, load does not abort"
    When run . $OUT
    The status should be success
    The stderr should eq ""
  End

    declare \
      SrcMain="${SHELLSPEC_PROJECT_ROOT}/src/main" \
      CallerRoot="/caller/root"

    declare -A default_paths=(
      [BASH_UTILS_ROOT_DIR]="$SrcMain"
      [BASH_UTILS_BIN_DIR]="$SrcMain/bin"
      [BASH_UTILS_LIB_DIR]="$SrcMain/lib"
      [BASH_UTILS_SBIN_DIR]="$SrcMain/sbin"
    ) \
    caller_paths=(
      [CALLER_ROOT_DIR]="$CallerRoot"
      [CALLER_BIN_DIR]="$CallerRoot/bin"
      [CALLER_LIB_DIR]="$CallerRoot/lib"
      [CALLER_SBIN_DIR]="$CallerRoot/sbin"
    )

  It "GP - Default i.e. no caller enrolment, env vars set"
    When call . $OUT
    The status should be success
    The stderr should eq ""
    The value "$(type -t source)" should eq "function"
    The value "$(type -t .)" should eq "function"

    for key in "${!default_paths[@]}"; do
      if test $key = ${key/_LIB_}; then
        The value "${!key}" should eq ${default_paths[$key]}
        The value ":$PATH:" should include ":${default_paths[$key]}:"
      else
        Skip "Default lib dir not in PATH: $key"
      fi
    done
  End

  Describe "GP - Non-default i.e. caller enrolment, all env vars set"
    It "GP - Non-default i.e. caller enrolment, default env vars set"
      declare SrcMain="${SHELLSPEC_PROJECT_ROOT}/src/main"

      When call . $OUT "$CallerRoot:CaLler:caller"
      The status should be success
      The stderr should eq ""
      The value "$(type -t source)" should eq "function"
      The value "$(type -t .)" should eq "function"

      for key in "${!default_paths[@]}"; do
        if test $key = ${key/_LIB_}; then
          The value "${!key}" should eq ${default_paths[$key]}
          The value ":$PATH:" should include ":${default_paths[$key]}:"
        else
          Skip "$key - default lib dir not in PATH"
        fi
      done
    End

    It "GP - Non-default i.e. caller enrolment, caller env vars set"
      When call . $OUT "$CallerRoot:CaLler:caller"
      The status should be success
      The stderr should eq ""
      for key in "${!caller_paths[@]}"; do
        if test $key = ${key/_LIB_}; then
          The value "${!key}" should eq ${caller_paths[$key]}
          The value ":$PATH:" should include ":${caller_paths[$key]}:"
        else
          Skip "$key - caller lib dir not in PATH"
        fi
      done
    End
  End
End

#### END OF FILE
