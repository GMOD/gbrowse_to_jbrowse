use strict;
use warnings;

use Test::More;
use Test::Warn;

use_ok( 'Bio::JBrowse::GBrowseConfConverter' );
use_ok( 'Bio::JBrowse::GBrowseConfConverter::MainFile' );

{
    my $c = Bio::JBrowse::GBrowseConfConverter->new;
    $c->add_text( <<'EOT' );
[zonker]
database         = encode
feature          = signal:Berchowitz_2009
glyph            = nonexistent_glyph_type
EOT

    my $jb;
    warning_like { $jb = $c->jbrowse_conf_data;} qr/nonexistent_glyph_type/i, 'warns about not able to handle nonexistent_glyph_type';
    is_deeply( $jb, { } ) or diag explain $jb;
}

{
    my $c = Bio::JBrowse::GBrowseConfConverter->new;
    $c->add_file( 't/data/ITAG2.3_genomic.conf' );

    my $jb = $c->jbrowse_conf_data;
    #is_deeply( $jb, {  } ) or diag explain $jb;
}

{
    my $c = Bio::JBrowse::GBrowseConfConverter::MainFile->new;
    $c->add_file( 't/data/GBrowse.tomato.conf' );

    my $jb = $c->jbrowse_conf_data;
    is_deeply( $jb, { zonker => 1 } ) or diag explain $jb;
}

done_testing;
