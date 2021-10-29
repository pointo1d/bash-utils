FNAME=lib.sinclude ; LNAME=${FNAME//./\/}

Describe "$FNAME ($LNAME) - $BASH_SOURCE"
  Include src/main/$LNAME.sh

  call-it() { eval $@ ; }

  Describe 'no paths is fatal'
    Parameters
      lib.sinclude
      .
      source
    End

    Example "BP: no path(s) is fatal"
      When run call-it $1
      The stderr should include 'Nothing to load'
      The status should not equal 0
    End
  End

  Describe 'non-existant file is fatal'
    Parameters
      lib.sinclude not-exist
      . not-exist
      source not-exist
    End

    Example "BP: '$1 $2' is fatal - not found"
      When run call-it $1 $2
      The stderr should include 'Library not found'
      The status should not equal 0
    End
  End

  Describe 'existing file is included successfully - silently'
    Parameters
      lib.sinclude exist
      . exist
      source exist
      lib.sinclude exist.sh
      . exist.sh
      source exist.sh
    End

    Example "GP: '$1 $2'"
      PATH=$PATH:/tmp
      echo "echo included" > /tmp/$2
      When run call-it $1 $2
      rm /tmp/$2
      The status should equal 0
      The output should equal 'included'
    End
  End

  Describe 'existing file is included only once successfully - silently'
    Parameters
      lib.sinclude exist
      . exist
      source exist
      lib.sinclude exist.sh
      . exist.sh
      source exist.sh
    End

    Example "GP: '$1 $2'"
      PATH=$PATH:/tmp
      echo "echo included" > /tmp/$2
      When run call-it "$1 $2 ; $1 $2"
      rm /tmp/$2
      The status should equal 0
      The output should equal 'included'
    End
  End

  Describe 'existing file is included successfully - verbosely'
    Parameters
      lib.sinclude exist
      . exist
      source exist
      lib.sinclude exist.sh
      . exist.sh
      source exist.sh
    End

    Example "GP: '$1 $2'"
      PATH=$PATH:/tmp
      > /tmp/$2
      When run call-it "SINCLUDE_VERBOSE=t $1 $2"
      rm /tmp/$2
      The status should equal 0
      The output should match pattern 'Load * Done'
    End
  End

  Describe 'existing file is included only once successfully - verbosely'
    Parameters
      lib.sinclude exist
      . exist
      source exist
      lib.sinclude exist.sh
      . exist.sh
      source exist.sh
    End

    Example "GP: '$1 $2'"
      PATH=$PATH:/tmp 
      > /tmp/$2
      When run call-it "SINCLUDE_VERBOSE=t $1 $2 ; $1 $2"
      rm /tmp/$2
      The status should equal 0
      The output should match pattern 'Load * Done'
    End
  End

  Describe 'local i.e. bash-utils, library file(s)'
    Parameters
      lib.sinclude path
      . path
      source path
      lib.sinclude console/help
      . console/help
      source console/help
    End

    Example "$1 $2"
      When run $1 $2
      The output should equal ''
      The stderr should equal ''
      The status should equal 0
    End
  End
End
