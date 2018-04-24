#!/usr/bin/env perl

use strict;
use warnings;
use local::lib;
use Text::Table;
use Term::ANSIColor qw(colored);
use DateTime;
use Getopt::Long qw(:config bundling pass_through);
use Data::Dumper;
use utf8;
use v5.010;

my $VERSION = '0.1.0';

binmode STDOUT, ":utf8";

sub usage {
  say <<EOB;
pcal (c)2018 Jari Matilainen

Usage: $0 [+|-<#>|<#> [<#>]] [-m|--month <month>] [-y|--year <year>] [-B|--before <before>]
          [-A|--after <after>] [-v...v|--verbose] [-h|--help|--usage]

Details:
	-|+<num>		Display month that is <num> months before/after the current one
	<month> [<year>]	Display <month> for current year or for <year>
	-m|--month <month>	Display <month>
	-y|--year <year>	Display full <year> if -m not specified, otherwise display <month> of <year>
	-B|--before <num>	Display <num> months before the current one
	-A|--after <num>	Display <num> months after the current one
	-h|--help|--usage	Show this help

EOB
  exit 0;
}

my $add = 0;
my @freeform;
sub process {
  my $input = shift;
  if($input =~ /^[+-]/) {
    $add = 0+$input unless $add;
  }
  else {
    push @freeform, $input if $input =~ /\d+/;
  }
}

sub make_table {
  my ($cal) = @_;
  my $mtb = Text::Table->new(
	  { title => '', align_title => 'right' },
	  { is_sep => 1, body => '│' },
	  map +{ title => $_, align_title => 'right' },
	  qw(Mo Tu We Th Fr Sa Su)
	);
  my @rows;
  my $t_year = $cal->year;
  my $t_month = $cal->month_name;
  my $som = $cal->truncate(to => 'month');
  do {
    my $week = $som->week_number;
    my @days = (colored(sprintf("%s%s", $week < 10 ? ' ' : '', $week), 'on_grey10'), ('') x (($som->dow) - 1));
    do {
      push @days, $som->doy == DateTime->now->doy ? colored($som->day, 'reverse') : $som->day;
      $som->add(days => 1);
    } while $week == $som->week && $som->day != 1;
    push @rows, [ @days ];
  } while $som->day != 1;
  
  $mtb->load(@rows);
  return { title => "$t_month $t_year", table => $mtb->stringify };
}

my ($month, $year, $before, $after, $verbose);
my $options = GetOptions(
  'month|m=i'    => \$month,
  'year|y=i'     => \$year,
  'before|B=i'   => \$before,
  'after|A=i'    => \$after,
  'verbose|v+'   => \$verbose,
  'help|usage|h' => \&usage,
  '<>'           => \&process
);

unless($options) {
  die "Failed to parse commandline\n";
}

my $dfy = $year && !$month;
eval {
  my @errors;
  push @errors, "You can't use -A and -B when displaying a full-year calendar" if $dfy && ($after || $before);
  $before = $before ? abs($before) * -1 : 0;
  $after = $after ? abs($after) : $dfy ? 11 : 0;

  die join("\n", @errors) . "\n" if @errors;
};
if($@) {
  die $@ . "\n";
}

my $now = DateTime->today(time_zone => 'local');
$month //= $freeform[0] // $now->month;
$year  //= $freeform[1] // $now->year;
if($dfy) {
  $now->set(year => $year);
  $now->truncate(to => 'year');
}
else {
  $now->set(month => $month);
  $now->set(year => $year);
  $now->add(months => $add) if $add;
}

my @calendars;
for($before .. $after) {
  state $index = 0;
  state $i = 0;
  $i++;
  my $cal = $now->clone;
  $cal->add(months => $_);
  push @{$calendars[$index]}, { title => '', table => '' } if $calendars[$index];
  push @{$calendars[$index]}, make_table($cal);
  if($i == 3) {
    $index++;
    $i = 0;
  }
}

for my $c (@calendars) {
  my $tb = Text::Table->new(map +{ title => $_->{title}, align_title => 'center' }, @$c);
  $tb->add(map { $_->{table} } @$c);
  say $tb;
}
