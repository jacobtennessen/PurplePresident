#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;

##### ##### ##### ##### #####

# This section describes the proper usage of the script

use vars qw( $opt_g $opt_i $opt_r $opt_x $opt_y $opt_w $opt_h );

my $usage = "
PurplePresident.pl - This script produces another script, to be run in R. That script generates a series of image files.
These can be combined into a single gif with a tool like ImageMagick.

Copyright (C) 2019 by Jacob A Tennessen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Usage: perl PurplePresident.pl options
 optional:
  -g  number of generations to run [default = 1000]
  -i  number of individuals in the population [default = 100]
  -r  radius of the initial circle (individuals will initially be randomly distributed with uniform density within this circle) [default = 1]
  -x  x-axis coordinate of the center of the initial circle [default = 0]
  -y  y-axis coordinate of the center of the initial circle [default = 0]
  -w  width of the region to plot [default = 1.5]
  -h  help. Prints this usage text
";

##### ##### ##### ##### #####

# This section records the input options, if any

getopts('g:i:r:x:y:w:h');

my ($reps, $inds, $radius, $xoffset, $yoffset, $width);

if (defined $opt_g) {
  $reps = $opt_g;
} else {
  $reps = 1000;
}

if (defined $opt_i) {
  $inds = $opt_i;
} else {
  $inds = 100;
}

if (defined $opt_r) {
  $radius = $opt_r;
} else {
  $radius = 1;
}

if (defined $opt_x) {
  $xoffset = $opt_x;
} else {
  $xoffset = 0;
}

if (defined $opt_y) {
  $yoffset = $opt_y;
} else {
  $yoffset = 0;
}

if (defined $opt_w) {
  $width = $opt_w;
} else {
  $width = 1.5;
}

if ($opt_h) {
  print "$usage\n";
  exit;
}

##### ##### ##### ##### #####

# This section generates the initial set of individuals

my %posx;

my %posy;

my @xlist;

my @ylist;

my $indcount = 1;

until ((scalar(@xlist)) >= $inds) {
    my $px = $radius - rand(2*$radius);
    my $py = $radius - rand(2*$radius);
    my $cd = sqrt($px*$px + $py*$py);
    if ($cd <= $radius) {
        $posx{$indcount} = $px + $xoffset;
        $posy{$indcount} = $py + $yoffset;
        push @xlist, sprintf "%.4f", $posx{$indcount};
        push @ylist, sprintf "%.4f", $posy{$indcount};
        $indcount +=1;
    }
}

##### ##### ##### ##### #####

# This sections simulates all subsequent generations and records the positions of all individuals

my @rout;

my $piccount = 0;

for (my $rep = 0; $rep < $reps; $rep++) {
    
    my $fitnesstotal = 0;
    
    my %fitness;
    
    for (my $i = 1; $i <= $inds; $i++) { #for each individual, fitness is calculated

        my $centerdist = sqrt($posx{$i}*$posx{$i} + $posy{$i}*$posy{$i});
        my $repel = 0;
        for (my $alt = 1; $alt <= $inds; $alt++) {
            unless ($alt == $i) {
                 my $repeldist += sqrt(($posx{$alt}-$posx{$i})*($posx{$alt}-$posx{$i}) + ($posy{$alt}-$posy{$i})*($posy{$alt}-$posy{$i}));
                 $repel += $repeldist**2; #the squared distance between two individuals
            }
        }
        my $compliance = exp(-0.5* ($centerdist**2))/sqrt(2*3.14159); #compliance is based on a standard normal distribution following this equation
        my $defiance = $repel/($inds-1); #defiance is based on the average squared distance against all other individuals
        my $fitness = $compliance*$defiance; #fitness is the product of compliance and defiance
        push @xlist, sprintf "%.4f", $posx{$i};
        push @ylist, sprintf "%.4f", $posy{$i};
        $fitness{$i} = $fitness;
        $fitnesstotal += $fitness;
    
    }
    
    my $xlist = join ",", @xlist;
    
    my $ylist = join ",", @ylist;
    
    $piccount +=1;
    
    push @rout, "png('PP$piccount.png',res = 200, width = 5, height = 5, units = \"in\",bg = \"transparent\")";
    push @rout, "plot(c($xlist),c($ylist),xlim=c(-$width,$width),ylim=c(-$width,$width),xlab=\"\",ylab=\"\",xaxt=\"n\",yaxt=\"n\")";
    push @rout, "dev.off()";

    my %newx;
    
    my %newy;
    
    for (my $ni = 1; $ni <= $inds; $ni++) { #generates the offspring of all individuals based on fitness
        my $id = rand($fitnesstotal);
        my $fcumul = 0;
        for (my $i = 1; $i <= $inds; $i++) {
            unless (defined $newx{$ni}) {
                $fcumul += $fitness{$i};
                my $jx = 0;
                my $jy = 0;
                for (my $j = 1; $j <= 10; $j++) {
                    $jx += (0.005 - (rand(0.01)));
                    $jy += (0.005 - (rand(0.01)));
                }
                if ($id < $fcumul) {
                    $newx{$ni} = $posx{$i} + $jx;
                    $newy{$ni} = $posy{$i} + $jy;
                    last;
                }
            }
        }
    }

    for (my $i = 1; $i <= $inds; $i++) {
        $posx{$i} = $newx{$i};
        $posy{$i} = $newy{$i};
    }
    
    @xlist = ();
    
    @ylist = ();

}

##### ##### ##### ##### #####

# This section outputs the result

my $result = join "\n", @rout;

unless ( open(OUT, ">R_pp.r") ) {
    print "Cannot open file \"R_pp.r\" to write to!!\n\n";
    exit;
}
print OUT $result;
close (OUT);


