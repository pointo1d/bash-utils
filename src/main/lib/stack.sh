#!/usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         source.sh
# Description:  Pure bash(1) script to provide a recursive inclusion avoiding
#               file inclusion capability whilst providing a simpler interface
#               such that the caller need only know a directory under which the
#               sourced file exists, so for example, this file may be included
#               merely as `. source` or even the help sub-library of console
#               may be included as `. console/help` - in these casaes this is
#               because the directory containing these elements is automgically
#               included in the PATH for free.
# Doc link:     ../../../docs/source.md
# Env vars:     $BASH_UTILS_STACK_ON_EMPTY  -
#                 specify the behaviour if/when top()/pop() called on an empty
#                 stack.Has one of a number of values as follows...
#                 * fatal             - a fatal error is thrown
#                 * warn              - a warning is thrown.
# Notes:
################################################################################

declare -A Methods=(
  [new]=class
  [exists]=class
  [fatal-error]=class
  [update]=inst
  [clone]=inst
  [push]=inst
  [pop]=inst
  [top]=inst
  [peek]=inst
  [seek]=inst
  [walk]=inst
  [depth]=inst
  [is-empty]=inst
  [is-equal]=inst
  [delete]=inst
  [update]=inst
)

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.fatal-error()
# Description:  .
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Never.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.stack.fatal-error() {
  local rc=1 ; case i${1//[0-9]} in i) rc=$1 ; shift ;; esac
  builtin echo -e "$*" >&2
  exit $rc
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.fatal-warn()
# Description:  .
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Never.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.stack.fatal-warn() { builtin echo -e "$*" >&2 ; }

# ------------------------------------------------------------------------------
# Function:     source.lib-stack._get_inst_name()
# Description:  .
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Never.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.stack.context-error() {
  bash-utils.stack.fatal-error "invalid context: $1 method on $2"
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack._get_inst_name()
# Description:  .
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      Never.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.stack.check-context() {
  local actual=${1:?'No actual context'} ; shift
  local caller=( $(caller 0) ) ; local exp=${Methods[${caller[1]##*.}]}
  case $exp in
    $actual*) case $exp:::$# in
                class:::0)  bash-utils.stack.fatal-error 'no stack name' ;;
              esac
              ;;
    *)        bash-utils.stack.fatal-error \
                "invalid context: $actual method on $exp"
              ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.check-existence()
# Description:  Routine to determine if the given stack exists and respond with 
#               a fatal error appropriately.
# Takes:        $1  - stack name.
#               $2  - optional fatal response flag. When 'n', non-existence is
#                     fatal, when 'y' existence is fatal, default - not fatal.
# Returns:      Never.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.stack.check-existence() {
  local caller=( $(caller 0) )
  local cond=$(bash-utils.stack.exists $1):::${2:-}
  local msg ; case $cond in
    n:::n)  msg="stack not found: $1" ;;
    y:::y)  msg="stack exists" ;;
    *)      return ;;
  esac

  bash-utils.stack.fatal-error "${caller[1]##*.}: $msg: $1"
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce._call_context_checker()
# Description:  .
# Opts:         None.
# Args:         $1  - actual context
# Returns:      Never.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.stack.calling-context() {
  local caller=( $(caller 0) ) caller_1=( $(caller 1) )
  : ${caller[@]}, ${caller_1[@]}
  local -A context=( [inst]= [method]=${caller[1]##*.} [context]= )
  : $(declare -p context)
  
  case ${caller_1[1]} in
    bash-utils.stack.*)   context[context]=class ;;
    *${context[method]})  context[inst]=${caller_1[1]//.${context[method]}}
                          context[context]=inst
                          ;;
    *)                    context[context]=class ;;
  esac

  declare -p context
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.exists()
# Description:  Function to create a new entry on the stack - if it's not the
#               first then it also updates the current entry with the line
#               number at which the new file is 'called` before add ing the new
#               entry
# Opts:         None
# Args:         $1  - name for the new stack
#               $2  - optional structure definition
# Returns:      None (atm).
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.exists() {
  local nm="${1:?'No stack name !!'}" found
  found="$(declare -p $nm 2>&1):::$(type -t $nm)"
  case "$found" in
    *:::function|\
    declare*$nm=*:::*)  found=y ;;
    *)                found=n ;;
  esac
  builtin echo $found
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.empty-behaviour()
# Description:  Called first for any sourced file, this routine records the
#               name, absolute path and "type" for the given library name &/or
#               path on the included stack.
# Takes:        $1  - instance.
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.empty-behaviour() {
local inst=${1:?'No instance'} caller=( $(caller 0) )

  case $($inst.is-empty) in
    y)  local msg="${caller[1]##*.}: cannot call on an empty stack ($inst)" 
        local reporter=${BASH_SOURCE_STACK_EMPTY_STACK:-warn}
        bash-utils.stack.fatal-${reporter/fatal/error} "$msg"
        ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.update()
# Description:  "instance" method to update the value of the given/default
#               element in-situ.
# Opts:         -n INT  - specify the index of the stack element to be
#                         updated - as an integer between 0 & <STACK>.depth()
# Takes:        $1 VAL  - specify the new value for the given element
# Returns:      
# Variables:    
# ------------------------------------------------------------------------------
bash-utils.stack.update() {
  local OPTARG OPTIND opt idx=0
  while getopts 'n:' opt ; do
    case $opt in
      n)  case "${idx//[0-9]}" in
            i)  idx=$OPTARG ;;
            *)  bash-utils.stack.fatal-error "Invalid integer: $OPTARG" ;;
          esac
          ;;
    esac
  done

  shift $((OPTIND-1))

  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  bash-utils.stack.empty-behaviour ${context[inst]}

  case $(${context[inst]}.is-empty) in y) return ;; esac

  local depth=$(${context[inst]}.depth)
  case $((depth - idx)) in
    -*) bash-utils.stack.fatal-error "Index out of range ($depth): $idx" ;;
  esac

  local -n stack=${context[inst]} ; stack[$idx]="$1"
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.push()
# Description:  Called first for any sourced file, this routine records the
#               given attribs for the lib and then saves them on the top of the
#               included stack.
# Takes:        $1  - lib name ( as supplied in the call).
#               $2  - fully pathed lib name
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.push() {
  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  case $# in
    0)  bash-utils.stack.fatal-warn "push: nothing to push"
        return
        ;;
  esac

  local -n stack=${context[inst]}
  : $#
  local e ; for e ; do : "$e" ; stack=( "$e" "${stack[@]}" ) ; done
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.peek()
# Description:  Routine to return the given/default element
# Takes:        $1  - optional set of attribs to return - by default, this is
#               the top set
# Returns:      The requested attrib set.
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.peek() {
  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  bash-utils.stack.empty-behaviour ${context[inst]}

  case $(${context[inst]}.is-empty) in y) return ;; esac

  local -n stack=${context[inst]}
  builtin echo "${stack[${1:-0}]}"
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.pop()
# Description:  Pops the top element off the include stack - assuming that...
#               * the stack isn't empty - the caller is expected to assert this
#                 via prior call to source.lib-stack.load.announce.is-empty().
#               * if the element to be popped is of interest to the caller, then
#                 the caller has already called bash-utils.source.top() to
#                 inspect/retrieve it.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.pop() {
  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  bash-utils.stack.empty-behaviour ${context[inst]}

  case $(${context[inst]}.is-empty) in y) return ;; esac

  local -n stack=${context[inst]}
  stack=( "${stack[@]:1}" )
}


# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.pop-attribs()
# Description:  Pops the top element(s) off the include stack - assumes that if
#               if the element(s) to be popped are of interest to the caller,
#               then the caller has already called bash-utils.source.top() to
#               inspect/retrieve them.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.depth() {
  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  local -n stack=${context[inst]}
  : $(declare -p context ${context[inst]} MyStack)
  builtin echo $((${#stack[@]} - 1))
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.pop-attribs()
# Description:  Pops the top element(s) off the include stack - assumes that if
#               if the element(s) to be popped are of interest to the caller,
#               then the caller has already called bash-utils.source.top() to
#               inspect/retrieve them.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.top() {
  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  bash-utils.stack.empty-behaviour ${context[inst]}

  case $(${context[inst]}.is-empty) in y) return ;; esac

  ${context[inst]}.peek 0
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.walk()
# Description:  Function to create a new entry on the stack - if it's not the
#               first then it also updates the current entry with the line
#               number at which the new file is 'called` before add ing the new
#               entry
# Opts:         -r  - reverse the direction of the walk i.e. tail to top,
#                     default - top to tail
# Args:         $1  - new element
# Returns:      None (atm).
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.walk() {
  local OPTARG OPTIND opt rev
  while getopts 'r' opt ; do
    case $opt in
      r)  rev=t ;;
    esac
  done

  shift $((OPTIND-1))

  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  bash-utils.stack.empty-behaviour ${context[inst]}

  case $(${context[inst]}.is-empty) in y) return ;; esac

  local -n stack=${context[inst]}

  : ${#stack[@]}
  local start=1 end=${#stack[@]} inc=1

  case "${rev:-}" in
    t)  local i ; i=$end end=$((start - 1)) ; start=$i inc=-1 ;;
  esac

  for (( i=start ; i != end ; i+=$inc )) ; do
    : $i
    printf "\n%s" "${stack[$((i-1))]}"
  done

  printf "\n"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.seek.compare-element()
# Description:  Element comparison method used as the default by
#               the bash-utils.stack.seek() method (see below) - implements a
#               simple string comparison.
#               default/given comparison function.
# Opts:         None.
# Args:         $1  - The search criteria i.e. the condition to be satisfied
#                     by elements on the returned list.
#               $2  - a stack element (as a string).
# Returns:      On STDOUT, 'y' iff the criteria is satisfied, 'n' otherwise.
# Variables:    None.
# ------------------------------------------------------------------------------
bash-utils.stack.seek.compare-element() {
  local criteria="$1" element="$2"
  local ret ; case "$criteria" in "$element") ret=y ;; esac
  builtin echo ${ret:-n}
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.seek()
# Description:  "Instance" method to seek out all stack elements satisfying the
#               default/given comparison function.
# Opts:         -c STR  - the name of an alternative comparison function,
#                         default - bash-utils.stack.seek.compare-element. The
#                         function is called with 2 args
#                         1 - a stack element as a string.
#                         2 - the search criteria (also as a string).
#                         It must return [yn] on STDOUT depending on whether the
#                         element satisfies the search criteria (as implemented
#                         in the function).
# Args:         $*      - The search criteria i.e. the condition to be satisfied
#                         by elements on the returned list.
# Returns:      An eval(1)able string which, when eval(1)led, results in an
#               array, found, containing a list of of elements each of which
#               satisfies the criteria implemented in/by the comparison
#               function.
# Variables:    <stack>
# ------------------------------------------------------------------------------
bash-utils.stack.seek() {
  local OPTARG OPTIND opt cmp=bash-utils.stack.seek.compare-element
  while getopts 'c:' opt ; do
    case $opt in
      c)  cmp=$OPTARG ;;
    esac
  done

  shift $((OPTIND-1))

  case "$(type -t $cmp)" in
    function) : ;;
    *)        bash-utils.stack.fatal-error "function not found: $cmp" ;;
  esac

  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  bash-utils.stack.empty-behaviour ${context[inst]}

  case $(${context[inst]}.is-empty) in y) return ;; esac

  local -n stack=${context[inst]}

  local el found=() ; while read el ; do
    : $el
    case "$($cmp "$*" "$el")" in n) continue ;; esac
    found+=( "$el" )
  done < <(${context[inst]}.walk)

  declare -p found
}

# ------------------------------------------------------------------------------
# Function:     source.lib-stack.load.announce.pop-attribs()
# Description:  Pops the top element(s) off the include stack - assumes that if
#               if the element(s) to be popped are of interest to the caller,
#               then the caller has already called bash-utils.source.top() to
#               inspect/retrieve them.
# Takes:        $1  - optional number of elements to pop, default - 1
# Returns:      $IncludeStack updated for the given nm & path
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.is-empty() {
  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"

  local ret ; case $(${context[inst]}.depth) in 0) ret=y ;; esac

  builtin echo ${ret:-n}
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.clone()
# Description:  Function to create a new entry on the stack - if it's not the
#               first then it also updates the current entry with the line
#               number at which the new file is 'called` before add ing the new
#               entry
# Opts:         None
# Args:         $1  - new element
# Returns:      None (atm).
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.clone() {
  case $# in 0) bash-utils.stack.fatal-error 'clone: no stack name' ;; esac

  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"
  
  bash-utils.stack.check-existence "${1:-}" y

  bash-utils.stack.new "$1"
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.new()
# Description:  Function to create a new entry on the stack - if it's not the
#               first then it also updates the current entry with the line
#               number at which the new file is 'called` before add ing the new
#               entry
# Opts:         None
# Args:         $1  - name of the new stack.
#               $*  - optional initial stack contents - one element per arg 
# Returns:      None (atm).
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.new() {
  local caller=( $(caller 0) )
  case ${caller[1]} in
    *.clone)  : ;;
    *)        eval $(bash-utils.stack.calling-context)
              bash-utils.stack.check-context "${context[context]}" "$@"

              bash-utils.stack.check-existence "$1" y
              ;;
  esac

  local name=$1 ; shift

  declare -xga $name
  local -n stack=$name
  stack+=( '' )
  
  local method ; for method in ${!Methods[@]} ; do
    case ${Methods[$method]} in class) continue ;; esac

    eval "$name.$method() { bash-utils.stack.$method \"\$@\" ; } "
  done

  # Finally, initialise the stack if appropriate
  : $#
  local e ; for e ; do $name.push "$e" ; done
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.new()
# Description:  Function to create a new entry on the stack - if it's not the
#               first then it also updates the current entry with the line
#               number at which the new file is 'called` before add ing the new
#               entry
# Opts:         None
# Args:         $1  - name of the new stack.
#               $2  - optional end of stack marker string.
# Returns:      None (atm).
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.is-equal() {
  case $# in 0) bash-utils.stack.fatal-error 'clone: no stack name' ;; esac

  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"
  
  bash-utils.stack.check-existence "${1:-}"

  # Can't be equal if they're different lengths/depths
  case $(${context[inst]}.depth) in
    $($1.depth))  case $($1.depth) in 0) ret=y ;; esac ;;
    *)            : ;;
  esac

  builtin echo ${ret:-n}
}

# ------------------------------------------------------------------------------
# Function:     bash-utils.stack.delete()
# Description:  Function to create a new entry on the stack - if it's not the
#               first then it also updates the current entry with the line
#               number at which the new file is 'called` before add ing the new
#               entry
# Opts:         None
# Args:         $1  - name of the new stack.
#               $2  - optional end of stack marker string.
# Returns:      None (atm).
# Variables:    $IncludeStack
# ------------------------------------------------------------------------------
bash-utils.stack.delete() {
  eval $(bash-utils.stack.calling-context)
  bash-utils.stack.check-context "${context[context]}" "$@"
  
  bash-utils.stack.check-existence "${1:-}"

  local inst=${context[inst]}
  unset $inst

  local method ; for method in ${!Methods[@]} ; do
    unset -f $inst.$method
  done

}

#### END OF FILE
