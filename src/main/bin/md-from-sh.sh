#! /usr/bin/env bash
# vim: et ai sw=2 sts=2
################################################################################
# File:         md-from-sh.sh
# Description:  This is a pure bash(1) script to generate markdown from well
#               formed & understood format of the accompanying scheel scripts.
# Notes:        None
# ------------------------------------------------------------------------------
# Author:       D. C. Pointon FIAP MBCS
# Date:         May 2022
################################################################################
declare md=() sects=(header body)
declare \
  PageHeadings=(
    Synopsis Description Variables
  ) \
  PageTrailings=(
    To_Do Author Date Copyright
  ) \
  FuncHeadings=(
    Function Synopsis Description Opts Args Returns Variables Notes
  )

declare fname ; for fname ; do
  declare -A header trailer funcdef ; declare curr_sect=0 sect_nm=header

  shopt -s extglob
  declare line ; while read line ; do
    declare _line="${line##\#+([[:space:]])}"
    declare -n sect=$sect_nm

    case "${line:-n}" in
      \#!*|\
      \#\ vim*|\
      \#\#\#*|\
      \#\ ------*)        continue ;;
      \#\ [A-Z][a-z]*:*)  # New heading, so do it
                          curr="${_line%%:*}"
                          declare _curr="${_line##$curr:+([[:space:]])}"
                          sect[$curr]="$_curr"
                          ;;
      \#\ *)              sect[$curr]="${sect[$curr]} $_line" ;;
      *\(\)\ {)           sect[Function]=${line// \{}
                          case "$_line" in *.__*)  sect=() ; continue ;; esac
                          case "${md[*]}" in
                            *Functions*)  : ;;
                            *)            md+=( "## Functions" )
                                          ;;
                          esac

                          declare hdg ; for hdg in ${FuncHeadings[@]} ; do
                            : $hdg
                            case "${funcdef[$hdg]:-n}" in
                              n|\
                              None*)  continue ;;
                            esac

                            declare line='###'
                            case $hdg in
                              Function)
                                md+=( "$line ${funcdef[$hdg]}" )
                                ;;
                              Args)
                                md+=(
                                  "#$line $hdg"
                                  "$(echo -e "${funcdef[$hdg]//\$/\\n- $}" )"
                                  ""
                                )
                                ;;
                              Opts)
                                md+=(
                                  "#$line $hdg"
                                  "$(echo -e "${funcdef[$hdg]/-/\\n* -}" )"
                                ) ;;
                              *)
                                md+=( "#$line $hdg" )
                                line=${funcdef[$hdg]//</\<}""
                                line=${line//>/\>}""
                                md+=( "$line" )
                                ;;
                            esac

                            md+=( "" )
                            
                          done
                          #break
                          ;;
      n)                  sect_nm=funcdef ;;
    esac
  done < $fname

  declare sect_name ; for sect_name in PageHeadings PageTrailings ; do
    declare -n sect=$sect_name ; declare hdg ; for hdg in ${sect[@]} ; do
      : $sect_name, $hdg
      case "${header[$hdg]:-n}" in n) continue ;; esac
      line=( "## $hdg" "${header[$hdg]}" )

      case $sect_name in
        PageHeadings)   md=( "${line[@]}" "${md[@]}" ) ;;
        PageTrailings)  md=( "${md[@]}" "${line[@]}" ) ;;
      esac
    done
  done

  printf "%s\n" "# ${header[File]}" "${md[@]}"
done

#### END OF FILE
