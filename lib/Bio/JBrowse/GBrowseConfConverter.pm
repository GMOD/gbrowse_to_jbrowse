package Bio::JBrowse::GBrowseConfConverter;
use strict;
use warnings;

use File::Basename ();
use Text::ParseWords ();
use List::MoreUtils ();

use Bio::Graphics::FeatureFile ();

sub new {
    my ( $class ) = @_;
    return bless {
        gbconf   => {},
        includes => []
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

    $self->{complete_conf} = Bio::Graphics::FeatureFile->new( -text => $text );

    # so that we can more or less replicate the original file layout,
    # strip out includes and execs, and handle includes specially
    my @includes;
    $text =~ s/^\#include\s+(.+)/push @includes, Text::ParseWords::shellwords( $1 ); ''/egi;
    $text =~ s/^\#exec\s+([^\n]+)/warn "ignoring exec $1"; ''/egi;

    push @{ $self->{includes} }, @includes;

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
            my $handler = $self->stanza_handler( $stanza );
            $handler and $handler->convert_stanza( \%jb, $stanza, $self->{gbconf}{$stanza} );
        }
    }

    # convert the tracks to an array
    if( $jb{tracks} && %{ $jb{tracks} } ) {
        $jb{tracks} = [ map $jb{tracks}{$_}, keys %{$jb{tracks}} ];
    }

    # add the includes
    if( @{$self->{includes}} ) {
        $jb{include} = [ List::MoreUtils::uniq( $self->{includes} ) ];
    }
#     databases -> stores
#     track defaults
#     track    -> track defaults, track

    return \%jb;
}

########## conversion method dispatch #################

sub stanza_handler {
    my ( $self, $stanza ) = @_;

    # track defaults are processed in each track stanza
    return if lc $stanza eq 'track defaults';

    my @choices = $self->stanza_handler_choices( $stanza );
    unless( @choices ) {
        warn "Warning: Not migrating stanza [$stanza], there is no equivalent in JBrowse.\n";
        return;
    }
    my $handler = $self->first_available_class( @choices );
    unless( $handler ) {
        warn "Warning: Not migrating stanza [$stanza], migration tool does not yet know what to do with it.\n";
        return;
    }

    return $handler->new( parent => $self );
}

sub first_available_class {
    my ( $self, @choices ) = @_;

    #warn "looking for @choices\n";

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

    my $namespace = 'track';
    if( $stanza =~ s/:(\w+)$// ) {
        $namespace = $1;
    }
    $namespace = ucfirst lc $namespace;
    if( $namespace =~ /^\d+$/ ) {
        $namespace = 'Semantic_zoom';
    }

    return if $namespace eq 'Details' || $namespace eq 'Semantic_zoom' || $namespace eq 'Region' || $namespace eq 'Overview';

    my $class = ref $self;
    ( my $mstanza = $stanza ) =~ s/\W/_/g;

    return ( $class."::".$mstanza, $class."::".$namespace );
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
