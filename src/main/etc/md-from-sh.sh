#! /usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         md-from-sh.sh
# Synopsis:
#   . md-from-sh.sh
# Description:  This is the config file for the eponymously named script in the
#               bin directory - defining, as it does, the expected/permissible
#               content of the generated page header, trailer & per-function
#               blocks c/w their ordering i.e. the ordering of the headers
#               within the respective blocks..
# Opts:         None
# Args:         None
# Notes:        None
# ------------------------------------------------------------------------------
# Author:       D. C. Pointon FIAP MBCS
# Date:         May 2022
################################################################################

# Allowed/recognized keywords
# Section specific keyword orderings
readonly declare \
CommonHeadings=( Synopsis Description Opts Args Returns ) \
CommonTrailings=( 'Env Vars' 'Doc Links' Notes Files 'To Do' )

readonly declare \
  FuncHeadings=( Function ${CommonHeadings[@]} ${CommonTrailings[@]} ) \
  ContentOrder=(
    Title
    "${CommonHeadings[@]}"
    Functions
    "${CommonTrailings[@]}"
    Author
    Date
    'License & Copyright'
    License
    Copyright
  )

declare -A Sections=() HeaderEquivs=( [file]=title )
readonly declare AllHeaders=(
  "${ContentOrder[@]}" "${FuncHeadings[@]}" "${HeaderDerivations[@]}"
)

declare section ; while read section ; do
  case "${Sections[*]}" in *"$section"*) continue ;; esac
  declare kwd=${section,,} ; Sections["$section"]=${kwd// /_}
done < <(printf "%s\n" "${AllHeaders[@]}")

#### END OF FILE
