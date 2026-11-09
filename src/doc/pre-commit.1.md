# pre-commit(1)

A script providing an alternate implementation of a pseudo-configurable Git
pre-commit hook.

## SYNOPSIS

When invoked via git(1), the invocation looks like this:

`[<DEF> [<DEF>...]] git commit [<ARG> [<ARG>]] <PATH> [<PATH>...]`

When invoked mandraulically, the hook can be employed as follows...

`[<DEF> [<DEF>...]] bash $BASH_UTILS_GITHOOK_FWK/hooks/pre-commit <PATH> [<PATH>...]`

### Where

`DEF`
: is an environment variable defintion where the variable is as defined in
[VARIABLES](#variables) (below).

## DESCRIPTION

As mentioned above, this is an implementation of a pseudo-configurable Git
pre-commit hook which is also capable of being invoked from command line to
ascertain the commit worthiness of files in the consumers repository. As
discussed further below, in outline, the configurability comprises the ability
to...

- Omit certain file(s)/path(s) from the syntax, style & unit test checks.
- Modify the behaviour of the hook (to a limited degree).

## FILES

Apart from the hook script itself, there is but one file that may be associated
with the hook: `.gitignore.pre-commit` - this file is located in the root
directory of the repository and is used in certain circumstances whereby, at
commit time, the consumer (of this hook) wants to direct the hook to, as its
name suggests, ignore any paths defined therein on a path per line basis.

## VARIABLES

`BASH_UTILS_GITHOOK_FWK`
: The location of the root directory of the githook-fwk element of the
  `bash-utils.sh` library, expressed as an absolute path, and defined by
  githook-fwk enrolment (using enrol-me.sh).

`GITHOOK_FWK_DEBUG`
: When set to non-true, this enables xtrace (shell debug) for the run-time
  duration of the script.

`GITHOOK_FWK_FAST_FAIL`
: By default, the hook fails when and only when all candidates paths have been
  checked, but by setting it to any non-empty string, the hook fails at the
  first hurdle.

`GITHOOK_FWK_COMMIT_FAIL`
: This variable is intended to support develeopment &/or debugging of the hook
  and when set to any non-empty string, causes the hook to do as it says in the
  variable ;-)

## NOTES

- The contexnts of the `.gitignore.pre-commit` file (as described above) is,
  itself, ignored when the hook is invoked mandraulically i.e. outside the
  context of a commit attempt.
