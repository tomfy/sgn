use strict;
use warnings;


our @urls;
our $tests_per_url;
BEGIN {
    @urls =  ( "http://solcyc.sgn.cornell.edu",
               "http://solcyc.sgn.cornell.edu/LYCO/substring-search?type=NIL&object=carotenoid",
             );
    $tests_per_url = 3;
}

use Test::More $ENV{TEST_SOLCYC_LIVE} ? ( tests => scalar(@urls)*$tests_per_url )
                                           : ( skip_all => "set TEST_SOLCYC_LIVE=1 to test the solcyc live site" );

use Test::WWW::Mechanize;

my $mech = Test::WWW::Mechanize->new;
for my $url (@urls ) {
    $mech->get_ok( $url );
    $mech->content_like( qr/generated by SRI International/i, "i see the footer, page seems to be fully generated" );
    $mech->content_unlike( qr/timed out/i, "page did not time out");
}
