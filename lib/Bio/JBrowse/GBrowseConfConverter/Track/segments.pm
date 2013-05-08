package Bio::JBrowse::GBrowseConfConverter::Track::segments;
# ABSTRACT: converter for segments-based tracks

use strict;
use warnings;

use base 'Bio::JBrowse::GBrowseConfConverter::Track';

sub handle_glyph {
    my ( $self, $value, $jb ) = @_;
    $jb->{glyph} = 'JBrowse/View/Track/HTMLFeatures';
}

sub handle_strand_arrow {
    my ( $self, $value, $jb ) = @_;
    $jb->{style}{arrowheadClass} = $value ? 'arrowhead' : undef;
}

1;
