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

sub generate_walls {
  my ($self) = @_;

  for my $y (0 .. $self->height - 1) {
    for my $x (0 .. $self->width - 1) {
      $self->set_room($x, $y, 15);
    }
  }

  my $x = int($self->width / 2);
  my $y = 0;

  $self->get_room($x, $y)->{special} = 'S';

  my @stack = ();
  while (1) {
    my @ways = ();

    push @ways, TOP    if $self->unvisited($x, $y + 1);
    push @ways, RIGHT  if $self->unvisited($x + 1, $y);
    push @ways, BOTTOM if $self->unvisited($x, $y - 1);
    push @ways, LEFT   if $self->unvisited($x - 1, $y);

    if (@ways == 0) {
      last unless @stack;

      my $cell = pop @stack;
      $x = $cell->[0];
      $y = $cell->[1];
    } else {
      push @stack, [$x, $y] if @ways > 1;

      @ways = shuffle @ways;
      my $way = $ways[0];

      $self->destroy_wall($x, $y, $way);
      $y++ if $way == TOP;
      $x++ if $way == RIGHT;
      $y-- if $way == BOTTOM;
      $x-- if $way == LEFT;
    }
  }

  for my $y (1 .. $self->height - 2) {
    for my $x (1 .. $self->width - 2) {
      my $walls = $self->get_room($x, $y)->{walls};

      for my $d (TOP, RIGHT, BOTTOM, LEFT) {
        next unless $walls & $d;
        $self->destroy_wall($x, $y, $d) if .25 > rand;
      }
    }
  }
}

sub unvisited {
  my ($self, $x, $y) = @_;

  my $room = $self->get_room($x, $y) or return undef;
  return $room->{walls} == 15;
}

sub destroy_wall {
  my ($self, $x, $y, $direction) = @_;

  if ($direction == TOP) {
    $self->get_room($x, $y)->{walls} &= 15 - TOP;
    $self->get_room($x, $y + 1)->{walls} &= 15 - BOTTOM;
  } elsif ($direction == RIGHT) {
    $self->get_room($x, $y)->{walls} &= 15 - RIGHT;
    $self->get_room($x + 1, $y)->{walls} &= 15 - LEFT;
  } elsif ($direction == BOTTOM) {
    $self->get_room($x, $y)->{walls} &= 15 - BOTTOM;
    $self->get_room($x, $y - 1)->{walls} &= 15 - TOP;
  } elsif ($direction == LEFT) {
    $self->get_room($x, $y)->{walls} &= 15 - LEFT;
    $self->get_room($x - 1, $y)->{walls} &= 15 - RIGHT;
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
