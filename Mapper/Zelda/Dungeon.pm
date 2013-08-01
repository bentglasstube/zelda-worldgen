package Mapper::Zelda::Dungeon;

use base 'Mapper::Zelda::Map';

sub generate {
  my ($class, $options) = @_;

  $options //= {};

  $options->{height} //= 8;
  $options->{width} //= 8;
  $options->{openness} //= 0.40;

  my $self = bless { options => $options }, $class;

  $self->generate_walls;
  $self->place_evenly('B', 'T');

  return $self;
}

sub random_biome {
  my ($self, $x, $y) = @_;

  return 'dungeon';
}

1;
