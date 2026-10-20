# bash-utils

# TABLE OF CONTENTS

<!-- vim-markdown-toc GitLab -->

* [DESCRIPTION](#description)
* [NOTES](#notes)
* [TO DO](#to-do)
* [AUTHOR](#author)

<!-- vim-markdown-toc -->

# DESCRIPTION
This repo constitutes a library containing pure bash(1) implementations of
common bash coding patterns employed by the author in such a manner as to strive
to provide flexibility & reusability whilst also providing stricture e.g.
_errexit_/_nounset_, safe condition testing.  Once complete, the intention is
that the implemented patterns will include, but not necessarily be limited to,
the following (in no particular order) ...

- _Enrolment_ of the caller with local Git repository clone(s) - see [enrol-me.sh](src/doc/enrol-me.1.md) for further details

Having enrolled as above i.e. using `enrol-me.sh`, the following features are
then made available to the caller...

- [getopts[.sh]](src/doc/getopts.sh.3.md) - an enhanced option & argument
  parser.

# NOTES
* This and all other Markdown documents were written using Vim/Gvim (with the
  aid of the [vim-markdown-toc](git@github.com:mzlogin/vim-markdown-toc.git
  ) plugin) together with the preview capability provided by Firefox c/w the
  [Markdown Viewer](https://github.com/simov/markdown-viewer) add-on.
* With the exception of development &/or install-time test dependencies on
  [shellspec](https://github.com/shellspec/shellspec) & [shellcheck](https://github.com/koalaman/shellcheck) (which are both employable either as Docker
  containers or the shell i.e. bash(1) itself (via Git clones), the above
  features of this library are realised using only internal run-time
  dependencies i.e. there are no run-time dependencies external to this
  repository.

# TO DO

- Fully implement the following...
  - Traps and their manipulation.
  - Xtrace enhancement(s) - including...
    - Selective enabling &/or disabling on a file &/or function basis.
    - Auto-redirection &/or auto-logging.
  - Temporary file manipulation i.e. creation and subsequent removal.
  - A pure bash(1) stack implementation.
  - Console related routines - including, but again not limited to,...
    - Introspective help generation.
    - ANSI code abstraction.
  - Data structure examination - including (atm) ...
    - Dumping the call stack & data structures, incl., but not limited to, arrays &/or assoc. arrays.
  - Option & argument parsing incl., but not limited to the following...
    - A getopts(1) wrapper intended to avoid propagation of the traditional localization-caused copy & paste anti-pattern.
    - Named argument handling.
  - Git hook (\& webhooks) framework.
  - Basic, bash-based, test framework.
  - Log4Perl/Log4J compliant logging framework.

# AUTHOR
D.C Pointon FIAP MBCS (pointo1d at gmail.com)

END OF FILE

