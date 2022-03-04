FNNAME=bash-utils.source LNAME=${FNNAME#*.}.sh PDIR=src/main/lib
LDIR=$(cd $PDIR >/dev/null && pwd)

Describe "The OUT ('$LNAME') itself"
  include-it() {
    : $FNNAME, $LNAME, $PDIR, $LDIR
    local lib=$PDIR/$LNAME flag=${1:+y} ; case $flag in y) shift ;; esac

    builtin . $lib
    if test "${flag:-}" ; then builtin . $lib ; fi
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

    It 'fail to reload itself'
      When call include-it t
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
      #\
      #  "WARNING !!! '$PDIR/$LNAME' ('$LDIR/$LNAME') already loaded"
      The value "$(type -t bash-utils.source)" should equal 'function'
    End

    It 'reload itself when enabled (using non-empty SINCLUDE_RELOAD)'
      SINCLUDE_RELOAD=t
      When call include-it t
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
      The value "$(type -t bash-utils.source)" should equal 'function'
    End
  End

  Describe \
    'can be sourced - default behaviours persist with non-default verbosity - it should'
    Context 'SINCLUDE_VERBOSE set to non-usable/off value)'
      Parameters
        0
        ''
        off
        wibble
      End

      Example "silent & without error SINCLUDE_VERBOSE=${1:-unset}"
        SINCLUDE_VERBOSE=$1
        When call include-it
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
      End

      Example "update the caller space - SINCLUDE_VERBOSE=${1:-unset}"
        When call include-it
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
        The value "$(type -t bash-utils.source)" should equal 'function'
      End

      Example "fail to reload itself - SINCLUDE_VERBOSE=${1:-unset}"
        When call include-it t
        The status should be success
        The stdout should equal ''
        The stderr should equal '' 
      End
    End

    Context 'be verbose (SINCLUDE_VERBOSE set - to usable value) - it should'
      Parameters
        1
        2
      End

      report_string() {
        local verb=${1:?'No verbosity level'} type=$2 exp=

        case $type:$verb in
          load:1|\
          noload:1) exp='
..'
                    ;;
          reload:1) exp='
..
..'                 ;;
          load:2) exp="
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ... Done"
                ;;
          noload:2) exp="
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ... Done
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Already loaded"
                ;;
          reload:2) exp="
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ... Done
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Reloading ... Done"
                ;;
        esac

        builtin echo "$exp"
      }

      Example "have no error - SINCLUDE_VERBOSE=$1"
        SINCLUDE_VERBOSE=$1
        When call include-it
        The status should be success
        The stdout should equal "$(report_string $1 load)"
        The stderr should equal ''
      End

      Example "update the caller space - SINCLUDE_VERBOSE=$1"
        SINCLUDE_VERBOSE=$1
        When call include-it
        The status should be success
        The stdout should equal "$(report_string $1 load)"
        The stderr should equal ''
        The value "$(type -t .)" should equal 'function'
        The value "$(type -t source)" should equal 'function'
      End

      Example "fail to reload itself - SINCLUDE_VERBOSE=$1"
        SINCLUDE_VERBOSE=$1
        When call include-it t
        The status should be success
        The stdout should equal "$(report_string $1 noload)"
        The stderr should equal ''
      End

      Example "reload when enabled (SINCLUDE_RELOAD set non-empty) - SINCLUDE_VERBOSE=$1"
        SINCLUDE_VERBOSE=$1 SINCLUDE_RELOAD=t
        When call include-it t
        The status should be success
        The stdout should equal "$(report_string $1 reload)"
        The stderr should equal ''
        The value "$(type -t bash-utils.source)" should equal 'function'
      End
    End
  End

  Describe 'make bash-utils libraries accessible'
    include-it() {
      local fnm=$1 ; shift
      builtin . $PDIR/$LNAME
      . $fnm
    }

    Describe "explicitly i.e. using the '!bash-utils' shortcut"
      Fnm=!bash-utils/console.sh

      Describe "simple"
        It "'$Fnm'"
          When run include-it "$Fnm"
          The output should equal ''
          The stderr should equal ''
          The status should equal 0
        End
      End

      Fnm=!bash-utils/console/help.sh

      Describe "complex"
        It "'$Fnm'"
          When run include-it "$Fnm"
          The output should equal ''
          The stderr should equal ''
          The status should equal 0
        End
      End
    End

    Describe 'implicitly i.e. by default'
      Fnm=console.sh

      Context 'simple'
        It "$Fnm"
          When run include-it "$Fnm"
          The output should equal ''
          The stderr should equal ''
          The status should equal 0
        End
      End

      Describe "complex"
        Fnm=console/help.sh

        It "$Fnm"
          When run include-it "$Fnm"
          The output should equal ''
          The stderr should equal ''
          The status should equal 0
        End
      End
    End   
  End
End

Describe 'Inclusion of the OUT by an external file'
  Describe 'callers dir auto-accessible'
    TDIR=$SHELLSPEC_TMPBASE/my-test
    run-it() {
      local sub=$TDIR/sub
      local upper=$TDIR/upper.sh lower=$sub/lower.sh

      mkdir -p $sub

      builtin echo return > $lower
      builtin echo ". sub/lower.sh" >$upper

      . $PDIR/$LNAME
      . $upper
    }

    Context 'varying verbosity levels'
           SINCLUDE_VERBOSE=

      It "on the QT i.e. SINCLUDE_VERBOSE=${SINCLUDE_VERBOSE:-unset}"
        When run run-it
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
      End

      SINCLUDE_VERBOSE=1

      It "SINCLUDE_VERBOSE=$SINCLUDE_VERBOSE"
        When run run-it
        The status should be success
        The stdout should equal '
..
....'
        The stderr should equal ''
      End

      SINCLUDE_VERBOSE=2

      It "SINCLUDE_VERBOSE=$SINCLUDE_VERBOSE"
        When run run-it
        The status should be success
        The stdout should equal "
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ... Done
Source: '$TDIR/upper.sh' - Starting ...
Source: 'sub/lower.sh' ('$TDIR/sub/lower.sh') - Starting ... Done
Source: '$TDIR/upper.sh' - Done"
        The stderr should equal ''
      End
    End
  End
End

Include $PDIR/$LNAME

Describe 'recursive inclusion detection & handling'
  Fname=$SHELLSPEC_TMPBASE/my-test.sh

  It 'direct recursion attempts are fatal'
    run-it() {
      builtin echo ". $Fname" >$Fname

      . $Fname
    }

    When run run-it
    The status should not be success
    The stdout should equal ''
    The stderr should equal \
      "FATAL !!! Direct recursive inclusion detected in '$Fname'"
  End

  It 'indirect recursion attempts are fatal'
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
      "FATAL !!! Indirect recursive inclusion detected in '$Fname'"
  End
End

Describe "inclusion of non-existant file(s) isn't fatal"
  Describe "continues silently for non & cursory verbose mode"
  It 'does so silently for non-verbose mode (SINCLUDE_VERBOSE=0)'
      When run bash-utils.ifsource $SHELLSPEC_TMPBASE/non-exist.sh
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End

    It "continues silently when non-verbose mode (SINCLUDE_VERBOSE=1)"
      SINCLUDE_VERBOSE=1

      When run bash-utils.ifsource $SHELLSPEC_TMPBASE/non-exist.sh
      The status should be success
      The stdout should equal '
.'
      The stderr should equal ''
    End
  End

  It 'reports correctly when in verbose mode (SINCLUDE_VERBOSE=2)'
    SINCLUDE_VERBOSE=2
    When run bash-utils.ifsource $SHELLSPEC_TMPBASE/non-exist.sh
    The status should be success
    The stdout should equal "\
Source: '$SHELLSPEC_TMPBASE/non-exist.sh' - Starting ... Not found"
    The stderr should equal ''
  End
End

Describe 'inclusion of mulitiple file on same line'
End

Describe 'inclusion of mulitiple file in same namespace'
End

#### END OF FILE