package Bio::JBrowse::GBrowseConfConverter::Track;
# ABSTRACT: base class for a converter for a GBrowse track stanza
use strict;
use warnings;

use List::MoreUtils ();

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub convert_stanza {
    my ( $self, $targetConf, $track_label, $gbrowse ) = @_;

    # merge it with the track defaults
    my %with_defaults;
    my $complete = $self->{parent}{complete_conf};
    for my $opt ( $complete->setting( 'TRACK DEFAULTS' ) ) {
        $with_defaults{$opt} = $complete->setting( 'TRACK DEFAULTS', $opt );
    }
    %with_defaults = ( %with_defaults, %$gbrowse );

    my $handler = $self->glyph_handler( \%with_defaults );
    if( ! $handler ) {
        warn "Warning: Not migrating track [$track_label], not capable of handling $gbrowse->{glyph} tracks.\n";
        return;
    }

    $handler->handle( $track_label, \%with_defaults, $targetConf )
}

sub handle {
    my ( $self, $track_label, $gbrowse, $targetConf ) = @_;
    my $jbrowse = $self->_commonParams( $track_label, $gbrowse, $targetConf );

    for my $key ( keys %$gbrowse ) {
        ( my $mkey = $key ) =~ s/\W/_/g;
        if( $self->can("handle_$mkey") ) {
            $self->${\"handle_$mkey"}( $gbrowse->{$key}, $jbrowse );
        }
    }

    $targetConf->{tracks}{$track_label} = $jbrowse;
}

sub trim {
    return unless $_[1];
    $_[1] =~ s/^\s+|\s+$//g;
    return $_[1];
}

sub _commonParams {
    my ( $self, $track_label, $gbrowse, $targetConf ) = @_;

    my $link = $gbrowse->{link} && $self->_convert_link( $gbrowse->{link} );

    return {
        label => $track_label,
        store => ( $gbrowse->{database} || 'default' ).':'.join( ',', map {s/^"|"$//g; $_ } split /\s+/, $self->trim($gbrowse->{feature}||'') ),
        key   => $gbrowse->{key},
        metadata => {
            ( $gbrowse->{citation} ? ( description => $self->trim( $gbrowse->{citation} ) ) : () ),
            ( $gbrowse->{category} ? ( category => $self->trim( $gbrowse->{category} ) ) : () ),
            },
        style => {
              ( $link ? ( linkTemplate => $link ) : () )
            }
        };
}

sub _convert_link {
    my ( $self, $gblink ) = @_;
    $gblink = $self->trim( $gblink );

    return if ! $gblink || $gblink eq 'AUTO';

    return $self->_convert_interpolation( $gblink );
}

sub _convert_interpolation {
    my ( $self, $str ) = @_;
    $str =~ s/\$(\w+)/{$1}/g;
    return $str;
}

sub glyph_handler {
    my ( $self, $gbrowse ) = @_;
    my $glyph_name = $gbrowse->{glyph} || 'generic';
    $glyph_name = lc $glyph_name;

    eval "require Bio::Graphics::Glyph::${glyph_name}"
        or return;

    my $class = ref $self;
    my $handler = $self->{parent}->first_available_class(
        map { s/Bio::Graphics::Glyph/${class}/; $_ }
        $self->glyph_pedigree( 'Bio::Graphics::Glyph::'.$glyph_name )
    );
    return $handler;
}

sub glyph_pedigree {
    my ( $self, $class ) = @_;
    return if $class eq 'Bio::Graphics::Glyph';
    my @pedigree = ( $class );
    my @isa = eval "\@${class}::ISA" or last;
    for my $superclass ( @isa ) {
        push @pedigree, $self->glyph_pedigree( $superclass );
    }
    #warn "$glyph_name -> @pedigree\n";

    return List::MoreUtils::distinct( @pedigree );
}

1;
