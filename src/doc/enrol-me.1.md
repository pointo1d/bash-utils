# enrol-ms.sh(1)

A script to provide the interface to the bash-utils library.

# SYNOPSIS
    (|.source] enrol-me.sh [[PREFIX]:[VAR_PREFIX]:[DIR]...]

# WHERE

`PREFIX`
: Defines a prefix with which the caller specifies their own libraries (for use
  when the caller has a library script whose filename clashes with one of thoee
  provisioned wherein.

`VAR_PREFIX`
: Defines a prefix for the auto-generated variable names.

`DIR`
: Defines root directory to be employed as the root directory.

For details of both of the above, see [ENVIRONMENT VARIABLES](#environment-variables) (below).

# DESCRIPTION

This script provisions the primary interface to the bash-utils library ... as an
integral part of which is an addition by way of overriding functions for the
builtin bash(1) `source` and `.` functions whereby the overrides also provide
for the following enhanced functional features...

- Recursive file inclusion avoidance measures - by both...
  - Readonly macro (environment variable definition) and...
  - Pre-inclusion inspection of the _bash_(1) `$BASH_SOURCE` associative array.
- Ease of access to consumer binary and library directories in addition to this
  suite of library scripts.
- Selective reporting of library script inclusion. 

# FUNCTIONS

As with the builtins themselves, the 2 functions provisioned herein are
synonyms.

## .(), source()

### Synopsis

    (source|.) LIB [LIB...]

### Where

LIB
: is a library script to be included - which is typically of the form of a
file base name (with, or without the extension/postfix) library and may, or may
not, be prepended with the caller supplied `PREFIX` (the only mandatory use is
in circumstances whereby the prefix is needed to disambiguate between file base
names.

### Variables

`BASH_UTILS_INCLUDE_VERBOSE`
: Define the verbosity level of the reporting of file inclusions.

# ENVIRONMENT VARIABLES

`BASH_UTILS_ROOT_DIR`, `BASH_UTILS_BIN_DIR` `BASH_UTILS_LIB_DIR` `BASH_UTILS_SBIN_DIR`
: These variables are calculated relative to the location of the `enrol-me.sh`
script and recorded and exported into the callers environment; additionally, the
non-`LIB` paths conveyed are appended to the callers `$PATH` variable.

In addition, for each pair of `PREFIX` and `DIR` arguments provided by the
caller, similar is true i.e. the variables are calculated relative to the given
`DIR` and recorded and exported into the callers environment; additionally, the
non-`LIB` paths conveyed are appended to the callers `$PATH` variable.

