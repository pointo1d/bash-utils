#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         ansi.sh
# Description:  Betteredge specific test library routines - as with Betteredge
#               itself, a test campaign comprises one, or more, test cases, each
#               of which comprises one, or more, inidivdual tests. Note
#               that the code herein, although having the same foundations as
#               the Betteredge code, aren't copied & pasted from the Betteredge
#               code. Moreover, wheresoever appropriate, individual test
#               routines i.e. test.*(), mirror those made available via the Perl
#               Test::More module. The ANSI code variables are all generated and are all
#               of the form ANSI_[<FGBG>_]['BOLD_']_<COLOUR>
###############################################O################################

eval ${__CONSOLE_CONFIRM_SH__:-}
export __CONSOLE_CONFIRM_SH__=return

#-------------------------------------------------------------------------------
# Function:     lib.console.confirm()
# Synopsis:
#   lib.console.confirm [-a CHR] [-o CHR [STR] [-o CHR [STR]] STR
# Description:  Function to implement a message-confirm interaction feature
# where the expected confirmation is yes ('y') or no ('n').
# Takes:        -y      - specify auto-accept default option
#               -d CHR  - specify the default option, default - 'n'
#               -o STR  - specify an option where STR is the option character
#                         with an optional whitespace separated eval'lable
#                         string containing code to run, default - 
#                         y return n exit.
#               -s STR  - specify the option checking strictness as one of
#                         * 'strict'  - only stated options, using the correct
#                                       case, are accepted
#                         * 'nocase'  - only stated options, case insensitive,
#                                       are accepted
#                         * 'default' - only stated responses, case insensitive,
#                                       are responded, for anything else, the
#                                       default is assumed
#                         Default - 'default'
# Args:         $*  - the prompt message, default - 'Confirm '
# Env Vars:     None
# Notes:        * -o 'y "return" n "exit"' is equiv to
#                 -o 'y "return"' -o 'n "exit"'
#               * '-y' is, as with other interactive commands, typically used
#                 when the user wnats a confirmation message but is prepared to
#                 accept the default option.
#               * If a selected option has no defined code, then the selected
#                 option character is returned on STDOUT
#-------------------------------------------------------------------------------
lib.console.confirm() {
  console.confirm._validate-opt() {
    local opt=${1:?'No option to validate'} ; shift
    case "${@,,}" in *$opt*) return ;; esac
    lib.console.die "Unknown option: $opt"
  }

  local OPTARG OPTIND opt auto_opt='' nocase='' default=n
  declare -A opts=([n]=exit [y]=return )
  while getopts 'a:d:n:s:y:' opt ; do
    case $opt in
      a)    auto_opt=$OPTARG ;;
      d)    default=$OPTARG ;;
      n|y)  opts[$opt]="$OPTARG";;
      s)    case $OPTARG in
              nocase|\
              strict|\
              default)  ;;
              *)        lib.console.fatal "Unknown option strictness: $opt" ;;
            esac
            ;;
    esac
  done

  console.confirm._validate-opt $default ${opts[@]}
  echo "lib.console.confirm() - STDOUT"
  echo "lib.console.confirm() - STDERR" >&2

  shift $((OPTIND - 1)) ;
  local prompt="${*:-Confirm}" resp='' options=${!opts[@]}
  prompt="$prompt ${options// /\/} [$default]? "

  read -p "$prompt" resp
  case "${resp:=$default}" in
    $default) ;;
    *)        ;;
  esac
}

#### END OF FILE
