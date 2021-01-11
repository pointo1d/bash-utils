bash-utils
==========

# DESCRIPTION
This repo is a bash(1) library containing a few stand-alone utilities to fill gaps in core bash(1) functionality - gaps including, but not limited to, capabilities related to the following ...

* traps and their manipulation.
* xtrace enhancement(s) - including selective enabling &/or disabling on a file &/or function basis.
* temporary file creation and subsequent removal.
* errexit-safe path testing.
* common console related routines - including introspective help generation.
* dumping the call stack.

The above enhanced/improved capabilities realise only internal dependancies i.e. other than bash(1) itself, there are no dependencies external to this repository.

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
