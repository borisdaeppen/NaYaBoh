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


# hack to enable proxy for LWP::Simple
BEGIN { $ENV{HTTP_proxy}="http://192.168.0.1:3128" }

use strict;
use warnings;
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
my @pages = ('http://www.google.com/', 'http://times.com/', 'http://www.bbc.co.uk/', 'http://sourceforge.net/', 'http://hackles.org/');
my $totaltime = 0;
my %result = ();
my $errors = 0;
my $highest = 0;

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
        print "Round $i:\ttry to receive $saveurl...";

        my $query = $dns_resolver->search($saveurl);
        my $ip = 0;
        if ($query) {
            foreach my $rr ($query->answer) {
                next unless $rr->type eq "A";
                $ip = $rr->address;
                last; # break the loop
            }
        } else {
            warn "\nquery failed: ", $dns_resolver->errorstring, "\n";
        }


        print "\ton $ip";
        my $status = getstore ("http://$ip", "benchmark/$saveurl");

        my $end = time();
        my $duration = $end - $start;
        if (is_error($status)) {
            $duration = 0;
            $errors++;
            $result{"Round $i"}{"$saveurl"} = 'ERROR';
            print "\tDONE\tERROR:\t$status\n";
        }
        else {
            $result{"Round $i"}{"$saveurl"} = $duration;
            if ($duration > $highest) { $highest = $duration; }
            print "\tDONE\t$duration sec\n";
        }

        $totaltime += $duration;
    }
}

# generate some intelligent output
print "\n\nRESULTS:\n\n";
foreach my $url (keys %{$result{"Round 1"}}) {
    print $url;
    print "\t";
}
print "\n";
foreach my $round (keys %result) {
    foreach my $url (keys %{$result{$round}}) {
        print "$result{$round}{$url}\t";
    }
        print "\n";
}
print "\n\nCALCULATIONS:\n\n";
my $req_count = (scalar(@pages) * $rounds) - $errors;
unless ($req_count) { die "NO REQUESTS MADE. $errors ERRORS.\n\n"; }
print "receiving of " . $req_count . " pages took $totaltime seconds.\n";
print "AVARAGE: " . int( ($totaltime / $req_count) + 0.5) . " seconds per page.\n";
print "\nThere where $errors ERRORS.\n\n";

#use Data::Dumper;
#print "\n\n\nDEBUG:\n";
#print Dumper(\%result);

my %grapharrays = ();
foreach my $round (keys %result) {
    foreach my $url (keys %{$result{$round}}) {
        if ($result{$round}{$url} =~ /ERROR/) {
            push (@{$grapharrays{$url}}, undef);
        }
        else {
            push (@{$grapharrays{$url}}, $result{$round}{$url});
        }
    }
}

my @data = ( [1 .. $rounds] );
foreach my $bla (keys %grapharrays) {
    push (@data, $grapharrays{$bla});
}
use Data::Dumper;
print "\n\n\nDEBUG:\n";
print Dumper(\@data);

my $graph = GD::Graph::lines->new(800, 600);

$graph->set( 
    x_label           => "$rounds Rounds",
    y_label           => 'Time',
    title             => 'Benchmark',
    y_max_value       => $highest,
    y_tick_number     => 1,
    y_label_skip      => 1 
) or die $graph->error;

my $gd = $graph->plot(\@data) or die $graph->error;

open(IMG, '>file.png') or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;

