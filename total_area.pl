#! /usr/bin/perl -w

use strict;

# Figure out the total area for all the .ps file arguments.
my $Total = 0;
my $FName = "";
my $BBox  = "";

# Last line of PS file is the bounding box (% Bounding xmin ymin xmax ymax).
foreach $FName (@ARGV)
{
	$BBox = `tail -n 1 $FName`;
	$BBox =~ /(-?[.\d]+)\s+(-?[.\d]+)\s+(-?[.\d]+)\s+(-?[.\d]+)/;
	my ($xmin, $ymin, $xmax, $ymax) = ($1, $2, $3, $4);

	$Total += (($xmax - $xmin) * ($ymax - $ymin));
}

print "$Total\n";

