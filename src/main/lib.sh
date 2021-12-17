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

eval ${__LIB_SH__:-}
export __LIB_SH__=return

. ${BASH_SOURCE%.sh}/sinclude.sh
. console.sh path.sh

#### END OF FILE
