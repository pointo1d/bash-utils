#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         call-stack.sh
# Description:  Bash library script to unit test the call-stack utils.
################################################################################

# Load the internal library code, passing on the CLI options, if any
. ${BASH_SOURCE%/scripts/*}/lib/lib.sh 

test.script.start $BASH_UTILS_MAIN_LIB_DIR/shell-option.sh

run-command ". $TEST_OUT"

test.assert.command.exit-code.success
test.assert.command.output-content

run-command ". $TEST_OUT"
test.assert.command.exit-code.success 'multi-include'
test.assert.command.output-content 'multi-include'

run-command \
  ". $TEST_OUT ; shopt -p mailwarn >&2 ; bash-utils.shell-option mailwarn"
test.assert.command.exit-code.success 'bash-utils.shell-option mailwarn'
test.assert.ok 'bash-utils.shell-option mailwarn' \
  "test '$(<$TEST_STDERR_CAPTURE)' = '$(<$TEST_STDOUT_CAPTURE)'"

run-command \
  ". $TEST_OUT ; shopt -po errtrace >&2 ; bash-utils.shell-option errtrace"
test.assert.command.exit-code.success 'bash-utils.shell-option errtrace'
test.assert.ok 'bash-utils.shell-option errtrace' \
  "test '$(<$TEST_STDERR_CAPTURE)' = '$(<$TEST_STDOUT_CAPTURE)'"

test.script.done

#### END OF FILE
