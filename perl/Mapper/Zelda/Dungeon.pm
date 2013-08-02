package Mapper::Zelda::Dungeon;

use strict;
use warnings;

use base 'Mapper::Zelda::Map';

sub generate {
  my ($class, $options) = @_;

  $options //= {};

  my $self = bless { options => $options }, $class;

  return $self;
}

1;
