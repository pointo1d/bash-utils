#!/usr/bin/env bash
# vim: ai columns=80 et fo+=rt sw=2 sts=2 tw=80
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################
# Load the internal library code, passing on the CLI options, if any
#. ${SHELLSPEC_SPECFILE%/test/*}/main/lib/lib.sh 

#test.script.start $BU_MAIN_LIB_DIR/getopts.sh
declare GitHookFwk=src/main/githook-fwk
declare \
  OUT=$GitHookFwk/hooks/pre-commit \
  EnrolMeSh=$GitHookFwk/enrol-me.sh \
  TestDataDir=${SHELLSPEC_SPECFILE%/*}/test-data \
  TestRepoRoot=$SHELLSPEC_WORKDIR/TestRepo
  PrepIt=$SHELLSPEC_WORKDIR/prep-it
declare RepoIgnore=$TestRepoRoot/.gitignore.pre-commit

Describe "$OUT"
  declare SrcMain="${SHELLSPEC_PROJECT_ROOT}/src/main"

  stand-up() {
    git init -q $TestRepoRoot
    bash $EnrolMeSh -d $TestRepoRoot
  }

  tear-down() {
    rm -fr $TestRepoRoot
  }

  Describe "Bad path"
    Describe "individual commit/non-commit & ignores handling"
      Parameters
        failed.lint.md
        failed.syntax.pl
        failed.syntax.pm
        failed.syntax.sh
        failed.lint.sh
      End

      Describe "Interactive (non-commit): Doesn't ignore i.e. checks, correctly"
        It "fails check: $1"
          When run $OUT $TestDataDir/$1

          The status should not be success
          The stderr should match pattern \
            "*Pre-commit: Check* failed for file: '$TestDataDir/$1'*"
        End
      End

      Describe "Individual commit: checks correctly (and fails)"
        Before stand-up
        After tear-down

        run-it() {
          local Paths=( "${1##*/}" )
          if test "${2:-}"; then printf "%s\n" "${Paths[@]}" > $RepoIgnore; fi
          cp $1 $TestRepoRoot
          git -C $TestRepoRoot add ${1##*/}
          git -C $TestRepoRoot commit -qm'.'
        }

        It "ignores check: $1"
          When run run-it $TestDataDir/$1 t

          The status should be success
          The stderr should include \
            "Pre-commit: Check(s) ignored by user for file: '$1'"
        End

        It "checks & fails: $1"
          When run run-it $TestDataDir/$1

          The status should not be success
          The stderr should match pattern \
            "*Pre-commit: Check* failed for file: '$1'*"
        End
      End
    End

    Describe "group commit - fails fast correctly"
      cp-files() {
        git init -q $TestRepoRoot
        bash $EnrolMeSh -d $TestRepoRoot
        local f; while read f; do
          cp $f $TestRepoRoot/
        done < <(git ls-files | grep $TestDataDir/failed)
        git -C $TestRepoRoot/ add .
      }

      Before cp-files

      Describe "checks all correctly (and fails)"
        Example "all paths fail"
          declare count="$(ls -1 $TestRepoRoot/failed* | wc -l)"

          When run command git -C $TestRepoRoot/ commit -qm'.'
          The status should not be success
          The stderr should include \
            "Pre-commit: Check(s) failed for $count file(s)"
        End
      End

      Describe "checks correctly (and fails fast)"
        Example "first path fails"
          export GITHOOK_FWK_FAST_FAIL=t
          When run command git -C $TestRepoRoot/ commit -qm'.'
          The status should not be success
          The stderr should include "Pre-commit: Check(s) failed for 1 file(s)"
        End
      End

      Describe "ignores correctly (and succeeds)"
        set-ignore() {
          cp-files
          ls $TestRepoRoot/failed* |
            sed 's,.* /,,' > $TestRepoRoot/.gitignore.pre-commit
        }

        Before set-ignore

        Example "all paths succeeds"
          declare count="$(ls -1 $TestRepoRoot/failed* | wc -l)"

          When run command git -C $TestRepoRoot/ commit -qm'.'
          The status should be success
          The stderr should include \
            "Pre-commit: Check(s) ignored for $count file(s)"
        End
      End
    End
  End

  Describe "GP - Invocation"
    Describe "individual commit/non-commit & ignores handling"
      tear-down() {
        rm -fr $TestRepoRoot
      }

      Parameters
        passed.lint.md
        passed.lint.sh
        passed.syntax.sh
      End

      After tear-down

      Describe "Interactive (non-commit): Checks, correctly"
        It "checks ok - $1"
          When run $OUT $TestDataDir/$1

          The status should be success
          The stderr should match pattern \
            "*Pre-commit: Check* passed for file: '$TestDataDir/$1'*"
        End
      End

      Describe "Individual commit: Checks correctly"
        run-it() {
          stand-up
          cp $1 $TestRepoRoot
          git -C $TestRepoRoot add .
          git -C $TestRepoRoot commit -qm'.'
        }

        It "commits ok - $1"
          When run run-it $TestDataDir/$1

          The status should be success
          The stderr should include \
            "Pre-commit: Check(s) passed for 1 file(s)"
        End
      End
    End

    Describe "group commit/non-commit & ignores handling"
      Describe "Checks correctly"
        run-it() {
          stand-up
          cp $TestDataDir/passed* $TestRepoRoot
          git -C $TestRepoRoot add .
          git -C $TestRepoRoot commit -qm'.'
        }

        It "commits ok"
          When run run-it

          The status should be success
          The stderr should include \
            "Pre-commit: Check(s) passed for 3 file(s)"
        End
      End
    End
  End
End

#### END OF FILE
