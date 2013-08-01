package Mapper::Zelda::Overworld;

use strict;
use warnings;

use Mapper::Zelda::PerlinNoise;

use base 'Mapper::Zelda::Map';

use constant TOP    => 1;
use constant RIGHT  => 2;
use constant BOTTOM => 4;
use constant LEFT   => 8;

use List::Util qw'shuffle';

sub _make_room {
  my ($base, $mask, $openness) = @_;

  if ($mask) {
    for (TOP, RIGHT, BOTTOM, LEFT) {
      if ($mask & $_) {
        if (rand() < $openness) {
          $base |= $_;
        } else {
          $base &= 15 - $_;
        }
      }
    }

    if ($base == 15) {
      for (TOP, RIGHT, BOTTOM, LEFT) {
        if ($mask & $_) {
          $base &= 15 - $_;
          last;
        }
      }
    }
  }

  return $base;
}

sub generate_walls {
  my ($self) = @_;

  my $x = int($self->width / 2);
  my $y = 0;

  $self->set_room($x, $y, _make_room(BOTTOM, 15 - BOTTOM, 0.25), 'S');

  my @stack = ();
  while (1) {
    my @ways = ();
    my $room = $self->get_room($x, $y)->{walls};

    push @ways, TOP    unless $room & TOP    or $self->has_room($x, $y + 1);
    push @ways, RIGHT  unless $room & RIGHT  or $self->has_room($x + 1, $y);
    push @ways, BOTTOM unless $room & BOTTOM or $self->has_room($x, $y - 1);
    push @ways, LEFT   unless $room & LEFT   or $self->has_room($x - 1, $y);

    if (@ways == 0) {
      return unless @stack;

      my $cell = pop @stack;
      $x = $cell->[0];
      $y = $cell->[1];
    } else {
      push @stack, [$x, $y] if @ways > 1;
      @ways = shuffle @ways;
      my $way = $ways[0];
      my $mask = 15;
      my $base = 0;

      if    ($way == TOP)    { $y++; }
      elsif ($way == RIGHT)  { $x++; }
      elsif ($way == BOTTOM) { $y--; }
      elsif ($way == LEFT)   { $x--; }

      if ($x == 0) {
        $base |= LEFT;
        $mask &= 15 - LEFT
      } elsif ($x == $self->width - 1) {
        $base |= RIGHT;
        $mask &= 15 - RIGHT
      }

      if ($y == 0) {
        $base |= BOTTOM;
        $mask &= 15 - BOTTOM
      } elsif ($y == $self->height - 1) {
        $base |= TOP;
        $mask &= 15 - TOP
      }

      if (defined (my $below = $self->get_room($x, $y - 1))) {
        $mask &= 15 - BOTTOM;
        $base |= ($below->{walls} & TOP ? BOTTOM : 0);
      }

      if (defined (my $above = $self->get_room($x, $y + 1))) {
        $mask &= 15 - TOP;
        $base |= ($above->{walls} & BOTTOM ? TOP : 0);
      }

      if (defined (my $left  = $self->get_room($x - 1, $y))) {
        $mask &= 15 - LEFT;
        $base |= ($left->{walls} & RIGHT ? LEFT : 0);
      }

      if (defined (my $right = $self->get_room($x + 1, $y))) {
        $mask &= 15 - RIGHT;
        $base |= ($right->{walls} & LEFT ? RIGHT : 0);
      }

      $self->set_room($x, $y, _make_room($base, $mask, 0.25));
    }
  }
}

sub place_evenly {
  my ($self, @items) = @_;

  my $seg = int(sqrt(@items));

  my $sw = int($self->width / $seg);
  my $sh = int($self->height / $seg);

  @items = shuffle @items;

  for my $section (0 .. $seg * $seg - 1) {
    my $i = shift @items or next;

    while (1) {
      my $x = int($section % $seg) * $sw + int($sw * rand);
      my $y = int($section / $seg) * $sh + int($sh * rand);

      my $room = $self->get_room($x, $y) or next;
      next if $room->{special};

      $room->{special} = $i;
      last;
    }
  }

  $self->place_evenly(@items) if @items;
}

sub generate {
  my ($class, $options) = @_;

  $options //= {};

  $options->{width} //= 32;
  $options->{height} //= 21;
  $options->{levels} //= 13;
  $options->{hearts} //= 7;

  my $self = bless { options => $options }, $class;

  $self->generate_walls;
  $self->generate_biomes;
  $self->place_evenly(map sprintf('L%u', $_), 1 .. $self->levels);
  $self->place_evenly(('H') x $self->hearts);

  return $self;
}

sub levels { shift->{options}{levels} }
sub hearts { shift->{options}{hearts} }

sub get_biome {
  my ($self, $alt, $rain)  = @_;

  if ($alt < -0.25) {
    return 'desert' if $rain < 0;
    return 'swamp';
  } elsif ($alt < 0.25) {
    return 'plains' if $rain < 0;
    return 'forest';
  } else {
    return 'mountain' if $rain < 0;
    return 'tundra';
  }
}

use constant SCALE => 8;

sub room_html {
  my ($self, $room) = @_;

  return sprintf '<td class="r%02u %s">%s</td>', $room->{walls}, $room->{biome}, $room->{special} || '&nbsp;';
}

sub generate_biomes {
  my ($self) = @_;

  my $alt  = Mapper::Zelda::PerlinNoise->new(SCALE, SCALE);
  my $temp = Mapper::Zelda::PerlinNoise->new(SCALE, SCALE);
  my $rain = Mapper::Zelda::PerlinNoise->new(SCALE, SCALE);

  my $threshold = 0.1;

  for my $y (0 .. $self->height - 1) {
    my $yy = SCALE * $y / $self->height;

    for my $x (0 .. $self->width - 1) {
      my $room = $self->get_room($x, $y) or next;

      my $xx = SCALE * $x / $self->width;

      my $a = $alt->value($xx, $yy);
      my $t = $temp->value($xx, $yy);
      my $r = $rain->value($xx, $yy);

      $room->{biome} = $self->get_biome($a, $t, $r);
    }
  }
}

1;
