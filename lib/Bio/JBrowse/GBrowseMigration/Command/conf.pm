package Bio::JBrowse::GBrowseMigration::Command::conf;
use Bio::JBrowse::GBrowseMigration -command;
use strict;
use warnings;

use File::Basename ();
use File::Spec ();

use JSON 2 ();

sub opt_spec {
    return (
        [ "main=s",  "process a main GBrowse.conf file" ],
        [ "out|o=s",  "base output directory.  Defaults to current directory.", { default => File::Spec->curdir } ],
        );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error("At least one file required.") unless @$args;

    -d $opt->{out} or die "Output directory $opt->{out} does not exist.\n";
    -w $opt->{out} or die "Output directory $opt->{out} is not writable.\n";
}

sub execute {
    my ($self, $opt, $args) = @_;

    # if we have a main gbrowse conf
    if( $opt->{gbrowse} && -f $opt->{gbrowse} ) {
        $self->convert_conf( 'Bio::JBrowse::GBrowseConfConverter::MainFile', $opt->{gbrowse}, $opt->{out} );
    }
    elsif( @$args ) {
        for my $file( @$args ) {
            $self->convert_conf( 'Bio::JBrowse::GBrowseConfConverter', $file, $opt->{out} );
        }
    }
}


sub convert_conf {
    my ( $self, $converter_class, $file, $outdir ) = @_;

    eval "require $converter_class";
    die $@ if $@;

    my $conv = $converter_class->new;
    $conv->add_file( $file );

    my $outfile = File::Spec->catfile( $outdir, File::Basename::basename( $file ).'.json' );
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
