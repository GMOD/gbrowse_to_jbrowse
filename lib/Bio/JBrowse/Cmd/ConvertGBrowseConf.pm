package Bio::JBrowse::Cmd::ConvertGBrowseConf;
use strict;
use warnings;

use Getopt::Long ();
use Pod::Usage ();

use JSON 2 ();

use IO::Handle ();

use File::Basename ();
use File::Spec ();

use Pod::Usage;

=head1 NAME

Bio::JBrowse::Cmd::ConvertGBrowseConf - convert GBrowse configurations into JBrowse configurations

=cut

# purposely avoiding using App::Cmd or similar things, because it will
# not save me much time when balanced with the number of emails I'll
# have to deal with from people having problems installing CPAN
# modules

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->getopts( @_ );
    return $self;
}

sub getopts {
    my $self = shift;
    my $opts = {
        $self->option_defaults,
    };
    local @ARGV = @_;
    Getopt::Long::GetOptions( $opts, $self->option_definitions );
    Pod::Usage::pod2usage( -verbose => 2 ) if $opts->{help};
    $self->{argv} = [ @ARGV ];
    $self->{opt} = $opts;
}

sub opt {
    if( @_ > 2 ) {
        return $_[0]->{opt}{$_[1]} = $_[2];
    } else {
        return $_[0]->{opt}{$_[1]}
    }
}

sub argv {
    @{ shift->{argv} || [] };
}

sub option_defaults {
    ( out => File::Spec->curdir )
}
sub option_definitions {
    (
        "help|h|?",
        "gbrowse|g=s",
        "out|o=s",
        "no-recurse",
    )
}

sub run {
    my ( $self ) = @_;

    my @args = $self->argv;

    -d $self->opt('out') or die "Output directory ".$self->opt('out')." does not exist.\n";
    -w $self->opt('out') or die "Output directory ".$self->opt('out')." is not writable.\n";

    # if we have a main gbrowse conf
    if( $self->opt('gbrowse') && -f $self->opt('gbrowse') ) {
        $self->convert_conf( 'Bio::JBrowse::GBrowseConfConverter::MainFile', $self->opt('gbrowse' ) );
    }
    elsif( @args ) {
        for my $file( @args ) {
            $self->convert_conf( 'Bio::JBrowse::GBrowseConfConverter', $file );
        }
    }
    else {
        Pod::Usage::pod2usage( -verbose => 2 );
    }
}

sub convert_conf {
    my ( $self, $converter_class, $file ) = @_;

    eval "require $converter_class";
    die $@ if $@;

    my $conv = $converter_class->new;
    $conv->add_file( $file );

    my $outfile = File::Spec->catfile( $self->opt('out'), File::Basename::basename( $file ).'.json' );
    $self->write_json(
        $conv->jbrowse_conf_data,
        $outfile
        );
}

sub write_json {
    my ( $self, $data, $file ) = @_;
    open my $f, '>', $file or die "$! writing $file";
    $f->print( JSON->new->pretty->encode( $data ) );
}

1;
