FNAME=lib.sinclude ; LNAME=${FNAME//./\/}

Describe "$FNAME ($LNAME) - $BASH_SOURCE"
  %logger "Note that, for the pruposes of this testing, only the overridden builtins (".", "source") are tested since they are the primary/sole interface"
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
          The stderr should include 'Library not found'
        End
      End

      Describe 'file exists'
        Parameters
          . exist
          source exist
        End

        Describe 'bad SINCLUDE_PATH'
          Describe 'empty'
            Example "'$1 $2'"
              export SINCLUDE_PATH=
              When run invoke-it $1 $2 $SHELLSPEC_TMPBASE/$2
              The status should be failure
              The stdout should equal ''
              The stderr should include 'Library not found'
            End
          End
      
          Describe 'wrong'
            Example "'$1 $2'"
              export SINCLUDE_PATH=/tmp
              When run invoke-it $1 $2 $SHELLSPEC_TMPBASE/$2
              The status should be failure
              The stdout should equal ''
              The stderr should include 'Library not found'
            End
          End
        End

        Describe 'no wildcarding problems'
          Example "'$1 ${2}t'"
            export SINCLUDE_PATH=/tmp
            When run invoke-it $1 ${2}t $SHELLSPEC_TMPBASE/$2
            The status should be failure
            The stdout should equal ''
            The stderr should include 'Library not found'
          End
        End
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
      #eval $@
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

      Example "'$1 $2' - SINCLUDE_VERBOSE="
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

      Example "'$1 $2' - SINCLUDE_VERBOSE=2"
        SINCLUDE_VERBOSE=2

        When call invoke-it $1 $2
        The status should equal 0
        The stdout should equal ''
        The variable MYSELF should equal $2
        
        if [[ $2 == /* ]]; then
          The stderr should equal "Load: $2 - Starting... Done"
        else
          The stderr should equal "Load: $2 (in '$SHELLSPEC_TMPBASE/$2') - Starting... Done"
        fi
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
        The stdout should equal ''
        The variable MYSELF should equal $2

        if [[ $2 == /* ]]; then
          The stderr should equal "Load: $2 - Starting... Done
Load: $2 - Already loaded"
        else
          The stderr should equal "Load: $2 (in '$SHELLSPEC_TMPBASE/$2') - Starting... Done
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
