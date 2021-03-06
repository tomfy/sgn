package SGN::View::Feature;
use base 'Exporter';
use strict;
use warnings;
use SGN::Context;

our @EXPORT_OK = qw/
    related_stats feature_table gbrowse_link
    get_reference gbrowse_image_url feature_link
/;
our $c = SGN::Context->new;

sub get_reference {
    my ($feature) = @_;
    my $fl = $feature->featureloc_features->single;
    return unless $fl;
    return $fl->srcfeature;
}

sub related_stats {
    my ($features) = @_;
    my $stats = { };
    my $total = scalar @$features;
    for my $f (@$features) {
            $stats->{$f->type->name}++;
    }
    my $data = [ ];
    for my $k (sort keys %$stats) {
        push @$data, [ $k => $stats->{$k} ];
    }
    push @$data, [ "Total" => $total ];
    return $data;
}

sub feature_table {
    my ($features) = @_;
    my $data = [];
    for my $f (@$features) {
        my @locations = $f->featureloc_features->all;

        # Add a row for every featureloc
        for my $loc (@locations) {
            my ($srcfeature) = $loc->srcfeature;
            my ($fmin,$fmax) = ($loc->fmin, $loc->fmax);
            push @$data, [
                $c->render_mason(
                    "/feature/link.mas",
                    feature => $f,
                ),
                $f->type->name,
                gbrowse_link($f,$fmin,$fmax),
                $fmax-$fmin . " bp",
                $loc->strand == 1 ? '+' : '-',
                $loc->phase,
                $loc->rank,
            ];
        }
    }
    return $data;
}

sub gbrowse_image_url {
    my ($feature) = @_;
    return _gbrowse_xref($feature,'preview_image_url');
}

sub _feature_search_string {
    my ($feature) = @_;
    my ($fl) = $feature->featureloc_features;
    return '' unless $fl;
    return $fl->srcfeature->name . ':'. $fl->fmin . '..' . $fl->fmax;
}

sub _gbrowse_xref {
    my ($feature, $xref_name) = @_;
    my $gb = $c->enabled_feature('gbrowse2');
    return '' unless $gb;
    # TODO: multiple
    my ($xref) = map { $_->$xref_name } $gb->xrefs($feature->name);
    unless ( $xref ) {
        ($xref) = map { $_->$xref_name } $gb->xrefs(_feature_search_string($feature));
    }
    return $xref;

}
sub gbrowse_link {
    my ($feature, $fmin, $fmax) = @_;
    my $url = _gbrowse_xref($feature,'url');
    if (defined $fmin && defined $fmax) {
        return sprintf('<a href="%s">%s</a>', $url, join(",", $fmin, $fmax)),
    } else {
        return $url;
    }
}

sub feature_link {
    my ($feature) = @_;
    my ($id, $name) = ($feature->feature_id, $feature->name);
    return qq{<a href="/cgi-bin/feature.pl?id=$id">$name</a>};
}

1;
