#! /usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         md-from-sh.sh
# Synopsis:
#   [bash] md-from-sh.sh FILE
# Description:  This is a pure bash(1) script to generate markdown from well
#               formed & understood format of the accompanying shell scripts.
# Opts:         --opt  - some opt
# Args:         $1  - the name of a file for which to  generate the markdown.
# Notes:        The format is via comments observing the RE
#               '# ' ' ' keyword ':' string. The following comprise the
#               designated/recognized keywords c/w a brief description of their
#               purpose::
#               - File        - specifies the title of the generated page.
#               - Description - identifies descriptive narrative for either the
#                               file (as a script) or function(s) therein.
#               - Author      - Identifies the author
#               - Date        - ... and the date the file was created
#               - Opts        - identify the/any options
#               - Args        - identify the/any arguments 
#               - Variables   - identify any global variables consumed by the
#                               script
#               - To Do       - a descriptive narrative describing any forecast
#                               changes
#               - Notes       - supplementary notes
# To Do:        None.
# ------------------------------------------------------------------------------
# Author:       D. C. Pointon FIAP MBCS
# Date:         May 2022
################################################################################
set -e
. ${BASH_SOURCE//bin/etc}

# Description:  A decsrikption
# on multiple
# lines
# Synopsis:
#   some-func a b c
# Opts:         -a  - dsalkjhbzlkdfgha
# Args:         $1  - dsalkjhbzlkdfgha
#               $2  - dsalkjhbzlkdfgha
#               $3  - dsalkjhbzlkdfgha
#
# Returns:      summat
# Env Vars:     $fred
# Notes:        - asdfasdf
#               - dsfasdf
some-func() {
  :
}

# Description:  A func defined on a single line but
# described
# on multiple
# lines
# Synopsis:
#   single-line-func
# Opts:         None
# Args:         None
# Returns:      a value
# Env Vars:     None
# Notes:        -None
single-line-func() { : ; }

# ------------------------------------------------------------------------------
# Description:  A function to converted the given line to a list entry as
#               appropriate
# Synopsis:
#   __process-opt-line "LINE"
# Opts:         None
# Args:         $1  - the line to process
# Returns:      On STDOUT - the given line converted as appropriate
# Env Vars:     None
# Notes:        None
# ------------------------------------------------------------------------------
__process-opt-line() {
  case "${*:-n}" in
    n)    : ;;
    \$*)  echo -e "${*/\$/\\n- \$}" ;;
    -*)   echo -e "${*/-/\\n* -}" ;;
    *)    echo -e "$*" ;;
  esac
}

shopt -s extglob

declare fname ; for fname ; do
  declare -A body funcdef ; declare sect_nm=body

  declare line ; while read line ; do
    declare _line="${line##\#+([[:space:]])}"
    declare -n sect=$sect_nm

    case "${line:-n}" in
      \#!*|\
      \#\ vim*|\
      \#\#\#*|\
      \#\ ------*)
        continue
        ;;
      \#\ [A-Z][a-z]*:*)
        # New heading, so start by extracting & saving it
        declare keywd="${_line%%:*}"

        # Now attempt to validate it
        case "${KeyWords[*]}" in *"$keywd"*) : ;; *) continue ;; esac

        case "${_line//$keywd:*([[:space:]])}" in none*|None*) continue ;; esac

        # Now save same line content (if any)
        sect["$keywd"]="$(__process-opt-line "${_line//$keywd:*([[:space:]])}")"
        ;;
      \#\ *)
        _line="$(__process-opt-line "$_line")"

        sect["$keywd"]="${sect["$keywd"]} $_line"
        ;;
      *\(\)\ {*)
        # Its a function declaration aka end of funcdef
        # 1st, complete the current funcdef - by adding the
        # function name - and add it to the body i.e. funcdefs
        case "${line// *}" in
          _*|\
          *._*) : ;;
          *)  funcdef[Function]=${line// *}
                              
              declare hdg ; for hdg in ${FuncDefHeadings[@]} ; do
                case "${funcdef["$hdg"]:-n}" in n) continue ;; esac

                case "$hdg" in
                  Function) body[Functions]="${body[Functions]}
                            $(echo -e "\n## ${funcdef["$hdg"]}")"
                            ;;
                  Synopsis) body[Functions]="${body[Functions]}
                            $(echo -e "\n### $hdg\n    ${funcdef["$hdg"]}")"
                            ;;
                  *)        body[Functions]="${body[Functions]}
                            $(echo -e "\n### $hdg\n${funcdef["$hdg"]}")"
                            ;;
                esac
              done
              ;;
        esac

        # Now, set-up for the next one
        funcdef=()
        ;;
      n)  
        # It's an empty space, so everything, if anything,
        # hereafter is/are funcdef(s)
        sect_nm=funcdef
        ;;
    esac
  done < $fname

  # All done, so now it's time to print the results - start with the page title
  printf "%s\n" "# ${body[File]}"

  # Now the body content as
  declare i sect_nm ; for i in "${!ContentOrder[@]}" ; do
    sect_nm="${ContentOrder[$i]}"
    # Avoid empty sections
    case "${body["$sect_nm"]:-n}" in n) continue ;; esac

    # But print non-empty ones
    case "$sect_nm" in
      Synopsis) printf "\n%s\n" "# $sect_nm" "    ${body["$sect_nm"]}" ;;
      *)        printf "\n%s\n" "# $sect_nm" "${body["$sect_nm"]}" ;;
    esac
  done
done

#### END OF FILE
