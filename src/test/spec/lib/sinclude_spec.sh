FNAME=lib.sinclude ; LNAME=${FNAME//./\/}

Describe "$FNAME ($LNAME) - $BASH_SOURCE"
  Include ../main/$LNAME.sh

  call-it() { eval $@ ; }

  Describe 'no paths is fatal'
    Parameters
      .
      source
    End

    Example "BP: '$1' is fatal - no path(s)"
      When run call-it $1
      The stderr should include 'Nothing to load'
      The status should not equal 0
    End
  End

  Describe 'not existant file is fatal'
    Parameters
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
      . exist
      source exist
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
      . exist
      source exist
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
      . exist
      source exist
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
      . exist
      source exist
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
End
