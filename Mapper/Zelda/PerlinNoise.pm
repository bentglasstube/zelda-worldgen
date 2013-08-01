package Mapper::Zelda::PerlinNoise;

use 5.010;

use strict;
use warnings;

sub new {
  my ($class, $width, $height) = @_;

  my $self = bless {
    width   => $width,
    height  => $height,
    map     => [],
  }, $class;

  for my $y (0 .. $height) {
    for my $x (0 .. $width) {
      $self->{map}[$y][$x] = 2 * rand() - 1;
    }
  }

  return $self;
}

sub width   { shift->{width}   };
sub height  { shift->{height}  };

sub _noise {
  my ($self, $x, $y) = @_;
  my $xx = int($x) % $self->width;
  my $yy = int($y) % $self->height;
  return $self->{map}[$yy][$xx];
}

sub _smooth_noise {
  my ($self, $x, $y) = @_;
  my $sum = 0;
  for my $dy (-1, 0, 1) {
    for my $dx (-1, 0, 1) {
      my $m = 2 ** (2 + abs($dy) + abs($dx));
      $sum += $self->_noise($x + $dx, $y + $dy) / $m;
    }
  }
  return $sum;
}

sub __interpolate {
  my ($a, $b, $x)  = @_;
  my $f = (1 - cos($x * 3.14159265358979)) * 0.5;
  return $a * (1 - $f) + $b * $f;
}

sub value {
  my ($self, $x, $y) = @_;

  my $ix = int($x);
  my $fx = $x - $ix;

  my $iy = int($y);
  my $fy = $y - $iy;

  my $v1 = $self->_smooth_noise($ix,     $iy    );
  my $v2 = $self->_smooth_noise($ix + 1, $iy    );
  my $v3 = $self->_smooth_noise($ix,     $iy + 1);
  my $v4 = $self->_smooth_noise($ix + 1, $iy + 1);

  my $i1 = __interpolate($v1, $v2, $fx);
  my $i2 = __interpolate($v3, $v4, $fx);

  return __interpolate($i1, $i2, $fy);
}

sub normalized {
  my ($self, $x, $y, $t) = @_;

  my $value = $self->value($x, $y);
  return 'L' if $value < -$t;
  return 'H' if $value >  $t;
  return 'M';
}

1;
