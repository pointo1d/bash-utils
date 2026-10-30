#!/usr/bin/env bash
# vim: ai et fo+=r sw=2 sts=2
################################################################################
# File:         enrol-me.sh
# Description:  Pure bash(1) script to enrol the caller with the bash-utils
#               library at one of the following 2 levels:
#               - User (to set up their environment - for easier access to
#                 the libraries provisioned herein).
#               - Shell script (to set up the environment and also provide
#                 recursive inclusion avoidance routines overriding the builtin
#                 `.` and `source` function).
# Docs:         [README.md](README.md), [enrol-me.sh](src/doc/enrol-me.sh).
###############################################O################################
# shellcheck disable=SC2086
eval ${GITHOOK_FWK_ENROL_ME_SH:-}
declare -grx GITHOOK_FWK_ENROL_ME_SH=return

################################################################################
################################################################################
########                         MAIN BODY                              ########
################################################################################
################################################################################
declare OPTARG OPTIND opt RepoDir="$PWD"
while getopts ':d:' opt; do
  case $opt in
    d)  RepoDir="$OPTARG" ;;
    *)  builtin echo "FATAL: Unknown option: '$OPTARG'" >&2
        exit 1
        ;;
  esac
done

shift $((OPTIND - 1))

if ! test -d "$RepoDir"; then
  builtin echo -e "FATAL: Directory not found: '$RepoDir'" >&2
  exit 1
fi

# shellcheck disable=SC2155,SC2164
declare RepoRoot="$(cd "$RepoDir"; git rev-parse --show-toplevel 2>/dev/null)"

if test ${#RepoRoot} -eq 0; then
  builtin echo -e "FATAL: Not a Git repository: '$RepoDir'" >&2
  exit 1
fi

# shellcheck disable=SC2155,SC2164
declare AbsPath=$(cd ${BASH_SOURCE%/*} >&/dev/null; pwd)

# shellcheck disable=SC2086
git -C "$RepoDir" config core.hooksPath "$AbsPath/hooks"

#### END OF FILE
