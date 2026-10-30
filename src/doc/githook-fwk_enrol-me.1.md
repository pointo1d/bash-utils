# githook-fwk_enrol-me.sh(1)

A script providing the means to enrol the caller with the githook framework
element within this bash-utils library.

## SYNOPSIS

```
bash <path to bash-utils repo>/enrol-me.sh
bash $BASH_UTILS_LIB_DIR/githook-fwk/enrol-me.sh [-d DIR]
```

### Where
`-d DIR`
: Specifies an alternate Git repository directory (or subdirectory thereof),
  default - `$PWD`.

## DESCRIPTION

This script provides the mean to register the caller as a consumer of the git
hook(s) framework contained herein.
