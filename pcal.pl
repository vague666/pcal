#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.010;
use DateTime;
use Path::Tiny 'path';
use Text::Table;
use Clone 'clone';
use Term::ANSIColor qw(colored);
use Getopt::Long qw(:config bundling pass_through);

my $VERSION = '0.3.2';
my $datafile = $ENV{HOME} . "/.config/pcal/pcal.dat";
my $mtb = Text::Table->new(
  { title => '', align_title => 'right' },
  { is_sep => 1, body => '│' },
  map +{ title => $_, align_title => 'right' },
  qw(Mo Tu We Th Fr Sa Su)
);

binmode STDOUT, ":utf8";

sub usage {
  say <<EOB;
pcal (c)2018 Jari Matilainen

Usage: $0 [+|-<#>|<#> [<#>]] [-m|--month <month>] [-y|--year <year>] [-B|--before <before>]
          [-A|--after <after>] [-H|--noholidays] [-F|--nofullweek] [-C|--nocolors]
          [-v...v|--verbose] [-h|--help|--usage]

Details:
	-|+<num>		Display month that is <num> months before/after the current one
	<month> [<year>]	Display <month> for current year or for <year>
	-m|--month <month>	Display <month>
	-y|--year <year>	Display full <year> if -m not specified, otherwise display <month> of <year>
	-B|--before <num>	Display <num> months before the current one
	-A|--after <num>	Display <num> months after the current one
	-H|--noholidays         Hide Swedish holidays
	-F|--nofullweek		Hide display of full week at start and end of month 
	-C|--nocolors		Don't use colors
	-v|--verbose		Print more verbose output
	-h|--help|--usage	Show this help

EOB
  exit 0;
}

my @freeform;
my $add = 0;
my $holidays;
my ($month, $year, $before, $after, $hide_holidays, $hide_fullweek, $hide_colors, $verbose);
my $options = GetOptions(
  'month|m=i'       => \$month,
  'year|y:i'        => \$year,
  'before|B=i'      => \$before,
  'after|A=i'       => \$after,
  'noholidays|H'    => \$hide_holidays,
  'nofullweek|F'    => \$hide_fullweek,
  'nocolors|C'      => \$hide_colors,
  'verbose|v+'      => \$verbose,
  'help|usage|h'    => \&usage,
  '<>'              => \&process
);

unless($options) {
  die "Failed to parse commandline\n";
}

my $dfy = defined $year && !$month;
my @errors;
push @errors, "You can't use -A and -B when displaying a full-year calendar" if $dfy && ($after || $before);
$before = $before ? abs($before) * -1 : 0;
$after = $after ? abs($after) : $dfy ? 11 : 0;
$hide_holidays = 0 unless $hide_holidays;

die join("\n", @errors) . "\n" if @errors;

my $now = DateTime->today(time_zone => 'local');
$month //= $freeform[0] // $now->month;
$year  ||= $freeform[1] // $now->year;
if($dfy) {
  $now->set(year => $year);
  $now->truncate(to => 'year');
}
else {
  $now->set(month => $month);
  $now->set(year => $year);
  $now->add(months => $add) if $add;
}

init();

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

##########################################################
sub process {
  my $input = shift;
  if($input =~ /^[+-]\d+/) {
    $add = 0+$input unless $add;
  }
  else {
    push @freeform, $input if $input =~ /\d+/;
  }
}

sub fetch_holidays {
  my $year = shift;
  say "Fetching data for $year" if $verbose;
  require Mojo::UserAgent;
  return [ Mojo::UserAgent->new->max_redirects(5)->get("https://www.kalender.se/helgdagar/$year")->result->dom('table.table.table-striped tbody tr td:last-child')->map('text')->each ];
}

sub is_holiday {
  my $cal = shift;
  if($cal->dow == 7) {
    return 1;
  }

  if(!$hide_holidays) {
    unless(exists $holidays->{$cal->year}) {
      $holidays->{$cal->year} = fetch_holidays($cal->year);
    }

    if(grep { $_ == $cal->doy } @{$holidays->{$cal->year}} ) {
      return 1;
    }
  }
  
  return 0;
}

sub make_table {
  my ($cal) = @_;
  my @rows;
  my $som = $cal->truncate(to => 'month');
  my $yearnumber = $som->year;
  my $monthname = $som->month_name;
  my $t_month = $som->month;
  $som = $cal->truncate(to => 'week') unless $hide_fullweek;

  do {
    my $week = $som->week_number;
    my $wstr = sprintf("%2s", $week);
    my @days = $hide_colors ? $wstr : colored($wstr, 'on_grey10');

    unless($hide_fullweek) {
      while($som->month != $t_month) {
        push @days, $hide_colors ? $som->day : colored($som->day, 'grey5');
        $som->add(days => 1);
      }
    }
    else {
      push @days, ('') x (($som->dow) - 1);
    }

    do {
      my $cur = !$hide_colors && $som->doy == DateTime->now->doy && $cal->year == DateTime->now->year ? colored($som->day, 'reverse') : $som->day;
      push @days, !$hide_colors && is_holiday($som) ? colored($cur, 'bright_red') : $cur;
      $som->add(days => 1);
    } while $week == $som->week && $som->day != 1;

    unless($hide_fullweek) {
      while($week == $som->week) {
        push @days, $hide_colors ? $som->day : colored($som->day, 'grey5');
        $som->add(days => 1);
      }
    }

    push @rows, [ @days ];
  } while $som->month == $t_month;
  
  my $ttb = clone $mtb;
  $ttb->load(@rows);
  return { title => "$monthname $yearnumber", table => $ttb->stringify };
}

sub init {
  if(!$hide_holidays && path($datafile)->exists) {
    eval {
      require File::Slurper;
      File::Slurper->import(qw(write_binary read_binary));
      require Sereal::Decoder;
      Sereal::Decoder->import(qw(sereal_decode_with_object));
      require Sereal::Encoder;
      Sereal::Encoder->import(qw(sereal_encode_with_object));
    };
    die $@ if $@;

    $holidays = sereal_decode_with_object(Sereal::Decoder->new, read_binary($datafile));
  }
}

END {
  unless($hide_holidays) {
    my $path = path($datafile);
    if(!$path->exists) {
      $path->touchpath;
    }
    write_binary($datafile, sereal_encode_with_object(Sereal::Encoder->new, $holidays));
  }
}
