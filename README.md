# pcal
Perl version of bsd cal

# Why?
I wanted to see the week number to the left of the calendar,
with bsd cal it's only possible to show the week number at
the bottom using ncal

```
$ ncal -w -M
    April 2018
Mo     2  9 16 23 30
Tu     3 10 17 24
We     4 11 18 25
Th     5 12 19 26
Fr     6 13 20 27
Sa     7 14 21 28
Su  1  8 15 22 29
   13 14 15 16 17 18
```
vs
```
$ pcal
      April 2018
   Mo Tu We Th Fr Sa Su
13                    1
14  2  3  4  5  6  7  8
15  9 10 11 12 13 14 15
16 16 17 18 19 20 21 22
17 23 24 25 26 27 28 29
18 30
```

# Usage
```
Usage: pcal [+|-<#>|<#> [<#>]] [-m|--month <month>] [-y|--year <year>] [-B|--before <before>]
            [-A|--after <after>] [-v...v|--verbose] [-h|--help|--usage]

Details:
        -|+<num>                Display month that is <num> months before/after the current one
        <month> [<year>]        Display <month> for current year or for <year>
        -m|--month <month>      Display <month>
        -y|--year <year>        Display full <year> if -m not specified, otherwise display <month> of <year>
        -B|--before <num>       Display <num> months before the current one
        -A|--after <num>        Display <num> months after the current one
        -h|--help|--usage       Show this help
```
