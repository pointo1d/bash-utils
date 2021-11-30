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

eval ${__lib_ansi_sh__:-}
export __lib_ansi_sh__=return

declare -r ANSI_PREFIX='\u001b['
declare -r \
  ANSI_COLOUR_RESET=${ANSI_PREFIX}0m \
  ANSI_BOLD=${ANSI_PREFIX}1m \
  ANSI_UNDERLINE=${ANSI_PREFIX}4m \
  ANSI_REVERSED=${ANSI_PREFIX}7m \
  ANSI_RESET=${ANSI_PREFIX}0m \
  ANSI_BOLD_COLOUR=';1' \
  ANSI_FG_BASE='30' \
  ANSI_BG_BASE='40'

# The colours are sorted in numeric order i.e. their index corresponds to the
# value to be added to the base when forming the ANSI code
readonly export ANSI_COLOURS=(black red green yellow blue magenta cyan white)

#-------------------------------------------------------------------------------
# Function:     console.ansi.colour()
# Synopsis:
#   console.ansi.colour [-bru] COLOUR
# Description:  
# Takes:        -b  - enable bol/bright
#               -r  - enable reverse
#               -u  - enable underline
#-------------------------------------------------------------------------------
console.ansi.colour() {
  _lookup-colour() {
    local -a colours=(black red green yellow blue magenta cyan white reset)

    local code=$1
    case $1 in
      *001b*) ;;
      *)      code=$(
                typeset -p colours | sed -n "s,.*\[\([^]]*\)\]=\"$1\".*,\1,p"
              )

              code="\u001b[3$code"
              ;;
    esac

    echo "$code"
  }

  local OPTARG OPTIND opt bold=
  while getopts 'bru' opt ; do
    case $opt in b)
      bold=';1' ;;
    esac
  done

  shift $((OPTIND - 1))

  local colour="${1:?'No colour name or code'}"
  local code="$(_lookup-colour ${colour,,})"

  case ${code:+y} in
    y)  echo "$code${bold}m" ;;
    *)  echo "Not a colour code and colour not found: $colour" >&2
        exit 1
        ;;
  esac
}

#-------------------------------------------------------------------------------
# Function:     console.ansi.declare-colour()
# Description:  (Mostly) internal utility function to declare global variables
#               for the standard 8 colour range
#-------------------------------------------------------------------------------
console.ansi.__declare-colour() {
  local fg=$1 bold=$2 col=$3

  local base=ANSI_${fg^^}_BASE \
    idx=$(declare -p ANSI_COLOURS | sed 's,.*\[\([0-9]*\)\]="'$col'".*,\1,')

  ${idx:?Unknown colour: $col}

  local n=$(($idx + ${!base}))
  local nm=ANSI_${fg}_${bold:+${bold}_}${ANSI_COLOURS[$idx]^^} \
    val=$ANSI_PREFIX$n${bold:+$ANSI_BOLD_COLOUR}m

  declare -gr $nm=$val
  ANSI_ALL_COLOURS+=($nm)
}

################################################################################
################################################################################
#### MAIN BODY
################################################################################
################################################################################

declare col ; for col in ${ANSI_COLOURS[@]} ; do
  declare fg ; for fg in FG BG ; do
    declare bold ; for bold in '' BOLD ; do
      console.ansi.__declare-colour "$fg" "$bold" $col
    done
  done
done

#### END OF FILE
