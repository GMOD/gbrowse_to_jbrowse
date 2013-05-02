use strict;
use warnings;

use Test::More;

use_ok( 'Bio::JBrowse::GBrowseConfConverter' );

my $c = Bio::JBrowse::GBrowseConfConverter->new;
$c->add_text( <<EOT );
[foobar]
key = noggin
glyph = generic
EOT

my $jb = $c->jbrowse_conf_data;
is_deeply( $jb, {} ) or diag explain $jb;

done_testing;
