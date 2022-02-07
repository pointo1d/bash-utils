FNNAME=lib.sinclude LNAME=${FNNAME//./\/}.sh PDIR=src/main
LDIR=$(cd $PDIR >/dev/null && pwd)

Describe "The OUT ('$LNAME') can itself be included"
  include-it() {
    : $FNNAME, $LNAME, $PDIR, $LDIR
    local lib=$PDIR/$LNAME flag=${1:+y} ; case $flag in y) shift ;; esac

    builtin . $lib
    if test "${flag:-}" ; then builtin . $lib ; fi
  }

  Context 'single attempt'
    Context 'varying verbosity levels'
      SINCLUDE_VERBOSE=

      It "on the QT i.e. SINCLUDE_VERBOSE=${SINCLUDE_VERBOSE:-unset}"
        When run include-it
        The status should be success
        The stdout should equal ''
        The stderr should equal ''
      End

      SINCLUDE_VERBOSE=1

      It "SINCLUDE_VERBOSE=$SINCLUDE_VERBOSE"
        When run include-it
        The status should be success
        The stdout should equal '....'
        The stderr should equal ''
      End

      SINCLUDE_VERBOSE=2

      It "SINCLUDE_VERBOSE=$SINCLUDE_VERBOSE"
        When run include-it
        The status should be success
        The stdout should equal "\
Load: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Starting ...
Load: '$PDIR/${LNAME/.sh}/announce.sh' ('$LDIR/${LNAME/.sh}/announce.sh') - Starting ... Done
Load: '$PDIR/$LNAME' ('$LDIR/$LNAME') - Done"
        The stderr should equal ''
      End
    End
  End
 
  Context 'multiple attempts'
    It 'first time'
      When run include-it
      The status should be success
      The stdout should equal ''
      The stderr should equal ''
    End

    Describe 'repeated inclusion'
      Context 'disallowed i.e. SINCLUDE_RELOAD unset'
        It '- verbosely i.e. SINCLUDE_NOWARN unset'
          SINCLUDE_NOWARN= SINCLUDE_RELOAD=
          When run include-it t
          The status should be success
          The stdout should equal ''
          The stderr should equal \
            "WARNING !!! '$PDIR/$LNAME' ('$LDIR/$LNAME') already loaded"
        End
        
        It '- silently i.e. SINCLUDE_NOWARN set'
          SINCLUDE_NOWARN=fred SINCLUDE_RELOAD=
          When run include-it t
          The status should be success
          The stdout should equal ''
          The stderr should equal ''
        End
      End

      Context 'allowed i.e. SINCLUDE_RELOAD set'
        It '- verbosely i.e. SINCLUDE_NOWARN unset'
          SINCLUDE_NOWARN= SINCLUDE_RELOAD=fred
          When run include-it t
          The status should be success
          The stdout should equal ''
          The stderr should equal ''
        End
        
        It '- silently i.e. SINCLUDE_NOWARN set'
          SINCLUDE_NOWARN=fred SINCLUDE_RELOAD=
          When run include-it t
          The status should be success
          The stdout should equal ''
          The stderr should equal ''
        End
      End
    End
  End

  Describe 'bash-utils lib dir auto-accessible'
    %logger "file:: $PDIR/$LNAME"
    #Include $PDIR/$LNAME
    include-it() {
      . $PDIR/$LNAME
      eval $@
    }

    Context 'simple - console'
      Parameters
        . console.sh
        source console.sh
      End

      Example "$1 $2"
        When run include-it
        The output should equal ''
        The stderr should equal ''
        The status should equal 0
      End
    End

    Describe "complex, direct ('console/help')"
      Parameters
        . console/help.sh
        source console/help.sh
      End

      Example "$1 $2"
        When run include-it
        The output should equal ''
        The stderr should equal ''
        The status should equal 0
      End
    End
  End

  Describe 'callers dir auto-accessible'
    run-it() {
      local dir=$SHELLSPEC_TMPBASE/my-test
      local sub=$dir/sub

      local upper=$dir/upper.sh lower=$sub/lower.sh

      mkdir -p $sub

      echo return > $lower
      echo ". sub/lower.sh" > $upper

      . $PDIR/$LNAME
      . $upper
    }
      
    It "upper.sh -> sub/lower.sh"
      When call run-it
      The output should equal ''
      The stderr should equal ''
      The status should equal 0
    End
  End
End

#Describe "$FNNAME() - good path i.e. no fatalities ($LNAME)"
#  invoke-it() {
#    : $# - $@
#    local t=$SHELLSPEC_TMPBASE/${2//$SHELLSPEC_TMPBASE}
#    echo "export MYSELF=$2" > $t
#    SINCLUDE_PATH=$SHELLSPEC_TMPBASE
#
#    eval $@
#  }
#
#  invoke-it-twice() {
#    : $# - $@
#    local cmd="$1" fnm="$2"
#    local t=$SHELLSPEC_TMPBASE/${fnm//$SHELLSPEC_TMPBASE}
#    echo "export MYSELF=$fnm" > $t
#    SINCLUDE_PATH=$SHELLSPEC_TMPBASE
#
#    eval $cmd $fnm
#    eval $cmd $fnm
#  }
#
#  Describe 'Successful inclusion of the OUT - at each reporting level'
#    Parameters
#      ''
#      0
#      1
#      2
#    End
#
#    Example "SINCLUDE_VERBOSE='$1'"
#      run-it() {
#        local v="${1:-}" ; shift
#        export SINCLUDE_VERBOSE="${v:-}"
#        builtin . src/main/$LNAME
#      }
#
#      When call run-it $1
#      The status should be success
#      The stderr should equal ''
#      if [ ! "${1:-}" ]; then
#        exp=
#      elif [ ${1:-} = 0 ]; then
#        exp=""
#      elif [ ${1:-} = 1 ]; then
#        exp='...'
#      elif [ ${1:-} = 2 ]; then
#        exp="Load: 'src/main/$LNAME', file: '$LDIR/$LNAME' - Starting ...
#Load: 'src/main/$LNAME/announce.sh', file: '$LDIR/$LNAME/announce.sh' - Starting ...
#Load: 'src/main/$LNAME/announce/stack.sh', file: '$LDIR/$LNAME/announce/stack.sh' - Starting ... Done
#Load: 'src/main/$LNAME/announce.sh', file: '$LDIR/$LNAME/announce.sh' - Done
#Load: 'src/main/$LNAME', file: '$LDIR/$LNAME' - Done"
#      fi
#      The stdout should equal "$exp"
#    End
#  End
#
#  Include src/main/$LNAME
#  
#  Describe 'existing file is included - silently'
#    Parameters
#      . exist
#      source exist
#      . exist.sh
#      source exist.sh
#      . $SHELLSPEC_TMPBASE/exist.sh
#      source $SHELLSPEC_TMPBASE/exist.sh
#    End
#
#    Example "'$1 $2' - SINCLUDE_VERBOSE unset"
#      unset SINCLUDE_VERBOSE
#      When call invoke-it $1 $2
#
#      The status should be success
#      The stdout should equal ''
#      The variable MYSELF should equal $2
#    End
#
#    Example "'$1 $2' - SINCLUDE_VERBOSE=0"
#      SINCLUDE_VERBOSE=0
#      When call invoke-it $1 $2
#
#      The status should be success
#      The stdout should equal ''
#      The variable MYSELF should equal $2
#    End
#  End
#
#  Describe 'existing file is included - verbosely'
#    Parameters
#      . exist
#      source exist
#      . exist.sh
#      source exist.sh
#      . $SHELLSPEC_TMPBASE/exist.sh
#      source $SHELLSPEC_TMPBASE/exist.sh
#    End
#
#    Example "'$1 $2' - SINCLUDE_VERBOSE=1"
#      SINCLUDE_VERBOSE=1
#      When call invoke-it $1 $2
#      The status should equal 0
#      The stderr should equal ''
#      The variable MYSELF should equal $2
#      The stdout should equal '.'
#    End
#
#    Example "'$1 $2' - SINCLUDE_VERBOSE=2"
#      SINCLUDE_VERBOSE=2
#
#      When call invoke-it $1 $2
#      The status should equal 0
#      The stderr should equal ''
#      The variable MYSELF should equal $2
#      
#      if [[ $2 == /* ]]; then
#        The stdout should equal "Load: '$2' - Starting ... Done"
#      else
#        The stdout should equal "Load: '$2', file: '$SHELLSPEC_TMPBASE/$2' - Starting ... Done"
#      fi
#    End
#  End
#
#  Describe "Nested includes"
#    Inner="$SHELLSPEC_TMPBASE/inner"
#    Outer="$SHELLSPEC_TMPBASE/outer"
#
#    nested-invoke() {
#      echo ". $Inner" > $Outer
#      echo return > $Inner
#
#      SINCLUDE_VERBOSE=${1:-} . $Outer
#    }
#    
#    Parameters
#      ''
##      0
##      1
##      2
#    End
#
#    Example "SINCLUDE_VERBOSE=${1:-unset}"
#      When call nested-invoke $1
#      The status should equal 0
#      The stderr should equal ''
#
#      if [ ! "${1:-}" -o "${1:-}" = 0 ]; then
#        exp=''
#      elif [ "${1:-}" = 1 ]; then
#        exp='..'
#      elif [ "${1:-}" = 2 ]; then
#        exp="
#Load: $Outer - Starting ...
#Load: $Inner - Starting ... Done
#Load: $Outer - Done"
#      fi
#      The stdout should equal "$exp"
#    End
#  End
#
#  Describe 'existing file is included only once'
#    Parameters
#      . exist
#      source exist
#      . exist.sh
#      source exist.sh
#      . $SHELLSPEC_TMPBASE/exist.sh
#      source $SHELLSPEC_TMPBASE/exist.sh
#    End
#
#    Example "'$1 $2' - SINCLUDE_VERBOSE="
#      SINCLUDE_VERBOSE=
#
#      When call invoke-it-twice $1 $2
#      The status should be success
#      The stdout should equal ''
#      The variable MYSELF should equal $2
#    End
#
#    Example "'$1 $2' - SINCLUDE_VERBOSE=1"
#      SINCLUDE_VERBOSE=1
#
#      When call invoke-it-twice $1 $2
#      The status should be success
#      The stdout should equal '..'
#      The variable MYSELF should equal $2
#    End
#
#    Example "$1 '$2' - SINCLUDE_VERBOSE=2"
#      SINCLUDE_VERBOSE=2
#
#      When call invoke-it-twice $1 $2
#      The status should equal 0
#      The stderr should equal ''
#      The variable MYSELF should equal $2
#
#      if [[ $2 == /* ]]; then
#        exp="Load: '$2' - Starting ... Done
#Load: '$2' - Already loaded"
#      else
#        exp="Load: '$2', file: '$SHELLSPEC_TMPBASE/$2' - Starting ... Done
#Load: '$2', file: '$SHELLSPEC_TMPBASE/$2' - Already loaded"
#      fi
#      The stdout should equal "$exp"
#    End
#  End
#
#End
