use strict;
use CXGN::Tools::File;
use CXGN::Page;
use CXGN::VHost;

my $vhost_conf=CXGN::VHost->new();
my $page=CXGN::Page->new('Secretom','john');
$page->header('Secretom');
print<<END_HTML;
<div style="width:100%; color:#303030; font-size: 1.1em; text-align:left;">

<center>
<img style="margin-bottom:10px" src="/documents/img/secretom/secretom_logo_smaller.jpg" alt="secretom logo" />
</center>

<span style="white-space:nowrap; display:block; padding:3px; background-color: #fff; text-align:center; color: #444; font-size:1.3em">
Education, Training, and Outreach Activities
</span>
<br />
<center>
<img src="/documents/img/secretom/secretom_outreach_people.jpg" />
</center>
<br /><br />

<b>Fall 2009:</b> A <a href="training.pl">workshop</a> on proteomics technologies and techniques was given at the <a href="http://www.brc.cornell.edu/brcinfo/index.php?f=2">Cornell Proteomics and Mass Spectrometry Core Facility</a> The handouts from the workshop are available online. <a href="/documents/secretom/MSOct09WorkshopHandouts.pdf">[pdf]</a></p>

<br /><br />

<b>Summer 2006:</b> The Plant Genome Research Program 
<a href="http://bti.cornell.edu/pgrp/pgrp.php?id=201">summer interns</a> 
participated in various genomics-associated activities on campus, including the 
cell wall proteomics project. This included practical lab-based 
training of students and a lecture.


</div>

END_HTML

$page->footer();
