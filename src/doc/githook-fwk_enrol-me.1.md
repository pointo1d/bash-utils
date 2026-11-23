# githook-fwk_enrol-me.sh(1)

A script that provides the means to enrol the caller with the githook framework.

## SYNOPSIS

```
bash <path to bash-utils repo>/enrol-me.sh
bash $BASH_UTILS_LIB_DIR/githook-fwk/enrol-me.sh [-d DIR]
```

### Where

`-d DIR`
: Specifies the Git repository directory (or a subdirectory thereof), for the
  enrolling repository, default - `$PWD`.

## DESCRIPTION

This script provides the mean to enrol the caller as a consumer of the githook
framework contained herein - doing so in a manner that enables the enroller to
...

- Maintain the/any existing hooks employed by the enrolling repository.
- Call the default hook helper functions provided by this repository.

## FILES

`.githook-enrolments`
: The record of enrolments maintained as an ignored file within the root
  directory of this repository clone.
