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
![All features visible][all_features] ![Public holidays hidden][hide_holidays] ![Full week at start and end of month not displayed][hide_full_week] ![Colors turned off][hide_colors]

# Usage
```
pcal (c)2019 Jari Matilainen

Usage: pcal.pl [+|-<#>|<#> [<#>]] [-m|--month <month>] [-y|--year <year>] [-B|--before <before>]
          [-A|--after <after>] [-H|--noholidays] [-F|--nofullweek] [-C|--nocolors]
          [-v...v|--verbose] [-h|--help|--usage]

Details:
        -|+<num>                Display month that is <num> months before/after the current one
        <month> [<year>]        Display <month> for current year or for <year>
        -m|--month <month>      Display <month>
        -y|--year <year>        Display full <year> if -m not specified, otherwise display <month> of <year>
        -B|--before <num>       Display <num> months before the current one
        -A|--after <num>        Display <num> months after the current one
        -H|--noholidays         Hide Swedish holidays
        -F|--nofullweek         Hide display of full week at start and end of month
        -C|--nocolors           Don't use colors
        -v|--verbose            Print more verbose output
        -h|--help|--usage       Show this help

```

# PreReqs
```
At least perl v5.10
Text::Table
DateTime
Path::Tiny
Mojolicious

```
[all_features]: screenshots/all_features.png
[hide_colors]: screenshots/hide_colors.png
[hide_full_week]: screenshots/hide_full_week.png
[hide_holidays]: screenshots/hide_public_holidays.png
