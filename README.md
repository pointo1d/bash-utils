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
  - Git hooks (\& webhooks) framework.
  - basic, bash-based, test framework.

The above patterns realise only internal run-time dependancies i.e. other than bash(1) itself, there are no run-time dependencies external to this repository.

## Content
- LICENSE.txt   - As it says on the tin
- install.sh    - ditto
- README.md     - This file
- src/
  - test/       - [internal test definition](src/test/README.md)
  - main/       - _production_ code
    - ext/      - [pure bash extension library](src/main/ext/README.md)
      - bin/    - utility/tool scripts.
      - etc/    - config definition file(s) (as per POSIX).
      - lib/    - consumable pure bash bash extension code library.
    - git/      - [git hook/webhook framework](src/main/git/README.md)
    - test/     - [simple pure bash(1) test framework](src/main/test/README.md)

From the PoV of this repository, the consumer is considered to enrol with this repository and all its many benefits

# SYNOPSIS/USAGE
From a consumer PoV, this repository is considered to be consumed by _enrolment_, consequently, assuming that this repo is to be found to be installed at ```$BASH_UTILS_ROOT```, basic consumption comprises...

````
. $BASH_UTILS_ROOT/enrol-me.sh
.
.
.
.
````

# DESCRIPTION
The primary interface to this repository is provided by the ```enrol-me.sh``` script which, when dotted, provides a couple of basic core functions c/w some environment variable definitions as follows.

## Synopsis
    . $UTILS_ROOT/enrol-me.sh [FEATURE [FEATURE]]

#### Where
- ```FEATURE``` - defines a feature, in case-insensitively fashion, to which the consumer wishes to enrol. This maps on to one of the subdirectories of ```src/main``` and is, currently, one of the following...
  - ```ext``` - [pure bash(1) bash extension library](src/main/ext/README.md).
  - ```git``` - [git hook/webhook framework](src/main/git/README.md).
  - ```test``` - [simple pure bash(1) test framework](src/main/test/README.md).

#### Note(s)
- There is no default extension.

### Functions
#### ```lib.core.incl-lib()```
##### Description
A function to reduce copy \& paste when including i.e. dot'tin/source'ing, libraries/scripts

##### Synopsis
    lib.core.incl-lib [-r DIR [-r DIR]] LIB [LIB [LIB]]

##### Where
- ```-r DIR``` specifies the path for an extant additional repository root directory.
- ```LIB``` is the name of a library/script to be included, specified in one of the following forms...
  - absolute path - the full path to the library/script file is specified.
  - relative path - a relative path to the library/script file.
  - a short name - a short name i.e. basename, for the library/script file.

##### Notes
- In all cases, the path/name may, or may not, include the file extension; If not specified, then ```.sh``` is assumed.
- Subject to the aforementioned, when either the relative path or the short name form is employed, then bash(1) uses ```$PATH``` to find the file.  In such cases, ```$PATH``` is locally extended to include ...
  - The ```src/main/lib``` (or it's equivalent - if it exists) directory within the consuming repository.
  - The contents of ```$BASHUTILS_INCL_PATH``` - which can be used to define addition paths in the same way as ```$PATH``` itself.

#### ```lib.core.def-global-var()```

### Environment Variables
#### ```BASHUTILS_MAIN_DIR```

#### ```BASHUTILS_TEST_DIR```

# TO DO
* .

# AUTHOR
D.C Pointon FIAP MBCS (pointo1d at gmail.com)

    #### END OF FILE

