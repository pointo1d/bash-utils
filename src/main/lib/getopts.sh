#!/usr/bin/env bash
# vim: ai et fo+=r sw=2 sts=2
################################################################################
# File:         getopts.sh
# Description:  Pure bash(1) script implementing an extended version of the
#               standard getopts builtin.
###############################################O################################

eval ${LIB_GET_OPTIONS_SH:-}

# Load the assertions library
. ${BASH_SOURCE/%.sh/\/assert.sh}

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.to-stderr()
# Description:  Routine to report the given text to STDERR, eexpanding escape
#               sequences as appropriate.
# Takes:        $1  - Messgae to report.
#-------------------------------------------------------------------------------
bash-utils.console.to-stderr() { builtin echo -e "$*" >&2; }

#-------------------------------------------------------------------------------
# Function:     bash-utils.console.fatal()
# Description:  Routine to 
# Takes:        $1  - .
# Returns:      .
# Variables:    .
#-------------------------------------------------------------------------------
bash-utils.console.fatal() {
  bash-utils.console.to-stderr "$* !!!"
  exit 1
}

getopts.unknown-option() { bash-utils.console.fatal "Unknown option: '$1'"; }

################################################################################
################################################################################
########                            VARIABLES                           ########
################################################################################
################################################################################
readonly \
  ArgKeys="index" \
  OptKeys="short long" \
  StdKeys="action default has_val help_short help_long mandatory validate var"

declare -A Keys=(
  [ArgsListVarName]="$StdKeys $ArgKeys" [OptsListVarName]="$StdKeys $OptKeys"
)

# Define the lists names record
declare -gxA Lists=(
  [ArgsListVarName]="ArgsList:a" [OptsListVarName]="OptsList:A"
)

# Define the default options
declare DefaultOpts=(
  "short='-h'  long='--help'   action='getopts.do-help' \
    help_short='Gneerate usage' help_long='Generate cursory/shortform help'"
  "short='-m'  long='--man'    action='getopts.do-man' \
    help_short='Generate this extended help' \
    help_long='Generate this man(1) page style help'"
  "short='-x'  long='--xtrace' action='getopts.do-xtrace' \
    help_short='Enable debug' \
    help_long='Enable shell debug (xtrace)'"
)
readonly Keys DefaultOpts

################################################################################
################################################################################
########                            FUNCTIONS                           ########
################################################################################
################################################################################
#-------------------------------------------------------------------------------
# Function:     bash-utils.getopts.init()
# Description:  Routine to record and initialize the list variables, optionally
#               pre-loading the options list with the default options.
# Options:      -a  - specify alternate opts list variable name.
#               -d  - enable load of default options.
#               -o  - specify alternate args list variable name.
# Returns:      .
# Variables:    $ArgsListVarName  - the name of the args list variable.
#               $OptsListVarName  - the name of the opts list variable.
#-------------------------------------------------------------------------------
getopts.init() {
  local OPTARG OPTIND opt ld_defaults=""
  local -A types=()

  while getopts ':a:do:' opt; do
    local type="" key=""

    case $opt in
      d)    ld_defaults=t ;;
      a)    key=ArgsListVarName; type=a ;;&
      o)    key=OptsListVarName; type=A ;;&
      a|o)  bash-utils.value.assert.legal-var-name "$OPTARG"

            # ... save it (the var name)
            Lists[$key]="$OPTARG:$type"
            ;;
      *)    getopts.unknown-option $OPTARG ;;
    esac
  done

  # Initialize the lists
  local list; for list in "${!Lists[@]}"; do
    local nm=${Lists[$list]%:*} flag=${Lists[$list]#*:}
    eval declare -gx$flag $nm
    local -n var=$nm
    var=()
  done

  if ! test "${ld_defaults:-}"; then return; fi

  local opt
  for opt in "${DefaultOpts[@]}"; do
    getopts.define-opt $opt
  done
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.getopts.define-entry()
# Description:  Routine to 
# Takes:        $1  - Expected/allowable keys.
#               $2  - Entry definition.
# Returns:      .
# Variables:    .
#-------------------------------------------------------------------------------
getopts.build-entry() {
  getopts.assert.entry-definition.defined '' "$@";

  local var_nm=${1:-}; shift
  eval "$@"

  local key; for key in ${Keys[$var_nm]}; do
    : $key
    local val="${!key:-}"
    if ! test "${val:-}"; then continue; fi

    entry[$key]="${val:-}"
  done
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.getopts.define-entry()
# Description:  Routine to 
# Takes:        $1  - Expected/allowable keys.
#               $2  - Entry definition.
# Returns:      .
# Variables:    .
#-------------------------------------------------------------------------------
getopts.add-entry() {
  getopts.assert.entry-definition.defined '' "$2";

  local var_nm=${1:-} defn="$2"
  local list=${Lists[$var_nm]%:*}
  local -n var=$list

  # Update the target list with the entry
  if test "${entry[index]:-}"; then
    var[${entry[index]:-}]=( "$(declare -p entry)" )
  else
    var+=( "$(declare -p entry)" )
  fi
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.getopts.define-arg()
# Description:  Routine to 
# Takes:        $1  - .
# Returns:      .
# Variables:    .
#-------------------------------------------------------------------------------
getopts.define-arg() {
  getopts.assert.entry-definition.defined 'arg' "$@";
 
  local -A entry; getopts.build-entry ArgsListVarName "${@}"
  getopts.add-entry ArgsListVarName "$(declare -p entry)"
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.getopts.define-opt()
# Description:  Routine to 
# Takes:        $1  - .
# Returns:      .
# Variables:    .
#-------------------------------------------------------------------------------
getopts.define-opt() {
  getopts.assert.entry-definition.defined 'opt' "$@"
  
  local -A entry; getopts.build-entry OptsListVarName "${@}"

  getopts.assert.entry-definition.mandatory-keys-defined "short" "long"

  getopts.add-entry OptsListVarName "$(declare -p entry)"
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.getopts.define()
# Description:  Routine to 
# Takes:        $1  - .
# Returns:      .
# Variables:    .
#-------------------------------------------------------------------------------
getopts.define() {
  :
}

#-------------------------------------------------------------------------------
# Function:     bash-utils.getopts.getopts.parse-cli()
# Description:  Routine to 
# Takes:        $1  - .
# Returns:      .
# Variables:    .
#-------------------------------------------------------------------------------
getopts.parse-cli() {
  local rc=1 oldifs="$OLDIFS"
  IFS=" 	"

  declare -xg OPTIND OPTARG
  local -n next=OPTIND arg=OPTARG

  # Read a token at a time
  local token; for token; do
    getopts.__parse-token "${token:-}"
  done


  declare -xg OPTIND=$index IFS="$oldifs"
  return $rc
}

################################################################################
################################################################################
########                            MAIN BODY                           ########
################################################################################
################################################################################

# Conditionally initialize if there's owt on the inclusion line
if test $# -ne 0; then getopts.init "$@"; fi

export LIB_GET_OPTIONS_SH=return

#### END OF FILE
