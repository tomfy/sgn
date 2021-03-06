#!/usr/bin/perl -wT

=head1 DESCRIPTION
A script for downloading population 
genotype raw data in tab delimited format.

=head1 AUTHOR(S)

Isaak Y Tecle (iyt2@cornell.edu)

=cut

use strict;

use CXGN::DB::Connection;
use CXGN::Phenome::Population;
use CXGN::Scrap;
use Cache::File;

my $scrap = CXGN::Scrap->new();
my $dbh   = CXGN::DB::Connection->new();

my %args = $scrap->get_all_encoded_arguments();
my $population_id = $args{population_id};

my $pop = CXGN::Phenome::Population->new( $dbh, $population_id );
my $name = $pop->get_name();

print
"Pragma: \"no-cache\"\nContent-Disposition:filename=genotype_data_${population_id}.txt\nContent-type:application/data\n\n";


my $g_file = $pop->genotype_file($c);

if (-e $g_file) {
    print "Genotype data for $name\n\n\n";
 
    open my $f, "<$g_file" or die "can't open file $g_file: $!\n";
    my $markers  = <$f>;
    my $linkages = <$f>;
    my $pos      = <$f>;
    foreach my $row ($markers, $linkages, $pos) {
	$row =~ s/,/\t/g;
	print $row;
    } 

### genotype code substitution needs to be modified when QTL analysis 
### is enabled for 4-way cross population

    while (my $genotype=<$f>) {
	$genotype =~ s/,1/\ta/g;
	$genotype =~ s/,2/\th/g;
	$genotype =~ s/,3/\tb/g;
	$genotype =~ s/,4/\td/g;
	$genotype =~ s/,5/\tc/g;
	$genotype =~ s/,NA/\tNA/g;
    
	print "$genotype";
    }

}
else {
    print "Genotype file for this population is not cached 
           or does not exist!\n";
}


