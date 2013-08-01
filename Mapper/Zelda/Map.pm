package Mapper::Zelda::Map;

use strict;
use warnings;

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

  $self->set_room($x, $y, _make_room(BOTTOM, 15 - BOTTOM, $self->openness), 'S');

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

      $self->set_room($x, $y, _make_room($base, $mask, $self->openness));
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

sub to_html {
  my ($self) = @_;

  my $h = $self->height - 1;
  my $w = $self->width - 1;

  my $output = '<table><tbody>';

  for my $y (reverse 0 .. $h) {
    $output .= '<tr>';
    for my $x (0 .. $w) {
      if (my $room = $self->get_room($x, $y)) {
        $output .= sprintf '<td class="r%02u %s">', $room->{walls}, $room->{biome};
        $output .= $room->{special} || '&nbsp;';
      } else {
        $output .= '<td class="empty">&nbsp;</td>';
      }
      $output .= '</td>';
    }
    $output .= '</tr>';
  }

  $output .= '</tbody></table>';
  return $output;
}

sub to_text {
  my ($self) = @_;

  my $h = $self->height - 1;
  my $w = $self->width - 1;

  my $output = '';

  for my $y (reverse 0 .. $h) {
    for my $x (0 .. $w) {
      if (my $room = $self->get_room($x, $y)) {
        $output .= '#';
        $output .= $room->{walls} & TOP ? '##' : '  ';
      } else {
        $output .= '...';
      }
    }
    $output .= "#\n";

    for my $x (0 .. $w) {
      if (my $room = $self->get_room($x, $y)) {
        $output .= $room->{walls} & LEFT ? '#' : ' ';
        $output .= sprintf('%-2s', $room->{special} || '');
      } else {
        $output .= '...';
      }
    }

    $output .= "#\n";
  }

  for my $x (0 .. $w) {
    $output .= "###";
  }
  $output .= "#\n";

  return $output;
}

sub width {
  my ($self) = @_;
  return $self->{options}{width};
}

sub height {
  my ($self) = @_;
  return $self->{options}{height};
}

sub openness {
  my ($self) = @_;
  return $self->{options}{openness};
}

sub has_room {
  my ($self, $x, $y) = @_;

  return exists $self->{rooms}{$y}{$x};
}

sub set_room {
  my ($self, $x, $y, $walls, $special) = @_;

  $self->{rooms}{$y}{$x} = {
    walls   => $walls,
    special => $special,
    biome   => $self->random_biome($x, $y),
  };
}

sub get_room {
  my ($self, $x, $y) = @_;

  return $self->{rooms}{$y}{$x};
}

sub room_count {
  my ($self) = @_;

  my $count = 0;
  foreach my $y (keys %{$self->{rooms}}) {
    my @rooms = keys ${$self->{rooms}{$y}};
    $count += @rooms;
  }

  return $count;
}

1;
