package Bio::JBrowse::GBrowseConfConverter::general;
# ABSTRACT: base class for a converter for a GBrowse [GENERAL] stanza
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub convert_stanza {
    my ( $self, $targetConf, $track_label, $gbrowse ) = @_;

    for my $key ( keys %$gbrowse ) {
        ( my $mkey = $key ) =~ s/\W/_/g;
        if( $self->can("handle_$mkey") ) {
            $self->${\"handle_$mkey"}( $gbrowse->{$key}, $targetConf );
        }
    }
}

sub handle_application_name {
    my ( $self, $value, $targetConf ) = @_;
    $targetConf->{aboutThisBrowser}{title} = $value;
}

sub handle_application_long {
    my ( $self, $value, $targetConf ) = @_;
    $targetConf->{aboutThisBrowser}{description} = $value;
}

sub handle_default_source {
    my ( $self, $value, $targetConf ) = @_;
    $targetConf->{dataset_id} = $value;
}

1;
