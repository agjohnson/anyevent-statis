#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statis::Viewer' ) || print "Bail out!\n";
}

diag( "Testing Statis::Viewer $Statis::Viewer::VERSION, Perl $], $^X" );
