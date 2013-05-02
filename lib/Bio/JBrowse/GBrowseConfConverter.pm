package Bio::JBrowse::GBrowseConfConverter;
use strict;
use warnings;

use File::Basename ();
use Text::ParseWords ();

use Bio::Graphics::FeatureFile ();

sub new {
    my ( $class ) = @_;
    return bless {
        gbconf => {}
    }, $class;
}

sub add_file {
    my ( $self, $file ) = @_;

    my $text = do {
        open my $f, '<', $file or die "$! reading $file";
        local $/;
        <$f>
    };

    $self->add_text( $text );
}

sub add_text {
    my ( $self, $text ) = @_;

    # strip out includes and execs, handle includes specially
    my @includes;
    $text =~ s/^\#include\s+(.+)/push @includes, Text::ParseWords::shellwords( $1 ); ''/egi;
    $text =~ s/^\#exec\s+([^\n]+)/warn "ignoring exec $1"; ''/egi;

    push @{ $self->{gbconf}{include} }, @includes;

    my $ff = Bio::Graphics::FeatureFile->new( -text => $text );
    for my $stanza ( $ff->setting ) {
        for my $opt ( $ff->setting( $stanza ) ) {
            $self->{gbconf}{lc $stanza}{lc $opt} = $ff->setting( $stanza, $opt );
        }
    }
}

sub jbrowse_conf_data {
    my ( $self ) = @_;

    my %jb;
    for my $stanza ( keys %{ $self->{gbconf} } ) {
        if( ref $self->{gbconf}{$stanza} eq 'HASH' ) {
            for my $key ( keys %{ $self->{gbconf}{$stanza} } ) {
                $self->convert( \%jb, $stanza, $key, $self->{gbconf}{$stanza}{$key} );
            }
        }
    }

    # convert the tracks to an array
    $jb{tracks} = [ map $jb{tracks}{$_}, keys %{$jb{tracks}} ];
#     databases -> stores
#     track defaults
#     track    -> track defaults, track

    return \%jb;
}

sub convert {
    my ( $self, $conf, $stanza, $key, $value ) = @_;
    ( my $mstanza = $stanza ) =~ s/\W/_/g;
    ( my $mkey = $key ) =~ s/\W/_/g;
    if ( $self->can( "convert_${mstanza}_${mkey}" ) ) {
        $self->${\"convert_${mstanza}_${mkey}"}( $conf, $value );
    } elsif( $self->can( "convert_$mstanza" ) ) {
        $self->${\"convert_$mstanza"}( $conf, $key, $value );
    } else {
        $self->convert_default( $conf, $stanza, $key, $value );
    }
}

sub convert_default {
    my ( $self, $conf, $stanza, $key, $value ) = @_;
    (my $mkey = $key) =~ s/\W/_/g;
    if( $self->can( "convert_track_$mkey" ) ) {
        $self->${\"convert_track_$mkey"}( $conf, $stanza, $value );
    }
}

sub convert_track_default {
    my ( $self, $conf, $track_label, $value, $key ) = @_;
    $conf->{tracks}{$track_label}{$key} = $value;
}

sub convert_track_key {
    my $self = shift;
    $self->convert_track_default( @_, 'key' );
}


1;
