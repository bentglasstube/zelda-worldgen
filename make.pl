#!/usr/bin/perl

use strict;
use warnings;

use Mapper::Zelda::Overworld;

print '<!doctype html><head><title>Zelda-like world generator</title><link rel="stylesheet" href="style.css"></head><body>';

print '<ul id="legend">';
printf '<li><span class="%s">&nbsp;</span> %s</li>', $_, ucfirst $_ for qw(ocean desert swamp plains forest tundra taiga mountain);
print '<li><span>S</span> Start Position</li>';
print '<li><span>H</span> Heart</li>';
print '<li><span>L#</span> Dungeon Level Entrance</li>';
print '<li><span>T</span> Level Treasure</li>';
print '<li><span>B</span> Level Boss</li>';
print '</ul>';

say STDERR "Generate overworld";
my $ow = Mapper::Zelda::Overworld->generate();

print '<h1><a name="overworld">Overworld</a></h1>';
print $ow->to_html;

print '</body></html>';
