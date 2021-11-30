#! /usr/bin/env bash
# vim: ai sw=2 sts=2 et
################################################################################
# File:		console/help.sh
# Description:	Shell script defining the console related library routines -
#               including, but not limited to, the introspective help & man
#               routines.
################################################################################

# ------------------------------------------------------------------------------
# Function:     console.help.to-stderr()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
console.help.do-introspective-synopsis() {
  local fname=$(lib.path-exists ${1:-$0})

  sed -n "
    /^while  *getopts  *['\"]/, /^done/ {
      /getopts/ {
        s,[^']*'\([^']*\)'.*,\1,
        s,[^'\"][*'\"]\([^'\"]\).*,\1,
        s,[a-zA-Z?], [-&],g
        s,]:, ARG],g
        s,^,${fname/*\/},
        H
      }
    }
    /#A#/{ s,#A# *,,; H }
    \${ x; s,\n, ,g; p}
  " $fname
}

# ------------------------------------------------------------------------------
# Function:     console.help.to-stderr()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
console.help.do-introspective-where() {
  local fname=$(lib.path-exists ${1:-$BASH_SOURCE})

  sed -n "
    /^while  *getopts  *['\"]/,/^done/ {
      /getopts/d
      /[	 ][ce][as]*[ce]/d
      /#H#/!d
      s,^[ 	]*, -,
      s,  #H#,  ,
      s,) #H#,  ,
      p
      /^done/s,.*,,p
    }
    /#W#/s,#W# *,,p
  " $fname 
}

# ------------------------------------------------------------------------------
# Function:     console.help.to-stderr()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
console.help.do-introspective-help() {
  local fname=$(lib.path-exists ${1:-$BASH_SOURCE})

  console.help.do-introspective-synopsis $fname | fmt -w $cols -s
}

# ------------------------------------------------------------------------------
# Function:     console.help.to-stderr()
# Description:  Routine provided to keep things DRY by replacing the requirement
#               for repeated 'echo -e "..." >&2' blocks with a call to this
#               routine.
# Takes:        $*  - the message to print to STDERR - note that escape sequence
#                     contained therein are honoured.
# ------------------------------------------------------------------------------
console.help.do-introspective-man() {
  local fname=$(lib.path-exists ${1:-$BASH_SOURCE})

  console.clear-screen

  cat<<EOT
SYNOPSIS
    $(console.help.do-introspective-synopsis $fname)

WHERE
$(console.help.do-introspective-where $fname)
    
DESCRIPTION
    $(sed -n '/#D#/s,[ 	]*#D#,,p' $fname)

ENVIRONMENT VARIABLES
    $(sed -n '/#V#/s,[ 	]*#V#,,p' $fname)
EOT

}

#### END OF FILE
