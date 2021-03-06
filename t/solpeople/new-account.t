
use strict;

use File::Spec;
use Test::More tests => 15;
use Test::WWW::Mechanize;

use SGN::Config;

use CXGN::DB::Connection;
use CXGN::People::Person;

my $mech = Test::WWW::Mechanize->new();

my $server = $ENV{SGN_TEST_SERVER} or die "SGN_TEST_SERVER must be set";

my $new_account_page = $server."/solpeople/new-account.pl";

$mech->get_ok($new_account_page);

# generate an account as a first test.

my %form = ( 
	     form_name => "submit_userdata",
	     fields => { 
		 first_name => "Test",
		 last_name  => "Testman",
		 username   => "testtesttest",
		 password   => "test-pass",
		 confirm_password => "test-pass",
		 email_address => "lam87\@cornell.edu",
	     },
	     );

ok($mech->submit_form(%form), "submit form test");

$mech->content_contains("created", "Account creation test");


# generate the same account again to test if it detects duplicated usernames

$mech->get_ok($new_account_page);
ok($mech->submit_form(%form), "submit duplicate username test");

$mech->content_contains("already in use", "Duplicate username test");

# remove the user just created

my $dbh = CXGN::DB::Connection->new( { config => SGN::Config->load });

my $p_id = CXGN::People::Person->get_person_by_username($dbh, "testtesttest");
my $p = CXGN::People::Person->new($dbh, $p_id);

$p->hard_delete();


# generate an account with a password that is too short

$form{fields}->{password}="xyz";
$form{fields}->{confirm_password}="xyz";
$mech->get_ok($new_account_page);
ok($mech->submit_form(%form), "password too short form submit");
$mech->content_contains("Password is too short", "password too short message test");

# generate an account with an identical username/password

$mech->get_ok($new_account_page);
$form{fields}->{username}="testtesttest";
$form{fields}->{password}="testtesttest";
$form{fields}->{confirm_password}="testtesttest";
ok($mech->submit_form(%form), "password and username identical form submit");
$mech->content_contains("Password must not be the same as your username.");

# attempt to generate an account with mismatching password/confirm_password

$mech->get_ok($new_account_page);
$form{fields}->{password}="asecretword";
$form{fields}->{confirm_password}="anothersecretword";
ok($mech->submit_form(%form), "password mismatch form submit");
$mech->content_contains("Password and confirm password do not match.");

