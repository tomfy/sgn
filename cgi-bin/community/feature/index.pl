use strict;
use CXGN::Tools::File;
use CXGN::Page;
use CXGN::VHost;
use File::Slurp qw/slurp/;
my $vhost_conf=CXGN::VHost->new();
my $documents_folder=$vhost_conf->get_conf('basepath').$vhost_conf->get_conf('documents_subdir');
my $page=CXGN::Page->new('Featured SOL Community Labs','john');
my $LABS=slurp("$documents_folder/labs.txt")||'';
$page->header();
print $LABS;
$page->footer();
