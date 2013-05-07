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
            $self->stanza_handler( $stanza )
                ->convert_stanza( \%jb, $stanza, $self->{gbconf}{$stanza} );
        }
    }

    # convert the tracks to an array
    $jb{tracks} = [ map $jb{tracks}{$_}, keys %{$jb{tracks}} ];
#     databases -> stores
#     track defaults
#     track    -> track defaults, track

    return \%jb;
}

########## conversion method dispatch #################

sub stanza_handler {
    my ( $self, $stanza ) = @_;

    my $handler = $self->first_available_class( $self->stanza_handler_choices( $stanza ) );

    return $handler ? $handler->new( parent => $self ) : $self;
}

sub first_available_class {
    my ( $self, @choices ) = @_;
    for my $class ( @choices ) {
        eval "require $class";
        if( $@ ) {
            warn $@ unless $@ =~ /^Can't locate/;
        } else {
            return $class;
        }
    }
    return;
}

sub stanza_handler_choices {
    my ( $self, $stanza ) = @_;
    ( my $mstanza = $stanza ) =~ s/\W/_/g;
    return ( (ref $self)."::${mstanza}", (ref $self)."::Track" );
}

sub convert_stanza {
    my ( $self, $confTarget, $stanza, $conf ) = @_;
    ( my $mstanza = $stanza ) =~ s/\W/_/g;

    for my $key ( keys %$conf ) {
        ( my $mkey = $key ) =~ s/\W/_/g;
        my $value = $conf->{$key};

        if ( $self->can( "convert_${mstanza}_${mkey}" ) ) {
            $self->${\"convert_${mstanza}_${mkey}"}( $conf, $value );
        }
        elsif( $self->can( "convert_default_$mkey" ) ) {
            $self->${\"convert_default_$mkey"}( $conf, $stanza, $value );
        }
    }
}

1;
