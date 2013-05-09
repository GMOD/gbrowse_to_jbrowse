package Bio::JBrowse::GBrowseConfConverter::MainFile::Dataset;
# ABSTRACT: base class for a converter for a GBrowse dataset stanza
use strict;
use warnings;

use List::MoreUtils ();

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub convert_stanza {
    my ( $self, $targetConf, $stanza, $gbrowse ) = @_;

    $targetConf->{datasets}{$stanza} = {
        url  => $gbrowse->{path}.'.json',
        name => $gbrowse->{description},
    };
}


1;
