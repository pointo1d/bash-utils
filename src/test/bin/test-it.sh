#! /usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         test-it.sh
# Synopsis:
#   [bash] test-it.sh FILE
# Description:  This is a pure bash(1) script to generate markdown from well
#               formed & understood format of the accompanying shell scripts.
# Opts:         -c STR  - specify the test command to run, default - shellspec
#               -d      - use docker to run the tests
#               -C      - specify no clean working directory, default - clean
#                         (see Notes below).
# Args:         $*  - the options (if any) (incl. file names) to pass on to the
#                     test command.
# Notes:        * A clean working directory (default) uses git stash under the
#                 covers as follows...
#                 * pre-test  - git stash push -ka
#                 * post-test - git stash pop
#               * If used, options to pass on to the test command must be '--'
#                 separated from the options described above.
# To Do:        None.
# ------------------------------------------------------------------------------
# Author:       D. C. Pointon FIAP MBCS
# Date:         May 2022
################################################################################
shopt -os errexit # ; shopt -s extglob

declare OPTARG OPTIND opt use_docker clean=t cmd=shellspec no_op
declare -n cmd_opts
while getopts 'c:d:nC' opt ; do
  case $opt in
    c)  cmd=$OPTARG ;;
    d)  use_docker=y ;;
    n)  no_op=echo ;;
    C)  unset clean ;;
  esac
done

shift $((OPTIND - 1))

case "i$(type -t $cmd)" in
  i)  builtin echo "$cmd: command not found" >&2 ; exit 1 ;;
esac

case ${clean:-n} in n) : ;; *) eval ${no_op:-} git stash push -ak ;; esac

case ${docker:-n} in
  n)  declare shopt="$(shopt -op xtrace errexit)"
      shopt -uo xtrace errexit
      eval ${no_op:-} $cmd "$@"
      eval $shopt
      ;;
  y)  docker run -it --rm -v "$PWD:/src" 
esac

case ${clean:-n} in n) : ;; *) eval ${no_op:-} git stash pop ;; esac

#### END OF FILE
