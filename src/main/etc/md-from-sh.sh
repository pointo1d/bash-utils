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
readonly declare KeyWords=(
  File Synopsis Description Opts Args Returns Variables Notes
  'To Do' Author Date Copyright
)

# Section specific keyword orderings
readonly declare CommonHeadings=(
  Synopsis Description Opts Args Returns
)
readonly declare \
  FuncDefHeadings=( Function ${CommonHeadings[@]} 'Env Vars' 'To Do' Notes ) \
  ContentOrder=(
    ${CommonHeadings[@]}
    Functions
    Variables
    Notes
    'To Do'
    Author
    Date
    Copyright
  )

#### END OF FILE
