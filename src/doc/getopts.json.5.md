# get-opts.json(5)

# DESCRIPTION

Data definition for the `get-opts.sh` bash(1) script library.

# DATA

The arguments for/to the `bash-utils.getopts.define-*` functions all take the
form of `eval`(1)able key-value pair strings where the keys are as defined in
[get-opts.json(5)](get-opts.json.5.md).

`short`
: Short format (single character) option string - self-evidently, N/A for
  arguments.

`long`
: Long format option string(s) - self-evidently, N/A for arguments.

`help_short`
: Help text in cursory/short form (as reported in usage strings by
  `getopts.do-help`).

`help_long`
: Help text in long form (as reported in man(1) format help by
  `getopts.do-man`).

`index`
: Specific to argument definitions, this allows the caller to override the
  default index of the current definition.

`has_val`
: Flag indicating the _nature_ of the option as one of the following...
  - simple i.e. flag (default).
  - opt i.e. optionally takes a value.
  - comp i.e. takes a value.

`var`
: The name of a variable to be associated with the option/argument. If not used,
  then a script variable - one of `CliOpts` (an associated array) or `CliArgs`
  (a simple array) will be defined and updated depending on context.

`default`
: Default value (optional).

`validate`
: Legal/allowable value determination - this can take any of the following
  forms...
  - A regular expression, which if prefixed with the string **xT#**, defines it
    as a string conforming to the shells\` `extglob` strictures, otherwise it's
    an extended regular expression.
  - An `eval`(1)able string.
  - The name of a function in the callers context.

`mandatory`
: Optional mandatory flag

| Name | Context | Mandatory |
| --- | --- | --- |
| `short` | O | Y |
| `long` | O | N |
| `help_short` | O, A | N |
| `help_long` | O, A | N |
| `has_val` | O | N |
| `var` | O, A | N |
| `default` | O, A | N |
| `validate` | O, A | N |
| `mandatory` | O, A | N |

`action`
: Specifies an action to take on parsing an argument/option. By default,
  however, the action can take a modifier prefix as one of the following...
    - **pre#** action to be taken before processing the argument/option.
    - **post#** action to be taken after processing the argument/option.

# NOTES

- For option definitions, the definition **MUST** include the `short` &/or
  `long` option i.e. one, or other, is mandatory.
- If defined, the `default` is applied when and only when all options and
  arguments have been parsed.
- If `var` is not defined, then the asociated list variable is employed.
- If `default` is defined for a flag i.e. a non-`has_val`, option then, in cases  where the option is used on the CLI invocation, that value is used as the
  value of the associated flag variable.

# TO DO

None - at the moment ;-)

# SEE ALSO

[get-opts.sh(3)](get-opts.sh.3.md)
