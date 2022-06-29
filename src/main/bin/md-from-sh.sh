#! /usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         md-from-sh.sh
# Synopsis:     [bash] md-from-sh.sh FILE
# Description:  This is a pure bash(1) script to generate markdown from a well
#               defined & understood format of the accompanying shell script
#               comments.
# Opts:         -n  - some short opt
#               --opt  - some long opt
# Args:         $1  - the name of a file for which to  generate the markdown.
# Notes:        This script is predicated on target bash files following
#               pre-determined formatted comment _block_s where each block
#               comprises one, or more, _section_s - each section matching
#               `# <keyword/title>:+(\ )[<string>]` -
#               `<string>` is here defined as a string that may, or may not, be
#               continued over multiple lines where the continuation lines all
#               use the prefix `# <keyword/title>:\ `.
#               The minimum prefix for empty continuation lines must match `# `
#               i.e. a hash (`#`) + at least one trailing space character
# 
#               Blocks are terminated by one of the following...
#               - a line matching `####+(#)` i.e. for, or more, consecutive hash
#                 (`#`) characters.
#               - any line whose first 2 characters are not `# \ `
#               - a function declaration - denoting the end of a function block.
# 
#               The format is via comments observing the RE
#               '# ' ' ' keyword ':' string. The following comprise the
#               designated/recognized keywords c/w a brief description of their
#               purpose::
#               - File        - specifies the title of the generated page.
#               - Description - identifies descriptive narrative for either the
#                               file (as a script) or function(s) therein.
#               - Author      - Identifies the author
#               - Date        - ... and the date the file was created
#               - Opts        - identify the/any options - short &/or long
#               - Args        - identify the/any arguments 
#               - Variables   - identify any global variables consumed by the
#                               script
#               - To Do       - a descriptive narrative describing any forecast
#                               changes
#               - Notes       - supplementary notes
#               - `[-*] `     - signifies a simple list entry
#               - `$VAR`      - signifies an entry in an `Env Vars` list.
#               - empty line  - any line matching `# +` signifies a new
#                               paragraph unless it's at the end of a list - of
#                               which it marks the end.
# 
#               In lists...
#               - Any text at, or greater than, the indent of the list start
#                 _keyword_ (see above) is treated as a continuation of the
#                 current/previous list text.
# 
#               The ordering of the headings within the generated _MarkDown_ is
#               determined by the `` variable i.e. it's completely independant
#               of the order in which the headings are defined in the script
# 
#               Everything other than function definitions are expected in the
#               header block - the end of which is define by a line matching
#               `#####+`.
# To Do:        None.
# Files:        etc/md-from-sh.sh
# ------------------------------------------------------------------------------
# Author:       D. C. Pointon FIAP MBCS (pointo1d at gmail dot com)
# Date:         June 2022
################################################################################

declare shopt="$(shopt -op xtrace)"
shopt -ou xtrace
shopt -os errexit
shopt -s extglob
. ${BASH_SOURCE//bin/etc}

# File global(s)
declare File=() LineNo=0 LastLineNo=116 CurrSect Eof InList Fname="${1:-}" 
declare -A Block=() Content=() FuncDef=()

# ------------------------------------------------------------------------------
# Function:     md.generate._do-funcdef()
# Description:  A function to converted the given line to a list entry as
#               appropriate
# Synopsis:     one-liner-func "LINE"
# Opts:         None
# Args:         $1  - the line to process
# Returns:      On STDOUT - the given line converted as appropriate
# Env Vars:     None
# Notes:        None
# ------------------------------------------------------------------------------
md.generate._do-funcdef() {
  local title prefix='###'
  for title in "${FuncHeadings[@]}" ; do
    local keywd=${Sections["$title"]}
    case ${Block[$keywd]:-n} in n) continue ;; esac
    case $keywd in
      function) printf "\n---\n%s()\n\n" "$prefix ${Block[$keywd]}" ;;
      synopsis) printf "\n%s\n\n" "$prefix# $title"
                printf "    %s\n\n" "${Block[$keywd]}"
                ;;

      *)        printf "%s\n\n%s\n\n" "$prefix# $title" "${Block[$keywd]}" ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Function:     md.generate._do-content()
# Description:  A function to converted the given line to a list entry as
#               appropriate
# Synopsis:     one-liner-func "LINE"
# Opts:         None
# Args:         $1  - the line to process
# Returns:      On STDOUT - the given line converted as appropriate
# Env Vars:     None
# Notes:        None
# ------------------------------------------------------------------------------
md.generate._do-content() {
  local title prefix='#'
  for title in "${ContentOrder[@]}" ; do
    local keywd=${Sections["$title"]}
    case ${Content[$keywd]:-n} in n) continue ;; esac
    case $keywd in
      title)      printf "%s\n" "$prefix ${Content[$keywd]}" ;;
      functions)  printf "\n---\n$prefix# Functions\n\n%s" "${Content[$keywd]}"
                  ;;
      synopsis)   printf "\n---\n"
                  printf "\n%s\n\n" "$prefix# $title"
                  printf "    %s\n\n" "${Content[$keywd]}"
                  ;;
      *)          printf "\n---\n"
                  printf "\n%s\n\n" "$prefix# $title"
                  printf "%s\n\n" "${Content[$keywd]}"
                  ;;
    esac
  done

  printf "\n\n---\nEND OF DOCUMENT\n"
}

# ------------------------------------------------------------------------------
# Function:     md._generate()
# Description:  A function to generate the markdown using the given header
#               orderings structure where the content is taken from the
#               structure as follows: 
#               * FuncHeadings  - Block
#               * ContentOrder  - Content
# Synopsis:
#   md._generate [HDRS]
# Opts:         None.
# Args:         $1  - optional headers struct name, default - FuncHeadings
# Returns:      the generated content on STDOUT.
# Env Vars:     None
# Notes:        None
# ------------------------------------------------------------------------------
md._generate() {
  local hdrs=${1:-FuncHeadings} # prefix funcdef

  case ${1:-FuncHeadings} in
    ContentOrder) md.generate._do-content ;;
    FuncHeadings) md.generate._do-funcdef ;;
  esac
}

# ------------------------------------------------------------------------------
# Function:     file._eof() {
# Description:  
# Opts:         None.
# Args:         $1  - the line to be adjudged.
# Returns:      't' on STDDOUT iff the line is of interest, 'n' otherwise.
# Vars:         None.
# Notes:        None.
# ------------------------------------------------------------------------------
file._eof() {
  case $((LineNo - ${1:-${#File[@]}})) in -*|0) return 1 ;; *) return 0 ;; esac
}

# ------------------------------------------------------------------------------
# Function:     line._is-interesting() {
# Description:  
# Opts:         None.
# Args:         $1  - the line to be adjudged.
# Returns:      't' on STDDOUT iff the line is of interest, 'n' otherwise.
# Vars:         None.
# Notes:        None.
# ------------------------------------------------------------------------------
file._readline() {
  case "$(file._eof)" in y) return ;; esac

  Line="${File[$LineNo]}"
  : $((LineNo+=1))
}

# ------------------------------------------------------------------------------
# Function:     line._get-type() {
# Description:  
# Opts:         None.
# Args:         $1  - the line to be adjudged.
# Returns:      't' on STDDOUT iff the line is of interest, 'n' otherwise.
# Vars:         None.
# Notes:        None.
# ------------------------------------------------------------------------------
line._get-type() {
  local line="$1" type

  case "$Line" in
    \#+([[:space:]]))
        type=empty ;;
    [[:alnum:]]+([[:alnum:]]|_|-)*(\.[[:alnum:]]+([[:alnum:]]|_|-))\(\)*)
        type=func
        ;;
    \#[[:space:]][A-Z]+([[:alnum:]]|[[:space:]]):*)
        type=sect
        ;;
    \#[[:space:]]+([[:space:]])*)
        case ${CurrSect:-n} in
          n)  type=ign ;;
          *)  type=doc ;;
        esac
        ;;
    \#[[:space:]]+(-|\#))
        type=docsep
        ;;
    *)  type=ign
        ;;
  esac

  builtin echo ${type:-n}
}

# ------------------------------------------------------------------------------
# Function:     line._is-interesting() {
# Description:  
# Opts:         None.
# Args:         $1  - the line to be adjudged.
# Returns:      't' on STDDOUT iff the line is of interest, 'n' otherwise.
# Vars:         None.
# Notes:        None.
# ------------------------------------------------------------------------------
line.doc._do-line() {
  local line="$1" no_sp="${1##*([[:space:]])}" ; local char_1=${no_sp:0:1}

  case $char_1 in
    \*|\$)  # Opt list or env var list, get the indent
            Indent=${line/$char_1*/}
            Indent=${#Indent}
            line="- $no_sp"
            InList=t
            ;;
    -)      # MD list char, but is it in list, or possibly, opt context
            case "$no_sp" in
              -\ *) # list context
                    ;;
              *)    local opt="${no_sp//-}"
                    case "${opt:-n}" in
                      n)  return ;;
                      -*) no_sp="- $no_sp" ;;
                    esac
                    ;;
            esac

            : ${InList:-n}
            line="
$no_sp"
            InList=t
            ;;
    *)      # Not a list line
            line="$no_sp "
            ;;
  esac

  Block[$CurrSect]+="$line"
}

# ------------------------------------------------------------------------------
# Function:     line._is-interesting() {
# Description:  
# Opts:         None.
# Args:         $1  - the line to be adjudged.
# Returns:      't' on STDDOUT iff the line is of interest, 'n' otherwise.
# Vars:         None.
# Notes:        None.
# ------------------------------------------------------------------------------
block._do-end() {
  # Return early if there's nowt to do i.e. Block is currently empty
  case ${#Block[@]} in 0) return ;; esac

  case ${Block[function]:-n} in
    n)  # Not a function block
        headings=ContentOrder

        # Update the content with the current block details
        local h ; for h in "${ContentOrder[@]}" ; do
          local k="${Sections[$h]}"
          : $h - $k
          case "${Block[$k]:-n}" in n) continue ;; esac

          Content[$k]="${Block[$k]}"
        done
        ;;
    *)  # Function block
        case ${Block[function]} in
          _*|*._*)  ;;
          *)        Content[functions]+="$(md._generate)

"
                    ;;
        esac
        ;;
  esac

  # And reset the current section and block
  unset CurrSect ; Block=()
}

# ------------------------------------------------------------------------------
# Function:     line.doc._do-funcdef()
# Description:  
# Opts:         None.
# Args:         $1  - the line to be adjudged.
# Returns:      't' on STDDOUT iff the line is of interest, 'n' otherwise.
# Vars:         None.
# Notes:        None.
# ------------------------------------------------------------------------------
line.doc._do-funcdef() {
  # Nothing to do other than reset the Block if it's a private function
  case $1 in _*|*._*)  Block=() ; return ;; esac

  # Otherwise, record the function name
  Block[function]=$1
  
  # And finish off the block
  block._do-end
}

line.doc._do-empty() {
  Block[$CurrSect]+='

'
}

line.doc._do-sect() {
  local line="$1" no_sp="${1##\#[[:space:]]}" hdr="${1%%:*}"
  local keywd="${hdr// /_}" ; keywd=${keywd,,}

  # Attempt to validate the new section header
  : ${!Sections[@]}
  case ${Sections["$hdr"]:-n} in
    n)  # Not found, so it's merely a straightforward doc line
        ;;
    *)  # Otherwise, it's known about, so 1st attempt to detect & warn about
        # repeated section header 
        case "${!Content[@]}${!Block[@]}" in
          *$keywd*) _warn "Repeated section header: $hdr" ;;
        esac

        # Now update the section header tracker
        CurrSect=$keywd

        # Initialize the section in the block
        Block[$keywd]=""

        # Before attempting to process the rest of the line ... after 1st
        # replacing the header with spaces (JIC it's the 1st entry in a list)
        local sp_hdr="${hdr//?/ }"
        line.doc._do-line "${line/$hdr:/$sp_hdr }"

        ;;
  esac
}

_2StdErr() { builtin echo "$*" >&2 ; }

_warn() { _2StdErr "WARN!! $* - line $LineNo" ; }

_fatal() { _2StdErr "FATAL!! $* - line $LineNo" ; exit 1 ; }

################################################################################
#
#                          MAIN BODY
#
################################################################################
mapfile -t File < "${Fname:-/dev/stdin}"

eval $shopt

# Attempt to read the first line
file._readline

# And now progress thro' the file
until $(file._eof ${LastLineNo:-}) ; do
  declare cond=${CurrSect:-}:::$(line._get-type "$Line") NoPrefix="${Line##\# }"

  case $cond in
    *:::ign)    # Not interesting, so end block if appropriate
                block._do-end
                ;;
    *:::sect)   line.doc._do-sect "$NoPrefix" ;;
    *:::empty)  line.doc._do-empty ;;
    *:::docsep) ;;
    *:::func)   line.doc._do-funcdef ${Line%%()*} ;;
    :::doc)     _fatal "doc line with no previous section" ;;
    *:::doc)    line.doc._do-line "${Line##\# }" ;;
  esac

  file._readline

done

block._do-end

# All done, so now it's time to print the results - start with the page title
md._generate ContentOrder

#### END OF FILE
