package Bio::JBrowse::GBrowseConfConverter::Track;
# ABSTRACT: base class for a converter for a GBrowse track stanza
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub convert_stanza {
    my ( $self, $targetConf, $track_label, $gbrowse ) = @_;

    my $handler = $self->glyph_handler( $gbrowse );
    if( ! $handler ) {
        warn "Warning: Not migrating track '$track_label', not capable of handling $gbrowse->{glyph} tracks.\n";
        return;
    }

    $handler->handle( $track_label, $gbrowse, $targetConf )
}

sub handle {
    my ( $self, $track_label, $gbrowse, $targetConf ) = @_;

    my %jbrowse = (
        label => $track_label,
        store => ( $gbrowse->{database} || 'default' ).':'.($gbrowse->{feature}||''),
        key   => $gbrowse->{key},
        metadata => {
            ( $gbrowse->{citation} ? ( description => $gbrowse->{citation} ) : () ),
            ( $gbrowse->{category} ? ( category => $gbrowse->{category} ) : () ),
            },
        style => {
              ( $gbrowse->{link} ? ( linkTemplate => $self->_convert_interpolation( $gbrowse->{link} ) ) : () )
            }
        );

    for my $key ( keys %$gbrowse ) {
        ( my $mkey = $key ) =~ s/\W/_/g;
        if( $self->can("handle_$mkey") ) {
            $self->${\"handle_$mkey"}( $gbrowse->{$key}, \%jbrowse );
        }
    }

    $targetConf->{tracks}{$track_label} = \%jbrowse;
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

    my $class = ref $self;
    my $handler = $self->{parent}->first_available_class(
        map { s/Bio::Graphics::Glyph/${class}/; $_ }
        $self->glyph_pedigree( $glyph_name )
    );
    return $handler;
}

sub glyph_pedigree {
    my ( $self, $glyph_name ) = @_;

    my $class = 'Bio::Graphics::Glyph::'.$glyph_name;
    my @pedigree = ( $class );
    until( $class eq 'Bio::Graphics::Glyph' ) {
        my @isa = eval "require $class; \@${class}::ISA" or last;
        push @pedigree, $class;
    }
    #warn "$glyph_name -> @pedigree\n";

    return @pedigree;
}

1;
