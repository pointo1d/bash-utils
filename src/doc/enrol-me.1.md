# enrol-me.sh(1)

A script providing the run-time (interactive) session interface to the
bash-utils library.

## SYNOPSIS

`bash enrol-me.sh`

## DESCRIPTION

This script provisions the primary interface to the bash-utils library for
(interactive) bash(1) sessions by way of generating the following to STDOUT...

- A set of environment variable definitions - see [VARIABLES](#variables) below.
- A suitably adjusted version of the callers `$PATH` variable whereby the
  adjustment comprises the appending of the `BASH_UTILS_BIN_DIR` &
  `BASH_UTILS_SBIN_DIR` to the callers `PATH`.

The above are either echoed to stdout or, optionally appended to the specified
file.

### Where
 
`-a STR`
: Specifies the file to which the definitions s/b appended (instead of stdout).


## VARIABLES

As mentioned above, the following are all echoed to STDOUT for the caller to
disposition as they see fit (typically, appending to their `.bashrc`/`.profile`
files)...

`BASH_UTILS_ROOT_DIR`, `BASH_UTILS_BIN_DIR`, `BASH_UTILS_LIB_DIR`, `BASH_UTILS_SBIN_DIR`
: These variables are calculated relative to the location of the `enrol-me.sh`
  script, listed on STDOUT and exported into the callers environment - the
  latter for immediate use as required.

`PATH`
: An adjusted value of the callers PATH (adjusted as above).

`BASH_UTILS_LIB`
: Defines the absolute location of the run-time `bash-utils.sh` library.

## NOTES

- In cases whereby the `-a` option has been employed (see [Where](#where)
  above), any existing entries matching `BASH_UTILS_.*_DIR` will be updated.

