FNNAME=bash-utils.source LNAME=${FNNAME#*.}.sh PDIR=src/main/lib
LDIR=$(cd $PDIR >/dev/null && pwd)

Describe "ease of consumption"
  FName=$SHELLSPEC_TMPBASE/my-test.sh
  prep-it() {
    builtin echo "
#! /usr/bin/env
declare flag=\${1:-} ; shift
. $PDIR/$LNAME
case \${flag:-n} in n) ;; *) . $PDIR/$LNAME ;; esac
" > $FName
    chmod +x $FName
  }

  BeforeEach prep-it

  include-it() {
    local lib=$PDIR/$LNAME flag=${1:+y} ; case $flag in y) shift ;; esac

    # initially, use the builtin
    . $lib

    # And attempt to use the overridden command if necessary
    if test "${flag:-}" ; then . $lib ; fi
  }

  Context  'can be sourced - default behaviours - should '
    It 'be silent & without error'
      When run $FName
      The status should be success
    End

    It 'update the caller space'
      When call include-it
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

      Example "when reload is $1 (\$BASH_UTILS_SOURCE_RELOAD=${2:-})"
        BASH_UTILS_SOURCE_RELOAD=${2:-}
        When run $FName t
        The status should not be success
        The stderr should equal "
$FName: line 5: $PDIR/$LNAME ($LDIR/$LNAME) cannot load itself, use builtin(1)"
      End
    End
  End

  Context \
    'can be sourced - default behaviours persist with non-default verbosity - it should'
    Describe 'BASH_UTILS_SOURCE_ENH_REPORT set to empty/non-usable/off value)'
      Parameters
        0
        ''
        off
        wibble
      End

      Example "silent & without error BASH_UTILS_SOURCE_ENH_REPORT=${1:-unset}"
        BASH_UTILS_SOURCE_ENH_REPORT=$1
        When call include-it
        The status should be success
      End

      Example "update the caller space - BASH_UTILS_SOURCE_ENH_REPORT=${1:-unset}"
        When call include-it
        The status should be success
        The value "$(type -t bash-utils.source)" should equal 'function'
      End
    End

    Describe 'be verbose (BASH_UTILS_SOURCE_ENH_REPORT set - to usable value) - it should'
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
Source: $PDIR/$LNAME ($LDIR/$LNAME) - Starting ... Done"
                ;;
        esac

        builtin echo "$exp"
      }

      Example "have no error - BASH_UTILS_SOURCE_ENH_REPORT=$1"
        export BASH_UTILS_SOURCE_ENH_REPORT=$1
        When call $FName
        The stdout should equal "$(report_string $1 load)"
      End

      Example "update the caller space - BASH_UTILS_SOURCE_ENH_REPORT=$1"
        BASH_UTILS_SOURCE_ENH_REPORT=$1
        When call include-it
        The stdout should equal "$(report_string $1 load)"
        The value "$(type -t .)" should equal 'function'
        The value "$(type -t source)" should equal 'function'
      End
    End
  End
End

Describe "core bash-utils library loaded"
  It "dependant library load fails without bash-utils.is-loaded"
    When run bash-utils.is-loaded
    The status should not be success
    The stderr should include 'bash-utils.is-loaded'
  End

  Include $PDIR/$LNAME

  It "dependant library load fails with bash-utils.is-loaded"
    When call bash-utils.is-loaded
    The status should be success
  End
End

Describe 'recursive inclusion avoidance'
  Context "direct"
    Include $PDIR/$LNAME

    It "direct inclusion attempts of self i.e. $PDIR/$LNAME"
      When run source $PDIR/$LNAME
      The status should not be success
      The stderr should match pattern "
*evaluation.sh: line *: $PDIR/$LNAME ($LDIR/$LNAME) cannot load itself, use builtin(1)"
    End
  End

  Fname=$SHELLSPEC_TMPBASE/my-test.sh

  Describe 'direct recursion - not self'
    prep-it() {
      builtin echo "
#! /usr/bin/env
. $PDIR/$LNAME
. $Fname
" >$Fname
      chmod +x $Fname
    }
    BeforeEach 'prep-it'

    It 'direct recursion - not self'
      When run $Fname
      The status should not be success
      The stderr should equal "
$Fname: line 4: source recursion detected"
    End
  End

  prep-it() {
    sub=$SHELLSPEC_TMPBASE/sub.sh
    builtin echo "
#! /usr/bin/env
. $PDIR/$LNAME
. $sub
" >$Fname
    builtin echo ". $Fname" >$sub
    chmod +x $Fname
  }

  BeforeEach 'prep-it'

  It 'indirect recursion - not self'
    When run $Fname
    The status should not be success
    The stderr should equal "
$Fname: line 1: indirect source recursion detected"
  End
End

Describe "non-extant file inclusion"
  Include $PDIR/$LNAME

  NonExist=$SHELLSPEC_TMPBASE/non-exist.sh

  Context "bash-utils.source"
    Describe "throws for all verbose modes"
      Parameters
        0
        1
        2
      End

      Example "BASH_UTILS_SOURCE_ENH_REPORT=$1"
        BASH_UTILS_SOURCE_ENH_REPORT=$1
        When run . $NonExist
        The status should not be success
        The stderr should equal "
$NonExist: source(1) target file not found"
      End
    End
  End

  Context "bash-utils.ifsource"
    Describe "continues silently for non & cursory verbose mode"
      It 'continues silently for non-verbose mode (BASH_UTILS_SOURCE_ENH_REPORT=0)'
        When run bash-utils.ifsource $NonExist
        The status should be success
      End

      It "continues silently when non-verbose mode (BASH_UTILS_SOURCE_ENH_REPORT=1)"
        BASH_UTILS_SOURCE_ENH_REPORT=1

        When run bash-utils.ifsource $NonExist
        The status should be success
        The stdout should equal ''
      End
    End

    It 'reports correctly when in verbose mode (BASH_UTILS_SOURCE_ENH_REPORT=2)'
      BASH_UTILS_SOURCE_ENH_REPORT=2
      When run bash-utils.ifsource $NonExist
      The status should be success
      The stdout should equal "\
Source: $NonExist - Starting ... Done (not found)"
    End
  End
End

Describe "non-standard file names"
  Include $PDIR/$LNAME
  
  Fnm="$SHELLSPEC_TMPBASE/my test.sh"

  prep-it() { builtin echo exit > "$Fnm" ; chmod +x "$Fnm" ; }

  BeforeEach 'prep-it'

  It "file name containing whitespace - '$Fnm'"
    When run "$Fnm"
    The status should be success
  End
End

Describe "bash-utils.source() correctly reports source of non-extant file"
  Root=$SHELLSPEC_TMPBASE/my-test
  Top=$Root.sh
  Sub1=$Root/sub1.sh Sub2=$Root/sub2.sh Sub3=$Root/sub3.sh

  Describe "file/path not found"
    
    prep-it() {
      mkdir -p $Root
      cat<<!>$Top
#! /usr/bin/env bash
. $PDIR/$LNAME
. $Sub1
!
      chmod +x $Top
      cat<<!>$Sub1
#! /usr/bin/env bash
. $Sub2
!
      cat<<!>$Sub2
#! /usr/bin/env bash
. $Sub3
!
    }
    
    BeforeEach prep-it

    It "non-extant $Sub3 - minimal report"
      When run source $Top
      The status should not be success
      The stderr should equal "
$Sub3: source(1) target file not found"
    End

    It "non-extant $Sub3 - enhanced report"
      BASH_UTILS_SOURCE_ENHANCED_ERROR=true
      When run source $Top
      The status should not be success
      The stderr should equal "
$Sub3: source(1) target file not found
In $Sub2: line 2
In $Sub1: line 2
In $Top: line 3"
    End
  End

  Describe "syntax error"

    prep-it() {
      set +u
      mkdir -p $Root
      cat<<!>$Top
#! /usr/bin/env bash
. $PDIR/$LNAME

. $Sub1
!
      chmod +x $Top
      cat<<!>$Sub1
#! /usr/bin/env bash
. $Sub2
!
      cat<<!>$Sub2
#! /usr/bin/e
. $Sub3
!
      cat<<!>$Sub3
#! /usr/bin/env bash
case $fred in
  *) : ;;
esac
!
    }
    
    BeforeEach prep-it

    It "syntax error - minimal report"
      When run source $Top
      The status should not be success
      The stderr should equal "
$Sub3: line 3: syntax error near unexpected token \`*'
$Sub3: line 3: \` *) : ;;'"
    End

    It "syntax error - enhanced report"
      BASH_UTILS_SOURCE_ENHANCED_ERROR=true
      When run source $Top
      The status should not be success
      The stderr should equal "
$Sub3: line 3: syntax error near unexpected token \`*'
$Sub3.sh: line 3: \` *) : ;;'
$Sub2: line 2
$Sub1: line 2"
    End
  End
End

Describe "non-standard file locations"
  Include $PDIR/$LNAME
  
  Base="$SHELLSPEC_TMPBASE/my-test"
  Fnm="$Base.sh" ; Inc="$SHELLSPEC_TMPBASE/inc.sh" ; > $Inc

  prep-it() { builtin echo ". ../inc.sh" > $Base ; }

  BeforeEach 'prep-it'

  It "non-standard relative file locations"
    When run source $Base
    The status should be success
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
  End
End

Describe "multi-file inclusion in same namespace"
  Include $PDIR/$LNAME

  Top=$SHELLSPEC_TMPBASE/my-test

  prep-it() {
    rm -fr $Top* ; mkdir -p $Top
    local nm ; for nm in 1 2 3 ; do > $Top/$nm.sh ; done
  }

  BeforeEach 'prep-it'

  Example ". $Top/*"
    When run . $Top/*
    The status should be success
  End
End

Describe 'ease of access'
  Describe 'callers dir auto-accessible'
    TDIR=$SHELLSPEC_TMPBASE/my-test
    TOP=$TDIR/top.sh

    prep-it() {
      local sub=$TDIR/sub
      local lower=$sub/lower.sh

      rm -fr $sub* ; mkdir -p $sub

      cat<<!>$TOP
#! /usr/bin/env bash
. $PDIR/$LNAME
. sub/lower.sh
!
      chmod +x $TOP
      builtin echo return > $lower
    }

    BeforeEach prep-it

    Context 'varying verbosity levels'
      export BASH_UTILS_SOURCE_ENH_REPORT=

      It "on the QT i.e. BASH_UTILS_SOURCE_ENH_REPORT=${BASH_UTILS_SOURCE_ENH_REPORT:-unset}"
        When run source $TOP
        The status should be success
      End

      export BASH_UTILS_SOURCE_ENH_REPORT=1

      It "BASH_UTILS_SOURCE_ENH_REPORT=$BASH_UTILS_SOURCE_ENH_REPORT"
        When run source $TOP
        The stdout should equal '
.
.'
      End

      export BASH_UTILS_SOURCE_ENH_REPORT=2

      It "BASH_UTILS_SOURCE_ENH_REPORT=$BASH_UTILS_SOURCE_ENH_REPORT"
        When run source $TOP
        The stdout should equal "
Source: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ... Done
Source: 'sub/lower.sh' ('$TDIR/sub/lower.sh') - Starting ... Done"
      End

      unset BASH_UTILS_SOURCE_ENH_REPORT
    End
  End

  Include $PDIR/$LNAME

  Describe "explicitly"
    Fnm='!bash-utils/console.sh'

    It "simple - '$Fnm'"
      When run . "$Fnm"
      The status should be success
    End

    Fnm='!bash-utils/console/help.sh'

    It "complex - $Fnm"
      When run . "$Fnm"
      The status should be success
    End
  End

  Describe 'implicitly i.e. by default'
    Fnm=console.sh

    It "simple - $Fnm"
      When run . "$Fnm"
      The status should be success
    End

    Fnm=console/help.sh

    It "complex - $Fnm"
      When run . "$Fnm"
      The status should be success
    End
  End   
End

#### END OF FILE
