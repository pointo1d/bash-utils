FNNAME=bash-utils.source LNAME=${FNNAME#*.}.sh PDIR=src/main/lib
LDIR=$(cd $PDIR >/dev/null && pwd)

Describe "ease of consumption"
  include-it() {
    local lib=$PDIR/$LNAME flag=${1:+y} ; case $flag in y) shift ;; esac

    # initially, use the builtin
    . $lib

    # And attempt to use the overridden command if necessary
    if test "${flag:-}" ; then . $lib ; fi
  }

  Context  'can be sourced - default behaviours - should '
    It 'be silent & without error'
      When run include-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End

    It 'update the caller space'
      When call include-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
      The value "$(type -t bash-utils.source)" should equal 'function'
      The value "$(type -t source)" should equal 'function'
    End

    Describe 'fail to reload itself '
      include-it() { . $PDIR/$LNAME ; . $PDIR/$LNAME ; }

      Parameters
        disabled  ''
        disabled  0
        enabled   t
      End

      Example "when $1 - \$BASH_UTILS_SOURCE_RELOAD=${2:-}"
        BASH_UTILS_SOURCE_RELOAD=${2:-}
        When run include-it
        The status should not be success
        The stdout should equal ''
        The stderr should equal "\
FATAL !!! '$PDIR/$LNAME' ('$LDIR/$LNAME') cannot load itself, use builtin(1)"
      End
    End
  End

  Context \
    'can be sourced - default behaviours persist with non-default verbosity - it should'
    Describe 'BASH_UTILS_SOURCE_VERBOSE set to empty/non-usable/off value)'
      Parameters
        0
        ''
        off
        wibble
      End

      Example "silent & without error BASH_UTILS_SOURCE_VERBOSE=${1:-unset}"
        BASH_UTILS_SOURCE_VERBOSE=$1
        When call include-it
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
      End

      Example "update the caller space - BASH_UTILS_SOURCE_VERBOSE=${1:-unset}"
        When call include-it
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
        The value "$(type -t bash-utils.source)" should equal 'function'
      End
    End

    Describe 'be verbose (BASH_UTILS_SOURCE_VERBOSE set - to usable value) - it should'
      Parameters
        1
        2
      End

      report_string() {
        local verb=${1:?'No verbosity level'} type=$2 exp=

        case $type:$verb in
          load:1|\
          noload:1) exp='
.'
                    ;;
          reload:1) exp='
.
.'                 ;;
          load:2) exp="
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ... Done"
                ;;
        esac

        builtin echo "$exp"
      }

      Example "have no error - BASH_UTILS_SOURCE_VERBOSE=$1"
        BASH_UTILS_SOURCE_VERBOSE=$1
        When call include-it
        The status should be success
        The stdout should equal "$(report_string $1 load)"
        The stderr should equal ''
      End

      Example "update the caller space - BASH_UTILS_SOURCE_VERBOSE=$1"
        BASH_UTILS_SOURCE_VERBOSE=$1
        When call include-it
        The status should be success
        The stdout should equal "$(report_string $1 load)"
        The stderr should equal ''
        The value "$(type -t .)" should equal 'function'
        The value "$(type -t source)" should equal 'function'
      End
    End
  End
End

Describe 'recursive inclusion avoidance'
  Include $PDIR/$LNAME

  Fname=$SHELLSPEC_TMPBASE/my-test.sh

  run-it() { . $PDIR/$LNAME ; }

  It 'direct inclusion attempts of self'
    When run run-it
    The status should not be success
    The stdout should equal ''
    The stderr should equal "\
FATAL !!! '$PDIR/$LNAME' ('$LDIR/$LNAME') cannot load itself, use builtin(1)"
  End

  It 'direct recursion'
    run-it() {
      builtin echo ". $Fname" >$Fname
      . $Fname
    }

    When run run-it
    The status should not be success
    The stdout should equal ''
    The stderr should equal \
      "FATAL !!! Recursive inclusion detected in '$Fname'"
  End

  It 'indirect recursion'
    run-it() {
      sub=$SHELLSPEC_TMPBASE/sub.sh
      builtin echo ". $sub" >$Fname
      builtin echo ". $Fname" >$sub

      . $Fname
    }

    When run run-it
    The status should not be success
    The stdout should equal ''
    The stderr should equal \
      "FATAL !!! Recursive inclusion detected in '$Fname'"
  End
End

Describe "non-extant file inclusion"
  Include $PDIR/$LNAME

  Describe "continues silently for non & cursory verbose mode"
  It 'continues silently for non-verbose mode (BASH_UTILS_SOURCE_VERBOSE=0)'
      When run bash-utils.ifsource $SHELLSPEC_TMPBASE/non-exist.sh
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End

    It "continues silently when non-verbose mode (BASH_UTILS_SOURCE_VERBOSE=1)"
      BASH_UTILS_SOURCE_VERBOSE=1

      When run bash-utils.ifsource $SHELLSPEC_TMPBASE/non-exist.sh
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End
  End

  It 'reports correctly when in verbose mode (BASH_UTILS_SOURCE_VERBOSE=2)'
    BASH_UTILS_SOURCE_VERBOSE=2
    When run bash-utils.ifsource $SHELLSPEC_TMPBASE/non-exist.sh
    The status should be success
    The stdout should equal "\
Source: '$SHELLSPEC_TMPBASE/non-exist.sh' - Starting ... Done (not found)"
    The stderr should equal ''
  End
End

Describe "non-standard file names"
  Include $PDIR/$LNAME
  
  Fnm="$SHELLSPEC_TMPBASE/my test.sh"

  run-it() { builtin echo return > "$Fnm" ; . "$Fnm" ; }

  It "file name containing whitespace - '$Fnm'"
    When run run-it
    The status should be success
    The stdout should equal ''
    The stderr should equal ''
  End
End

Describe "one-liner multi-file inclusion"
  run-it() {
    local nm ; for nm in 1 2 ; do > $SHELLSPEC_TMPBASE/file$nm.sh ; done
    . $PDIR/$LNAME $SHELLSPEC_TMPBASE/file1.sh $SHELLSPEC_TMPBASE/file2.sh
  }

  It ". <file1> <file2>"
    When run run-it
    The status should be success
    The stdout should equal ''
    The stderr should equal ''
  End
End

Describe "multi-file inclusion in same namespace"
  Include $PDIR/$LNAME

  Top=$SHELLSPEC_TMPBASE/my-test
  prep-it() {
    mkdir -p $Top
    local nm ; for nm in 1 2 3 ; do > $Top/$nm.sh ; done
  }

  BeforeEach 'prep-it'

  Example ". $Top/*"
    When run . $Top/*
    The status should be success
    The stdout should equal ''
    The stderr should equal ''
  End
End

Describe 'ease of access'
  Describe 'callers dir auto-accessible'
    TDIR=$SHELLSPEC_TMPBASE/my-test
    TOP=$TDIR/top.sh

    prep-it() {
      local sub=$TDIR/sub
      local lower=$sub/lower.sh

      mkdir -p $sub

      builtin echo return > $lower
      builtin echo "
. $PDIR/$LNAME
. sub/lower.sh
" >$TOP
      chmod +x $TOP
    }

    BeforeEach 'prep-it'

    Context 'varying verbosity levels'
      export BASH_UTILS_SOURCE_VERBOSE=

      It "on the QT i.e. BASH_UTILS_SOURCE_VERBOSE=${BASH_UTILS_SOURCE_VERBOSE:-unset}"
        When run $TOP
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
      End

      export BASH_UTILS_SOURCE_VERBOSE=1

      It "BASH_UTILS_SOURCE_VERBOSE=$BASH_UTILS_SOURCE_VERBOSE"
        When run $TOP
        The status should be success
        The stdout should equal '
.
.'
        The stderr should equal ''
      End

      export BASH_UTILS_SOURCE_VERBOSE=2

      It "BASH_UTILS_SOURCE_VERBOSE=$BASH_UTILS_SOURCE_VERBOSE"
        When run $TOP
        The status should be success
        The stdout should equal "
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ... Done
Source: 'sub/lower.sh' ('$TDIR/sub/lower.sh') - Starting ... Done"
        The stderr should equal ''
      End

      unset BASH_UTILS_SOURCE_VERBOSE
    End
  End

  Include $PDIR/$LNAME

  Describe "explicitly"
    Fnm='!bash-utils/console.sh'

    It "simple - '$Fnm'"
      When run . "$Fnm"
      The output should equal ''
      The stderr should equal ''
      The status should equal 0
    End

    Fnm='!bash-utils/console/help.sh'

    It "complex - $Fnm"
      When run . "$Fnm"
      The output should equal ''
      The stderr should equal ''
      The status should equal 0
    End
  End

  Describe 'implicitly i.e. by default'
    Fnm=console.sh

    It "simple - $Fnm"
      When run . "$Fnm"
      The output should equal ''
      The stderr should equal ''
      The status should equal 0
    End

    Fnm=console/help.sh

    It "complex - $Fnm"
      When run . "$Fnm"
      The output should equal ''
      The stderr should equal ''
      The status should equal 0
    End
  End   
End

#### END OF FILE
