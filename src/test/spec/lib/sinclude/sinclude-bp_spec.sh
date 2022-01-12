FNAME=lib.sinclude ; LNAME=${FNAME//./\/}

Describe "$FNAME ($LNAME) - $BASH_SOURCE"
%logger "Note that, for the purposes of this testing, only the overridden builtins (".", "source") are i.e. lib.sinclude() isn't, tested since they are the primary/sole interface"
  Include src/main/$LNAME.sh

  invoke-it() {
    local args=( $@ )
    case ${3:+y} in
      y)  echo "echo included" > $3
          args[2]=
          ;;
    esac

    eval ${args[@]}
  }

Describe echo
  It 'builtin'
    builtin-echo() { builtin echo -e 'newline\n' ; }
    When run builtin-echo
    Dump
    The stderr should equal ''
    The stdout should equal 'newline
'
  End
  It 'bin 1'
    bin-echo() { echo -e "newline\n" ; }
    When run bin-echo
    Dump
    The stderr should equal ''
    The stdout should equal 'newline
'
  End
  It 'bin 2'
    bin-echo() { echo -e "newline" ; }
    When run bin-echo
    Dump
    The stderr should equal ''
    The stdout should equal 'newline
'
  End
End

  Describe 'Bad paths [sic]: - fatal results'
    Describe 'no args i.e. no given path(s)'
      Parameters
        .
        source
      End

      Example "'$1'"
        When run invoke-it $1
        The status should be failure
        The stdout should equal ''
        The stderr should include 'Nothing to load'
      End
    End

    Describe 'not found file'
      Describe "file just doesn't exist"
        Parameters
          . not-exist
          source not-exist
        End

        Example "'$1 $2'"
          When run invoke-it $1 $2
          The status should be failure
          The stdout should equal ''
          The stderr should include 'No such file or directory'
        End
      End

      Describe 'file exists'
        Parameters
          . exist
          source exist
        End

        Describe 'empty SINCLUDE_PATH'
          Describe 'empty'
            Example "'$1 $2'"
              export SINCLUDE_PATH=
              When run invoke-it $1 $2 $SHELLSPEC_TMPBASE/$2
              The status should be failure
              The stdout should equal ''
              The stderr should include 'No such file or directory'
            End
          End
      
          Describe 'wrong SINCLUDE_PATH'
            Example "'$1 $2'"
              export SINCLUDE_PATH=/tmp
              When run invoke-it $1 $2 $SHELLSPEC_TMPBASE/$2
              The status should be failure
              The stdout should equal ''
              The stderr should include 'No such file or directory'
            End
          End
        End

        Describe 'no wildcarding problems'
          Example "'$1 ${2}t'"
            export SINCLUDE_PATH=$SHELLSPEC_TMPBASE
            When run invoke-it $1 ${2}t $SHELLSPEC_TMPBASE/$2
            The status should be failure
            The stdout should equal ''
            The stderr should include 'No such file or directory'
          End
        End
      End
    End

    Describe 'nested include file has error'
      It "syntax"
        invoke-it() {
          local \
            outer=$SHELLSPEC_TMPBASE/outer.sh \
            nested=$SHELLSPEC_TMPBASE/nested.sh
          
          echo for > $nested
          echo ". $nested" > $outer

          . $outer
        }
        export SINCLUDE_PATH=$SHELLSPEC_TMPBASE

        When run invoke-it
        The status should be failure
        The stdout should equal ''
        The stderr should not include 'No such file or directory'
      End

      It "bad command"
        invoke-it() {
          local \
            outer=$SHELLSPEC_TMPBASE/outer.sh \
            nested=$SHELLSPEC_TMPBASE/nested.sh
          
          echo for > $nested
          echo ". $nested" > $outer

          . $outer
        }
        export SINCLUDE_PATH=$SHELLSPEC_TMPBASE

        When run invoke-it
        The status should be failure
        The stdout should equal ''
        The stderr should not include 'No such file or directory'
      End
    End
  End

  Describe 'Good paths [sic] - no fatalities'
    invoke-it() {
      : $# - $@
      local t=$SHELLSPEC_TMPBASE/${2//$SHELLSPEC_TMPBASE}
      echo "export MYSELF=$2" > $t
      SINCLUDE_PATH=$SHELLSPEC_TMPBASE

      eval $@
    }

    invoke-it-twice() {
      : $# - $@
      local cmd="$1" fnm="$2"
      local t=$SHELLSPEC_TMPBASE/${fnm//$SHELLSPEC_TMPBASE}
      echo "export MYSELF=$fnm" > $t
      SINCLUDE_PATH=$SHELLSPEC_TMPBASE

      eval $cmd $fnm
      eval $cmd $fnm
    }

    Describe 'existing file is included - silently'
      Parameters
        . exist
        source exist
        . exist.sh
        source exist.sh
        . $SHELLSPEC_TMPBASE/exist.sh
        source $SHELLSPEC_TMPBASE/exist.sh
      End

      Example "'$1 $2' - SINCLUDE_VERBOSE unset"
        When call invoke-it $1 $2

        The status should be success
        The stdout should equal ''
        The variable MYSELF should equal $2
      End

      Example "'$1 $2' - SINCLUDE_VERBOSE=0"
        SINCLUDE_VERBOSE=0
        When call invoke-it $1 $2

        The status should be success
        The stdout should equal ''
        The variable MYSELF should equal $2
      End
    End

    Describe 'existing file is included - verbosely'
      Parameters
        . exist
        source exist
        . exist.sh
        source exist.sh
        . $SHELLSPEC_TMPBASE/exist.sh
        source $SHELLSPEC_TMPBASE/exist.sh
      End

      Example "'$1 $2' - SINCLUDE_VERBOSE=1"
        SINCLUDE_VERBOSE=1
        When call invoke-it $1 $2
        The status should equal 0
        The stderr should equal ''
        The variable MYSELF should equal $2
        The stdout should equal '.
'
      End

      Example "'$1 $2' - SINCLUDE_VERBOSE=2"
        SINCLUDE_VERBOSE=2

        When call invoke-it $1 $2
        The status should equal 0
        The stderr should equal ''
        The variable MYSELF should equal $2
        
        if [[ $2 == /* ]]; then
          The stdout should equal "Load: $2 - Starting... Done"
        else
          The stdout should equal "Load: $2 (in '$SHELLSPEC_TMPBASE/$2') - Starting... Done"
        fi
      End
    End

    Describe "Nested includes"
      Inner="$SHELLSPEC_TMPBASE/inner"
      Outer="$SHELLSPEC_TMPBASE/outer"

      nested-invoke() {
        echo ". $Inner" > $Outer
        echo return > $Inner

        . $Outer
      }

      Example "SINCLUDE_VERBOSE=1"
        SINCLUDE_VERBOSE=1
        
        When call nested-invoke
        The status should equal 0
        The stderr should equal ''

          The stdout should equal "..
"
      End

      Example "SINCLUDE_VERBOSE=2"
        SINCLUDE_VERBOSE=2
        
        When call nested-invoke
        The status should equal 0
        The stderr should equal ''

          The stdout should equal m"
Load: $Outer - Starting...
Load: $Inner - Starting... Done
Load: $Outer - Done"
      End
    End

    Describe 'existing file is included only once - silently'
      Parameters
        . exist
        source exist
        . exist.sh
        source exist.sh
        . $SHELLSPEC_TMPBASE/exist.sh
        source $SHELLSPEC_TMPBASE/exist.sh
      End

      Example "'$1 $2' - SINCLUDE_VERBOSE="
        When call invoke-it-twice $1 $2
        The status should be success
        The stdout should equal ''
        The variable MYSELF should equal $2

      End

      Example "$1 '$2' - SINCLUDE_VERBOSE=2"
        SINCLUDE_VERBOSE=2
        
        When call invoke-it-twice $1 $2
        The status should equal 0
        The stderr should equal ''
        The variable MYSELF should equal $2

        if [[ $2 == /* ]]; then
          The stdout should equal "Load: $2 - Starting... Done
Load: $2 - Already loaded"
        else
          The stdout should equal "Load: $2 (in '$SHELLSPEC_TMPBASE/$2') - Starting... Done
Load: $2 (in '$SHELLSPEC_TMPBASE/$2') - Already loaded"
        fi
      End
    End

    Describe 'local i.e. bash-utils, library file(s)'
      Describe 'simple - console'
        Parameters
          . console.sh
          source console.sh
        End

        Example "$1 $2"
          When run $1 $2
          The output should equal ''
          The stderr should equal ''
          The status should equal 0
        End
      End

      Describe 'complex - console/help'
        Parameters
          . console/help.sh
          source console/help.sh
        End

        Example "$1 $2"
          When run $1 $2
          The output should equal ''
          The stderr should equal ''
          The status should equal 0
        End
      End
    End
  End
End
