#!/usr/bin/perl

# Copyright 2010 Boris Daeppen <boris_daeppen@bluewin.ch>
# 
# This file is part of NaYaBoh.
# 
# NaYaBoh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# NaYaBoh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with orgcreator.  If not, see <http://www.gnu.org/licenses/>.


# TODO
#  * regex replace of url with IP so that also images can be received
#  * better  and more test-url's
#  * nice shell output
#  * error handling (maybe just abort. ore just ignore and take the time?)


use strict;
use warnings;
use Time::HiRes qw(time);
use LWP::Simple;
use Net::DNS::Resolver; # uses libnet-dns-perl package in ubuntu
use GD::Graph::lines;   # uses libgd-graph-perl

$| = 1; # disable print buffer of Perl

# nasty handling of commandline arguments
if (not exists $ARGV[0]) {
    print "give the number of test cycles as argument.\nTry '-h' for help.\nABORTING\n";
    exit 1;
}
elsif ($ARGV[0] =~ /-h/) {
    print "\nUse this program only if you know what you do.\nFor documentation see the source code.\n\nThis program downloads some web pages and calculates the time consumed.\n\n";
    exit 1;
}
elsif ($ARGV[0] =~ /[^0-9]/) {
    print "argument must be a number.\nABORTING\n";
    exit 1;
}

# initialise things I need
my $rounds = $ARGV[0];
my $highest = 0;
my @time_proxy = ();
my @time_noproxy = ();

my @pages = (   'http://www.google.com/',
                'http://www.bbc.co.uk/',
                #'http://www.gnu.org/graphics/heckert_gnu.small.png',
                'http://hackles.org/');

my $dns_resolver = Net::DNS::Resolver->new(
      nameservers => [qw(192.168.0.1)],
      recurse     => 1,
      debug       => 0,
);


# loop through all pages, download them
for (my $i=1;$i<=$rounds;$i++) {
    #
    foreach my $url (@pages) {
        my $saveurl;
        if ($url =~ /\/\/(.*)\//) {
            $saveurl = $1;
        }

        my $start = time();
        print "PROXY\tRound $i:\ttry to receive $saveurl...";
        ask_nayaboh($saveurl);
        my $end = time();
        my $duration = sprintf("%.1f", ($end - $start));
        push (@time_proxy, $duration);
        if ($duration > $highest) { $highest = $duration; }
        print "\tDONE\t$duration sec\n";


        $start = time();
        print "DIRECT\tRound $i:\ttry to receive $saveurl...";
        ask_internet($saveurl);
        $end = time();
        $duration = sprintf("%.1f", ($end - $start));
        push (@time_noproxy, $duration);
        if ($duration > $highest) { $highest = $duration; }
        print "\tDONE\t$duration sec\n";

    }
}


my $graph = GD::Graph::lines->new(800, 400);

$graph->set( 
    x_label           => "$rounds Rounds",
    y_label           => 'Time',
    title             => 'Benchmark',
    y_max_value       => $highest,
    y_tick_number     => 1,
    y_label_skip      => 1 
) or die $graph->error;

my @sorted_time_proxy = sort {$a <=> $b } @time_proxy;
my @sorted_time_noproxy = sort {$a <=> $b } @time_noproxy;

my @data = (    [1 .. ($rounds * scalar @pages)],
                \@sorted_time_noproxy,
                \@sorted_time_proxy );

#use Data::Dumper;
#print Dumper(\@data);

$graph->set_legend('Direct', 'NaYaBoh');
my $gd = $graph->plot( \@data ) or die $graph->error;

open(IMG, '>file.png') or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;





sub ask_nayaboh {

    my $url = shift;

    my $any_error = 1;

    my $query = $dns_resolver->search($url);
    my $ip = 0;
    if ($query) {
        foreach my $rr ($query->answer) {
            next unless $rr->type eq "A";
            $ip = $rr->address;
            last; # break the loop
        }
    } else {
        warn "\nquery failed: ", $dns_resolver->errorstring, "\n";
        $any_error = 0;
    }

    my $status = `perl -e "BEGIN { \\\$ENV{HTTP_proxy}='http://192.168.0.1:3128' }; use LWP::Simple; print getstore ('http://$ip', 'bla');"`;

    if (is_error($status)) { $any_error = 0; }

    return $any_error;
}

sub ask_internet {

    my $url = shift;
    my $any_error = 1;

    my $status = getstore ("http://$url", $url);

    if (is_error($status)) { $any_error = 0; }

    return $any_error;
}
