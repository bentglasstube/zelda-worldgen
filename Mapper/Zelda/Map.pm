package Mapper::Zelda::Map;

use strict;
use warnings;

sub to_html {
  my ($self) = @_;

  my $h = $self->height - 1;
  my $w = $self->width - 1;

  my $output = '<table><tbody>';

  for my $y (reverse 0 .. $h) {
    $output .= '<tr>';
    for my $x (0 .. $w) {
      if (my $room = $self->get_room($x, $y)) {
        $output .= $self->room_html($room);
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

sub width { shift->{options}{width} }
sub height { shift->{options}{height} }

sub has_room {
  my ($self, $x, $y) = @_;

  return exists $self->{rooms}{$y}{$x};
}

sub set_room {
  my ($self, $x, $y, $walls, $special) = @_;

  $self->{rooms}{$y}{$x} = {
    walls   => $walls,
    special => $special,
  };
}

sub get_room {
  my ($self, $x, $y) = @_;

  return $self->{rooms}{$y}{$x};
}

1;
