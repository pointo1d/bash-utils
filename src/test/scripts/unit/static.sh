#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################
shopt -so errexit errtrace nounset

# Load the internal library code, passing on the CLI options, if any
. ${BASH_SOURCE%/scripts/*}/lib/lib.sh 

test.script.start $BASH_UTILS_MAIN_LIB_DIR/static.sh

test.run-command ". $TEST_OUT"
test.assert.command.exit-code.success
test.assert.command.output.empty

test.run-command ". $TEST_OUT ; . $TEST_OUT"
test.assert.command.exit-code.success 'multi-include'
test.assert.command.output.empty 'multi-include'

test.run-command "
. $TEST_OUT
do-it() { bash-utils.static FrEd ; FrEd=A_val ; }
do-it
typeset -p FrEd
"
test.assert.command.exit-code.success 'declare & reference FrEd'
test.assert.command.output -o 'declare -- FrEd="A_val"' \
  'declare & reference FrEd'

test.script.done

#### END OF FILE
