# get-opts(3)

# DESCRIPTION

Pure bash(1) script library that, for each command line option &/or
argument allowed/expected by the calling script, provisions a means to define & 
subsequently parse from the invocation, any or all of the following pertinent
details...

- Short &/or long format option string(s) - self-evidently, N/A for arguments.
- Help texts in both short form (as reported in/by cursory usage strings) &/or
  long form (as reported in/by man(1) format help).
- An associated variable name.
- Default values.
- Legal/allowable value determination.

# SYNOPSIS

    # Load the core
    (.|source) bash-utils.sh

    # Now getopts() itself
    bash-utils.load-func getopts [-d] [-a VAR] [-o VAR]

    # ... or, load the core and getopts simultaneously
    (.|source) bash-utils.sh getopts [-d] [-a VAR] [-o VAR]

    # Initialize it as necessary - optionally providing alternate list var
    name(s) and pre-loading the default options
    getopts.init [-d] [-a VAR] [-o VAR]

    # Now use it - getopts() - define the option(s) in-line
    getopts.define-opt ...
    .
    .

    # Define the arg(s) in the order they're expected on the command line
    getopts.define-arg ...
    .
    .

    # or, use an external pseudo-JSON definition of the above
    getopts.define <JSON file>


    # Finally, parse the command line according to the previous definition - 
    # howsoever it may have been defined
    getopts.parse-cli ...

# FUNCTIONS

## getopts.init()

This is a one-shot function to record & initialize the arguments & options list
variables and optionally pre-load the default options.

### Synopsis
    
    getopts.init [-a VAR] [-o VAR]

#### Where

`-a`
: Specify an alternate name for the arguments list variable.

`-o`
: Specify an alternate name for the options list variable.

#### Returns

True (0) iff the current token was parsed successfully, 1 otherwise.

#### Environment Variables

The arguments & options variables are defined & initialized in the script
calling context

`ArgsListName`
: As it suggests on the tin, the name of the arguments list variable,
  default - `$ArgsListName`.

`OptsListName`
: As it suggests on the tin, the name of the options list variable, default -
  `$OptsListName`.

## getopts.parse-cli()

The workhorse - this function provides the means to parse the command line
according to the ruling definition - as provided by the caller using one, or
possibly more, of the following function(s).

### Synopsis
    
    getopts.parse-cli [-m] "$@"

#### Where

`-m`
: Specify mandraulic establishment of the values of command line related
  variables when the caller invokes `getopts.establish-defaults`. By default,
  the establishment of the values of variables occurs once command line parsing
  is complete.

#### Returns

True (0) iff the current token was parsed successfully, 1 otherwise.

#### Environment Variables

This function aligns with the standard `getopts`(1) builtin in its use of the
`OPTIND` variable whereby it is employed, in the callers\` context, to return
the index of the next token to be parsed from the callers argument list -
resulting in the all too commonly seen code fragment: `shift $((OPTIND - 1))`.

## getopts.establish-defaults()

This function provides the means to establish the values of variables in a
post-parsing context - this is especially useful if, as or when there are
dependencies between values given on the CLI.

### Synopsis
    
    getopts.establish-defaults

## getopts.define()

This function is provided to enable the caller to provide an external
definition in pseudo-JSON format.

### Synopsis
    
    getopts.define [-d] <DEF>

#### Where

-d
: Identifies `<DEF>` as a configuration file in pseudo-JSON format. If not
  employed, then `<DEF>` comprises an in-line definition.

DEF
: Is either an inline definition or, if `-d` is employed, the name of a file in
  pseudo-JSON format as outlined in [get-opts.json(5)](get-opts.json.5.md).

## getopts.define-opt()

The function provided to enable the caller to provide a definition of an
expected/allowable option.

### Synopsis
    
    getopts.define-opt <DEF>

#### Where

DEF
: Is the argument definition as outlined in
  [get-opts.json(5)](get-opts.json.5.md).

## getopts.define-arg()

The function provided to enable the caller to provide a definition of an
expected/allowable argument.

### Synopsis
    
    getopts.define-arg [n <NUM>] <DEF>

#### Where

-n
: Specifies the number of the argument on the command line in the same way as
  the shell refers to a positional argument i.e. as an integer in the range
  `1`..`<n>`.

DEF
: Is the argument definition as outlined in
  [get-opts.json(5)](get-opts.json.5.md).

## getopts.define-section()

The function provided to enable the caller to provide a definition of a section
to be employed by `getopts.do-man`.

### Synopsis
    
    getopts.define-section <name> <content>

#### Where

name
: The section name.

content
: The section content.

## getopts.do-help()

The function employed internally for generating the help text message in usage
format.

### Synopsis
    
    getopts.do-help

## getopts.do-man()

The function employed internally for generating the help text message in
pseudo-man(1) page format.

### Synopsis
    
    getopts.do-man [-p]

#### Where

`-p`
: Specify pagination of the output in cases whereby it (the output) would exceed
  a screen length  - by default, all of the text is displayed.

## getopts.get-entry()

Function to return an `eval`(1)able version of the given list entry -
provisioned for cases whereby a default option entry is required to be modified
e.g. the entry content is as desired with the exception of the short &/or long
names are required to be updated.

### Synopsis

    getopts.get-entry LST ID

### Where

LST
: the list from which the entry is to be found - specified as either
  `ArgsListName` or `OptsListName` or possibly one of the list variables
  indicated thereby.

ID
: the identifier for the required entry - _short_ &/or _long_ for the opts list,
  the index for the args list.


# DEFINITIONS

The above functions operate on a standard set of data definitions for the
options, arguments and to some degree, generated help text - the definitions are
as defined in [get-opts.json(5)](get-opts.json.5.md).

# NOTES

- If `getopts.init()` isn't invoked either implicitly (on the inclusion line) or
  explicitly (by the caller), then it is automagically called by the 1st
  invocation of `getopts.define-arg`, `getopts.define-opt()` or
  `getopts.define()`
  to initialize the default list variables and pre-load the default options.
- The order in which the argument definitions appear determines the order in
  which the arguments are expected on the command line and also the order in
  which the values appear in the `$ArgList` variable (should it be used).
- By default, the options for help in both usage (`-h|--help`) & man page (
  (`-m|--man`)) formats, is provided by default but, should the caller wish to
  reuse/reallocate the above options, the functions `getopts.do-help()` and
  `getopts.do-man()` (as mentioned above) are defined for that purpose, as is
  the `getopts.reallocate-entry()` utility function.

## Environment Variables

The following variables may be defined and exported by the caller in order to
specify alternate name(s) for the argument(s) &/or option(s) lists as follows...

`ArgsListName`
: Specify an alternate name for the argument(s) list, default - `ArgsList`.

`OptsListName`
: Specify an alternate name for the option(s) list, default - `OptsList`.

#### Returns

True (0) iff the declaration was successful, 1 otherwise.

# SEE ALSO

[get-opts.json(5)](get-opts.json.5.md)

# TO DO

