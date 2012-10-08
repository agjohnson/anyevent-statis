#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Statis' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::Statis $AnyEvent::Statis::VERSION, Perl $], $^X" );
