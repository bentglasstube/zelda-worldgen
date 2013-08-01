#!/usr/bin/perl

use 5.010;

use strict;
use warnings;

use Mapper::Zelda::PerlinNoise;
use GD;

use constant WIDTH  => 32;
use constant HEIGHT => 21;
use constant RES    => 32;
use constant SCALE  => 8;

sub get_color {
  my ($temp, $rain) = @_;

  my $t = $temp < -0.15 ? 'L' : $temp > 0.15 ? 'H' : 'M';
  my $r = $rain < -0.15 ? 'L' : $rain > 0.15 ? 'H' : 'M';

  my $biomes = {
    LL => 'tundra',
    LM => 'plains',
    LH => 'plains',
    ML => 'plains',
    MM => 'forest',
    MH => 'forest',
    HL => 'desert',
    HM => 'plains',
    HH => 'forest',
  };

  my $colors = {
    tundra => [ 196, 196, 255 ],
    plains => [ 196, 255, 196 ],
    desert => [ 255, 255, 128 ],
    forest => [ 128, 255, 128 ],
  };

  return $colors->{$biomes->{"$t$r"}};
}

say STDERR "Generating noise map";
my $temp = Mapper::Zelda::PerlinNoise->new(SCALE, SCALE);
my $rain = Mapper::Zelda::PerlinNoise->new(SCALE, SCALE);

my $image = GD::Image->newTrueColor(RES * WIDTH, RES * HEIGHT);

say STDERR "Drawing image";

for my $y (0 .. HEIGHT - 1) {
  for my $x (0 .. WIDTH - 1) {
    my $t = $temp->value(SCALE * $x / WIDTH, SCALE * $y / HEIGHT);
    my $r = $rain->value(SCALE * $x / WIDTH, SCALE * $y / HEIGHT);
    my $rgb = get_color($t, $r);
    my $color = $image->colorAllocate(@$rgb);

    $image->filledRectangle(RES * $x, RES * $y, RES * $x + RES - 1, RES * $y + RES - 1, $color);
  }
}

print $image->png
