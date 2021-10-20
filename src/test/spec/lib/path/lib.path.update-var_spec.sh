FNAME=lib.path.update-var

Describe "$FNAME"
  Include ../main/lib/path.sh

  call-it() { $FNAME $@ ; }

  It "BP: $FNAME -or -n VPATH - s/b fatal"
    When run call-it -or -n VPATH
    The stderr should include 'No paths'
    The status should not equal 0
  End

  It "$FNAME -or -n VPATH /bin"
    VPATH=/bin
    When call $FNAME -or -n VPATH /bin
    The variable VPATH should equal ''
    The status should equal 0
  End

  It "$FNAME -oa -n VPATH /bin"
    VPATH_i=/sbin:/bin:/usr/bin
    VPATH=$VPATH_i
    When call $FNAME -oa -n VPATH /bin
    The variable VPATH should equal $VPATH_i
  End

  It "$FNAME -oa -n VPATH /usr/local/bin"
    VPATH_i=/sbin:/bin:/usr/bin
    VPATH=$VPATH_i
    When call $FNAME -oa -n VPATH /usr/local/bin
    The variable VPATH should equal $VPATH_i:/usr/local/bin
  End

  It "$FNAME -or -n VPATH /sbin /bin /usr/bin"
    VPATH=/sbin:/bin:/usr/bin:/sbin
    When call $FNAME -or -n VPATH /sbin
    The variable VPATH should equal '/bin:/usr/bin'
  End

  It "$FNAME -or -n VPATH /sbin"
    VPATH_i=/sbin:/bin:/usr/bin:/sbin
    VPATH=$VPATH_i
    When call $FNAME -or -n VPATH /sbin /bin /usr/bin
    The variable VPATH should equal ''
  End
End
