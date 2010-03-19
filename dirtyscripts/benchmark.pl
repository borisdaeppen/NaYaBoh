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

use strict;
use warnings;
use LWP::Simple;

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
my @pages = ('http://www.google.com/', 'http://times.com/', 'http://www.yahoo.com/', 'https://login.yahoo.com/', 'http://www.facebook.com/', 'http://www.bbc.co.uk/');
my $totaltime = 0;
my %result = ();

# loop through all pages, download them
for (my $i=1;$i<=$rounds;$i++) {
    #
    foreach my $url (@pages) {
        my $saveurl;
        if ($url =~ /\/\/(.*)\//) {
            $saveurl = $1;
        }
        my $start = time();
        print "Round $i:\ttry to receive $url...";
        my $status = getstore ($url, "benchmark/$saveurl");
        die "Couldn't get $url" if (is_error($status));
        my $end = time();
        my $duration = $end - $start;

        $result{"Round $i"}{"$saveurl"} = $duration;
        
        print "\tDONE\t$duration sec\n";

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
my $req_count = scalar(@pages) * $rounds;
print "receiving of " . $req_count . " pages took $totaltime seconds.\n";
print "AVARAGE: " . int( ($totaltime / $req_count) + 0.5) . " seconds per page.\n";

#use Data::Dumper;
#print "\n\n\nDEBUG:\n";
#print Dumper(\%result);

