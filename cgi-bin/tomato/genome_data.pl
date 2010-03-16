use strict;
use POSIX;

use CXGN::Page;
use CXGN::DB::Connection;

use CGI qw/-compile :standard/;


use CXGN::Cview::MapFactory;
use CXGN::Cview::Map::Tools;

use CXGN::Genomic::CloneIdentifiers qw/ assemble_clone_ident parse_clone_ident /;
use CXGN::TomatoGenome::Config;

use CXGN::ITAG::Release;
use CXGN::Page::FormattingHelpers qw/columnar_table_html modesel simple_selectbox_html tooltipped_text info_section_html info_table_html commify_number/;
use CXGN::Tools::Identifiers qw/identifier_url identifier_namespace link_identifier/;
use CXGN::Tools::List qw/max/;

my $page = CXGN::Page->new("Tomato Genome Data","rob");
my ($chrnum) = $page->get_encoded_arguments('chr');
$chrnum ||= 1;
$page->header("Tomato Genome Data","Tomato Genome Data");
#print <<HTML;
#<div style="margin: 1em" class="alert">3/27/08 15:00 GMT: The genome browser is being reloaded with new data.  For the next few hours, not all annotations may be available.</div>
#HTML

my $dbh = CXGN::DB::Connection->new();

print info_section_html( title => 'Full Datasets',
			 contents => '<a href="ftp://ftp.sgn.cornell.edu/tomato_genome">download from the Tomato Genome FTP repository</a>',
		       );

print info_section_html( title => 'Official Annotation',
			 subtitle => 'browse genome contigs and official annotations',
			 contents => <<EOH
			 <table><tr><td>The official annotation for the tomato genome is provided by the <a href="http://www.ab.wur.nl/TomatoWiki">International Tomato Annotation Group (ITAG)</a>, a multinational consortium, funded in part by the <a href="http://www.eu-sol.net">EU-SOL project</a>.</td><td><a class="footer" href="http://www.eu-sol.net"><img src="/img/eusol_logo_small.jpg" border="0" /></a></td></tr></table>
<h3 style="margin-left: -1em">Currently available genome releases</h3>
EOH
			 .itag_releases_html( $page )
		       );

print info_section_html( title => 'Physical Maps',
			 subtitle => 'locate clones on the genome',
			 contents =>
			 '<ul>'
			 .qq|<li><a href="/sequencing/agp.pl">Tomato AGP File Viewer</a> &ndash; chromosome assembly data files</li>|
			 .do {
			   my $map_factory = CXGN::Cview::MapFactory->new($dbh);
			   my %maps = ( c9  => 'clones anchored in FPC contigs from Sanger 2006 FPC build (Tomato HindIII and MboI libraries)',
					p9  => 'clones anchored with overgo, computational, or manual methods',
					13  => 'clones anchored with FISH',
					agp => 'clones anchored in manually-curated final chromosome assemblies',
				      );
			   join('',
				( map {
				  my $mid = $_;
				  my $mvid = CXGN::Cview::Map::Tools::find_current_version($dbh, $mid)
				    or die "no map_version_id found for map_id $mid\n";
				  my $m = $map_factory->create({map_version_id => $mvid})
				    or die "no map found with map_version_id $mvid\n";
				  my $sn = $m->get_short_name;
				  qq|<li><a href="/cview/map.pl?map_id=$mid">$sn</a> &ndash; $maps{$mid}</li>|;
				} sort keys %maps ),
			       )
			 }
			 .'<li><a href="/gbrowse/gbrowse/fpc_tomato_sgn_2009/">SGN 2009 FPC browser</a> &ndash; browse FPC contigs from SGN 2009 FPC build (Tomato HindIII, EcoRI, MboI, and random sheared libraries)</li>'
			 .'<li><a href="/gbrowse/gbrowse/sanger_tomato_fpc/">Sanger 2006 FPC browser</a> &ndash; browse FPC contigs from Sanger 2006 FPC build (Tomato HindIII and MboI libraries)</li>'
			 .'</ul>'
		       );

my $tg_conf = CXGN::TomatoGenome::Config->load;

print info_section_html( title => 'Clone preliminary annotations',
                         contents => do {
                             my $ftp_link  =   a( { href =>
                                                     $page->get_conf('ftpsite_url')
                                                     . '/'
                                                     . $tg_conf->{bac_publish_subdir}
                                                  },
                                                  '[FTP]'
                                                );
                             my $gb_root   = 'gbrowse/tomato_bacs/';
                             my $gb_link   = a( { href => $gb_root }, '[GBrowse]' );

                             info_table_html(
                                             Browse => "$ftp_link $gb_link",
                                             'Search Annotations' => gb_searchbox($gb_root),
                                             __multicol => 2,
                                             __border => 0,
                                            );
                         },
                       );

print qq|<a name="clones"></a>\n|;
print info_section_html( title => 'Clone sequences',
			 subtitle => 'browse and download individual genomic clone sequences',
			 contents => clone_sequences_html($dbh,$chrnum),
		       );

$page->footer();

exit;


########## SUBROUTINES #######

# given a relative URL to a gbrowse installation, generates a search
# box to search it
sub gb_searchbox {
    my ($gb_root) = @_;
    return start_form( -action => $gb_root ).textfield(-name => 'name').submit('Search','Search').end_form()
}

sub itag_releases_html {
    my ($page) = @_;

  my @releases = CXGN::ITAG::Release->find();

  my @release_rows = map {
    my $r = $_;
    my $dev = $r->is_devel_release ? '(development snapshot)' : '';
    my $pre = $r->is_pre_release ? '(pre-release)' : '';
    my $official = $dev || $pre ? '' : '(official release)';
    my $tag = $r->release_tag;
    my $dir = $r->dir_basename;
    my $conf_name = $tag.'_genomic';
    my $modtime = strftime('%b %e, %Y',gmtime($r->dir_modtime));
    my $conf_file = $r->get_file_info('gbrowse_genomic_conf');
    my $ftp_link = itag_release_ftp_link($r);
    my $gb_root = "gbrowse/$conf_name/";
    my $loading_span = span({class=>'ghosted'},'loading');
    my $gb_link   = -f $conf_file->{file} ? a({href => $gb_root},'[GBrowse]')
                                          : $loading_span;

    my $gb_search = -f $conf_file->{file} ? gb_searchbox($gb_root)
                                          : $loading_span;
    [$modtime,
     "$tag  $dev$pre$official",
     $ftp_link,
     $gb_search,
     $gb_link,
    ]
  } @releases;

  if(@release_rows) {
      return join "\n", map {
      my ($modtime,$relname, $ftp_link, $gb_search, $gb_link) = @$_;
      info_table_html(
                      Browse => "$ftp_link $gb_link",
                      'Search Annotations' => $gb_search,
                      __multicol => 2,
                      __title => table({style => 'width: 100%'},Tr(td($relname),td({style => 'text-align: right'},$modtime))),
                     ),

      } @release_rows;

  } else {
    return '<span class="ghosted">temporarily unavailable</span>'
  }
}

sub itag_release_ftp_link {
    my ($r) = @_;

    #return ghosted link if files are not world-readable
    return '<span class="ghosted" title="bulk files not publicly released">[FTP]</span>'
        unless (stat($r->get_file_info('combi_genomic_gff3')->{file}))[2] & 04;

    my $ftp_link = $r->dir;
    my $ftpsite_root = $page->get_conf('ftpsite_root');
    $ftp_link =~ s!^$ftpsite_root/*!!;
    $ftp_link = a({href=>"ftp://ftp.sgn.cornell.edu/$ftp_link"},'[FTP]');

    return $ftp_link;
}

sub clone_sequences_html {
  my ($dbh,$chrnum) = @_;

  my $names = $dbh->selectall_arrayref(<<EOQ,undef,$chrnum);
select f.name,(select dbx.accession
               from feature_dbxref fd
               join dbxref dbx using(dbxref_id)
               join db using(db_id)
               where db.name = 'DB:GenBank_Accession'
                 and fd.feature_id=f.feature_id),
       f.seqlen,
       c.clone_id
from metadata.attribution a
join metadata.attribution_to at
  using(attribution_id)
join sgn_people.sp_project p
  on( at.project_id = p.sp_project_id )
join genomic.clone c
  on(a.row_id=c.clone_id)
join clone_feature cf
  using(clone_id)
join feature f
  using(feature_id)
where p.name ilike '%Tomato% ' || ? || ' %'
order by f.name
EOQ

  #group the sequence names by clone name and version, storing in the %clones hash
  my %clones;
  foreach my $namepair (@$names) {
    my ($seqname,$acc,$seqlen,$clone_id) = @$namepair;
    my $p = parse_clone_ident($seqname,'versioned_bac_seq')
      or die "Could not parse sequence ident '$seqname'";
    delete $p->{fragment};
    my $clone_name = assemble_clone_ident(agi_bac_with_chrom => $p);
    my $clone = CXGN::Genomic::Clone->retrieve($clone_id);
    $clones{$clone_name}{$p->{version}}{seqname} = assemble_clone_ident(versioned_bac_seq => $p);
    $clones{$clone_name}{$p->{version}}{fragments} ||= [];
    $clones{$clone_name}{$p->{version}}{accession} = $acc;
    $clones{$clone_name}{$p->{version}}{seqlen}    = $seqlen;
    $clones{$clone_name}{$p->{version}}{clone}     = $clone;
    $clones{$clone_name}{$p->{version}}{phase}     = $clone->seqprops($p->{version})->{htgs_phase};
    push @{$clones{$clone_name}{$p->{version}}{fragments}}, $seqname;
  }

  #now assemble the html table rows from the grouped clone names
  my %stats; #< and keep some stats
  my @tablerows = map {
    my $clone_name = $_;
    my @versions = sort {$b <=> $a} keys %{$clones{$clone_name}};
    my $clone_seqs = $clones{$clone_name}{$versions[0]};
    my @fragnames = @{$clone_seqs->{fragments}};

    my $clone = $clone_seqs->{clone};

    #  warn 'got ns '.identifier_namespace($clone_name);
    my $details_url = identifier_url($clone_name,'bac');

    #here's the actual table row

    sub phase_html {
      my $phase = shift;
      my $pstyle = 'htg'.($phase || 'unk');
      $phase ||= '-';
      qq|<div class="$pstyle">$phase</div>|
    }

    $stats{Clones}++;


    $stats{'Phase '.($clone_seqs->{phase}||'unknown')}++;
    $stats{'Total sequenced bases'} += $clone_seqs->{seqlen};

    if (@fragnames > 1) {
      [
       qq|<a style="color: black" href="$details_url">$clone_seqs->{seqname}</a>|,
       $clone_seqs->{accession} ? link_identifier($clone_seqs->{accession},'genbank_accession') : '-',
       phase_html($clone_seqs->{phase}),
       ( qq|<form method="get" action="/gbrowse/gbrowse/tomato_bacs/">\n|
	 .simple_selectbox_html( choices  => [ [ '', '-' ],
					       sort {$a->[1] <=> $b->[1]}
					       map  {[$_,parse_clone_ident($_,'versioned_bac_seq')->{fragment}]}
					       @fragnames
					     ],
				 name     => 'ref',
				 params   => { onchange => 'submit();',
					       style => 'width: 4em',
					     },
				 label    => 'fragment',
				 selected => '',
			       )
	 .qq|<input type="hidden" name="start" value="1" />|
	 .qq|<input type="hidden" name="end" value="$clone_seqs->{seqlen}" />|
	 .qq|</form>\n|
       ),
       $details_url ? qq(&nbsp;<a href="$details_url">[details]</a>) : '',
      ]
    } else {
      [
       qq|<a style="color: black" href="$details_url">$clone_seqs->{seqname}</a>|,
       $clone_seqs->{accession} ? link_identifier($clone_seqs->{accession}) : '-',
       phase_html($clone_seqs->{phase}),
       qq(<a href="gbrowse/tomato_bacs/?ref=$fragnames[0]&start=1&end=$clone_seqs->{seqlen}">[browse]</a>),
       $details_url ? qq(&nbsp;<a href="$details_url">[details]</a>) : '',
      ]
    }
  } sort {(maxphase($clones{$b}) <=> maxphase($clones{$a})) || ($a cmp $b) } keys %clones;

  sub maxphase {		#finds the highest phase number present in a clone entry
    my ($clone_entry) = @_;
    my $maxphase =  max map $_->{phase}, values %$clone_entry;
    return $maxphase || 0;
  }

  my $seqs_and_annots_html = <<HTML
<style type="text/css">
div.htg1 {
  background: #bfbfbf;
}
div.htg2 {
  background: #b0b0e4;
}
div.htg3 {
  background: #7575ed;
}
div.htgunk {
}
</style>

<div align="center">

<h3>Chromosome</h3>
HTML
    .modesel( [ map { ["?chr=$_#clones",$_]} ('unmapped',1..12) ],
	      $chrnum eq 'unmapped' ? 0 : $chrnum,
	    )
    .do {
      $stats{'Total sequenced bases'}  = commify_number($stats{'Total sequenced bases'}) || 0;

      info_table_html( __title => ($chrnum eq 'unmapped' ? "Unmapped" : "Chromosome $chrnum")." Sequence Summary",
		       __multicol => scalar(keys %stats),
		       __tableattrs => 'style="margin-bottom: 0.6em"',
		       map {$_ => $stats{$_}} sort keys %stats,
		     )
    }
    .do {
      if (@tablerows) {
	columnar_table_html( headings     => ['SOL ID','GenBank Acc.',tooltipped_text('HTGS Phase','1: unordered fragments, 2: ordered fragments, 3: finished sequence'),'Prelim. Annot.','Clone Details'],
			     data         => \@tablerows,
			     __tableattrs => 'width="100%" cellspacing="0"',
			     __border     => 1,
			     __align      => 'lccc',
			   );
      } else {
	"<b>No sequences found.</b>\n";
      }
    }
    ."</div>";


  return $seqs_and_annots_html;

}