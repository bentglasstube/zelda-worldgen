#!/usr/bin/perl

use strict;
use warnings;

use Mapper::Zelda::Overworld;
use Mapper::Zelda::Dungeon;

print '<!doctype html><head><title>Zelda-like world generator</title><link rel="stylesheet" href="style.css"></head><body>';

print '<ul id="legend">';
printf '<li><span class="%s">&nbsp;</span> %s</li>', $_, ucfirst $_ for qw(plains forest mountain desert tundra);
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

for (1 .. $ow->levels) {
  print qq{<h1><a name="L$_">Level $_</a></h1>};

  say STDERR "Generate dungeon $_";
  my $level = Mapper::Zelda::Dungeon->generate();
  print $level->to_html;
}

print '</body></html>';
