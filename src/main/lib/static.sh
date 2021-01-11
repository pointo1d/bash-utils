#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         lib.sh
# Description:  Betteredge specific test library routines - as with Betteredge
#               itself, a test campaign comprises one, or more, test cases, each
#               of which comprises one, or more, inidivdual tests. Note
#               that the code herein, although having the same foundations as
#               the Betteredge code, aren't copied & pasted from the Betteredge
#               code. Moreover, wheresoever appropriate, individual test
#               routines i.e. test.*(), mirror those made available via the Perl
#               Test::More module.
###############################################O################################

eval ${__lib_static_sh__:-}
export __lib_static_sh__=return

#-------------------------------------------------------------------------------
# Function:     bash-utils.static()
# Synopsis:
#   bash-utils.static [OPTS] VAR[=VAL] [VAR[=VAL] ...]
# Description:  Routine to reduce shell script clutter by providing a static
#               variable emulation capability in a single-line whilst also
#               providing errexit friendliness i.e. disparate declaration &
#               assignment - thus allowing the assignment to blow up if
#               approriate; Otherwise i.e. in a single line declaration &
#               assignment, any error resulting from a backtick command value
#               determination is overridden by the declaration itself - the
#               backtick command is evaluated first and the shell determines the
#               outcome based on the result of the declaration _NOT_ the
#               assignment).
# Takes:        $1 - $n - options as per declare(1).
#               VAR     - the var name.
#               VAL     - the optional value.
# Returns:      As per declare(1)
# Variables:    None
# To do:        Implement a more elegant solution that merely provisions an
#               override for declare(1) that adds in and intercepts, an extra
#               non-attribute setting option (to define 'static` definition(s)).
#-------------------------------------------------------------------------------
bash-utils.static() {
  # Build a list of & extract, the opts - they're due to be passed, ad-verbatim,
  # on to declare(1). As it currently stands, this relies on the fact that all
  # of the opts for declare(1) are simple i.e. take no value
  local opts=() var= val=

  while true ; do
    case "${1:+y}":"$1" in
      y:-*)   opts+=($OPTARG)
              shift
              ;;
      y:*=*)  var="${1#=*}" ; val="${1%*=}"
              declare -g ${opts[@]:+-${opts[@]}} $var
              eval $var=${val:+"$val"}
              ;;
      y:*)    var=$1
              declare -g ${opts[@]:+-${opts[@]}} $var
              ;;
      *)      break ;;
    esac

    shift
  done
}

#### END OF FILE
