package Mapper::Zelda::Overworld;

use base 'Mapper::Zelda::Map';

sub generate {
  my ($class, $options) = @_;

  $options //= {};

  $options->{width} //= 32;
  $options->{height} //= 21;
  $options->{levels} //= 13;
  $options->{hearts} //= 7;
  $options->{smoothing} //= 3;
  $options->{openness} //= 0.25;

  my $self = bless { options => $options }, $class;

  $self->generate_walls;
  $self->smooth_biomes for 1 .. $self->smoothing;
  $self->place_evenly(map sprintf('L%u', $_), 1 .. $self->levels);
  $self->place_evenly(('H') x $self->hearts);

  return $self;
}

sub random_biome {
  my ($self, $x, $y) = @_;

  my $z = $y / $self->height;
  my $r = rand();

  if ($z < 0.6) {
    return 'forest'   if $r < 0.15;
    return 'plains'   if $r < 0.55;
    return 'mountain' if $r < 0.65;
    return 'desert';
  } elsif ($z < 0.85) {
    return 'forest'   if $r < 0.35;
    return 'mountain' if $r < 0.85;
    return 'tundra';
  } else {
    return 'mountain' if $r < 0.45;
    return 'tundra';
  }
}

sub smooth_biomes {
  my ($self) = @_;

  for my $y (0 .. $self->height - 1) {
    for my $x (0 .. $self->width - 1) {
      if (my $room = $self->get_room($x, $y)) {
        my %weights = ();
        my $count = 0;
        for my $dy ($y - 1 .. $y + 1) {
          for my $dx ($x - 1 .. $x + 1) {
            my $dr = $self->get_room($dx, $dy) or next;
            $weights{$dr->{biome}}++;
            $count++;
          }
        }

        foreach (keys %weights) {
          $room->{biome} = $_ and last if $weights{$_} > 4;
          $room->{biome} = $_ if $weights{$_} > 3;
        }
      }
    }
  }
}

sub levels {
  my ($self) = @_;
  return $self->{options}{levels};
}

sub hearts {
  my ($self) = @_;
  return $self->{options}{hearts};
}

sub smoothing {
  my ($self) = @_;
  return $self->{options}{smoothing};
}

1;
