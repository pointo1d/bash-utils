bash-utils
==========

# TABLE OF CONTENTS


<!-- vim-markdown-toc GitLab -->

* [DESCRIPTION](#description)
* [ON-BOARDING](#on-boarding)
* [SYNOPSIS](#synopsis)
  * [Where](#where)
  * [Notes](#notes)
* [FEATURES](#features)
  * [`lib/*`](#lib)
  * [`lib/console`](#libconsole)
  * [`lib/debug`](#libdebug)
  * [`lib/enrol`](#libenrol)
  * [`lib/include`](#libinclude)
  * [`lib/narg`](#libnarg)
  * [`lib/path`](#libpath)
  * [`lib/tmp-path`](#libtmp-path)
  * [`lib/trap-handler`](#libtrap-handler)
  * [`lib/xtrace`](#libxtrace)
* [TO DO](#to-do)
* [NOTES](#notes-1)
* [AUTHOR](#author)

<!-- vim-markdown-toc -->

# DESCRIPTION
This repo constitutes a library containing, as near as humanly possible, pure bash(1) implementations of common bash coding patterns in such a manner as to strive to provide flexibility & reusability whilst also providing stricture e.g. _errexit_/_nounset_, safe condition testing.  Once complete, the intention is that the implemented patterns will include, but not necessarily be limited to, the following (in no particular order) ...

- _Enrols_ the caller with VCS (initially Git) repository/repositories, including the...
  - Creation of a global associative array variable containing values specific to the enrolment.
  - Auto-updating of PATH to include the bin & lib directories in the enrolled repository.
- File inclusion - overriding the `.` & `source` builtin commands to ...
  - Avoid recursive file inclusion.
  - Implement conditional file inclusion i.e. don't blow up if targetted file(s) doesn't exist.
  - Allow multiple file inclusion in one one line (thereby providing another means to tidy up code).
- Traps and their manipulation.
- Xtrace enhancement(s) - including...
  - Selective enabling &/or disabling on a file &/or function basis.
  - Auto-redirection &/or auto-logging.
- Temporary file manipulation i.e. creation and subsequent removal.
- Console related routines - including, but again not limited to,...
  - Introspective help generation.
  - ANSI code abstraction.
- Data structure examination - including (atm) ...
  - Dumping the call stack & data structures, incl., but not limited to, arrays &/or assoc. arrays.
- Option & argument parsing incl., but not limited to the following...
  - A getopts(1) wrapper intended to avoid propagation of the traditional localization-caused copy & paste anti-pattern.
  - Named argument handling.
- Git hooks (\& webhooks) framework.
- Basic, bash-based, test framework.
- Log4Perl/Log4J compliant logging framework.

With the exception of development &/or install-time test dependencies on [shellspec](https://github.com/shellspec/shellspec) & [shellcheck](https://github.com/koalaman/shellcheck) (which can both be employed as Docker containers) and the shell i.e. bash(1) itself, the above are realised using only internal run-time dependencies i.e. there are no run-time dependencies external to this repository.

# ON-BOARDING
There are no onboarding specific pre-requisite(s) or procedure(s) other than cloning this repository.  From a consumer PoV, this repository is considered to be consumed by _enrolment_, therefore enrolment (assuming that this repo has been cloned to `<BASH_UTILS_ROOT>`), is merely a case of running a simple command in the consuming script  (or, indeed, the users interactive session :-) - see [SYNOPSIS](#synopsis)).

# SYNOPSIS
The primary interface to this repository is provided by the `enrol-me.sh` script in the repository root directory, which, when dotted (or indeed `source`ed :-)), provides the basic core enrolment features (see [Notes](#notes))...

    . $UTILS_ROOT/enrol-me.sh [FEATURE [FEATURE ...]]

## Where
- `FEATURE` - defines a feature, in case-insensitive fashion, to which the consumer may wish to enrol. This is, currently, one, or more, of the following...
  - [`lib`](#lib) - pure bash(1) bash extension library (alternatively, in its entirety, `lib/*`).
    - [`lib/console`](#libconsole) - console I/O related tools & utils.
    - [`lib/debug`](#libdebug) - data & stack trace dumping/eaxmanination related tools & utils.
    - [`lib/repo-enrol`](#libenrol) - general purpose repository enrolment routine.
    - [`lib/narg`](#libnarg) - function named argument routine.
    - [`lib/path`](#libpath) - general path related tools & utils.
    - [`lib/include`](#libinclude) - file inclusion routines including conditional & non-recursive file inclusion prevention routines.
    - [`lib/tmppath`](#libtmp-path) - temporary file manipulation & maintenance tools & utils.
    - [`lib/trap`](#libtrap-handler) - trap(1) manipulation & maintenance tools & utils.
    - [`lib/xtrace`](#libxtrace) - xtrace manipulation & maintenance tools & utils.
  - [`git`](src/main/git/README.md) - git hook/webhook framework.
  - [`cuba`](src/main/cuba/README.md) - prototype test framework implementing the [Cucumber](https://cucumber.io) language in pure bash(1) and utilising, not entirley unsurprisingly :-), the aforementioned library routines.
  - [`test`](src/main/test/README.md) - simple pure bash(1) test framework.

## Notes
  - The consumer is auto-enrolled to the  `lib/enrol`, `lib/sincl` & `lib/pathvar`. features.
  - Since the consumer enrols features using the `lib/sinclude` library...
    - Multiple/recursive inclusion is prevented i.e. the consumer will only ever be enrolled once for any feature.
    - The users PATH environment variable is temporarily extende to include this reporistory ... and optionally further extended to add in paths containing files specific to the consumer.

# FEATURES
## `lib/*`
  This i.e. `lib/*`, is the means by which enrollment to all available features within the library i.e. not including the frameworks mentioned above, is acheived.

## `lib/console`

## `lib/debug`

## `lib/enrol`

## `lib/include`

## `lib/narg`

## `lib/path`

## `lib/tmp-path`

## `lib/trap-handler`

## `lib/xtrace`

# TO DO
* Complete the shellspec unit tests for existing fetaures.
* Complete the intended feature set c/w associated unit tests.
* Finish off introspective README extension.

# NOTES
* This and all other Markdown documents were written using Vim/Gvim (with the aid of the [vim-markdown-toc](git@github.com:mzlogin/vim-markdown-toc.git) plugin) together with the preview capability provided by Firefox c/w the [Markdown Viewer](https://github.com/simov/markdown-viewer) add-on.

# AUTHOR
D.C Pointon FIAP MBCS (pointo1d at gmail.com)


END OF FILE
