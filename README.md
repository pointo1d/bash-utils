bash-utils
==========

# DESCRIPTION
This repo is a library containing as near as humanly possible, pure bash(1) implementations of common bash coding patterns in a manner that strives to be stricture e.g. _errexit_/_nounset_, safe condition testing ... including, but not necessarily limited to, the following ...

- traps and their manipulation.
- xtrace enhancement(s) - including...
  - selective enabling &/or disabling on a file &/or function basis.
  - auto-logging.
- temporary file manipulation i.e. creation and subsequent removal.
- common console related routines - including introspective help generation.
- dumping the call stack.
- _enrolment_ (of the caller) with VCS (initially Git) repository/repositories.
- option parsing incl., but not limited to the following...
  - a getopts(1) wrapper intended to avoid propagation of the copy & paste anti-pattern.
  - named argument handling.

The above patterns realise only internal run-time dependancies i.e. other than bash(1) itself, there are no run-time dependencies external to this repository.

## Content
```
  LICENSE.txt           - As it says on the tin
  install.sh            - ditto
  README.md             - This file
  src/
    test/
      lib/              - internal test libraries
      scripts/          - internal test definition scripts
        unit/           - dynamic i.e. functional, test scripts
        features/       - expectation definition(s) aka feature file(s)
          support/      - support directory .... a la standard Cucumber
        static/         - static i.e. non-functional, test scripts
    main/               - production code
      etc/              - config definition file(s) (as per POSIX)
      lib/              - internal library code
```

# SYNOPSIS
Assuming that this repo is to be found to be installed at ```$UTILS_ROOT```, the following applies...

## Bespoke script
### Preparation
Within the consuming script e.g. ```test.sh```...

```
# Load capability access
. $UTILS_ROOT/bash-utils.sh

# Load individual capabilities - using the loader provisioned by the utilities
# loader automagically loaded above
bash-utils.file-loader tempfile xtrace traps

#### END OF FILE
```

# INSTALLATION
Install by using ```./INSTALL.sh``` (specifying an installation root directory as an alternative to ```/usr/local/```)...

    $ [PREFIX=dir] [bash] ./INSTALL.sh 


# TO DO
* .

# AUTHOR
D.C Pointon FIAP MBCS (pointo1d at gmail.com)
