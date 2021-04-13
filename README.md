# Server Install Scripts

## Resources & Guides

- [Command Parser](https://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash/21128172)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Colored Output](https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux)

## Argument Parsing

### getops

The basic syntax of getopts is (see: man bash):

```bash
getopts OPTSTRING VARNAME [ARGS...]
```

where:

- `OPTSTRING` is string with list of expected arguments,
  - `h` - check for option `-h` **without** parameters; gives error on unsupported options;
  - `h:` - check for option `-h` **with** parameter; gives errors on unsupported options;
  - `abc` - check for options `-a`, `-b`, `-c`; **gives** errors on unsupported options;
  - `:abc` - check for options `-a`, `-b`, `-c`; **silences** errors on unsupported options;
    <sup>Notes: In other words, colon in front of options allows you handle the errors in your code. Variable will contain ? in the case of unsupported option, : in the case of missing value.</sup>
- `OPTARG` - is set to current argument value,
- `OPTERR` - indicates if Bash should display error messages.

So the code can be:

```bash
#!/usr/bin/env bash
usage() { echo "$0 usage:" && grep " .)\ #" $0; exit 0; }
[ $# -eq 0 ] && usage
while getopts ":hs:p:" arg; do
  case $arg in
    p) # Specify p value.
      echo "p is ${OPTARG}"
      ;;
    s) # Specify strength, either 45 or 90.
      strength=${OPTARG}
      [ $strength -eq 45 -o $strength -eq 90 ] \
        && echo "Strength is $strength." \
        || echo "Strength needs to be either 45 or 90, $strength found instead."
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done
```

Example usage:

```bash
$ ./foo.sh
./foo.sh usage:
    p) # Specify p value.
    s) # Specify strength, either 45 or 90.
    h | *) # Display help.
$ ./foo.sh -s 123 -p any_string
Strength needs to be either 45 or 90, 123 found instead.
p is any_string
$ ./foo.sh -s 90 -p any_string
Strength is 90.
p is any_string
```

See: [Small getopts tutorial](https://wiki.bash-hackers.org/howto/getopts_tutorial) at Bash Hackers Wiki
