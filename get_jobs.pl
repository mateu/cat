#!/usr/bin/env perl
use 5.014;

use utf8;
use warnings;
use warnings qw( FATAL utf8 );
use open qw(:std :utf8);
 
use Getopt::Long;
use XML::FeedPP;
use Elastijk;
use Data::UUID;

my $carregar   = 1;
my $mot_cercar = 'porros';
GetOptions(
  "carregar"     => \$carregar,
  "mot_cercar=s" => \$mot_cercar,
);

# Client minimalista d'elasticsearch
my $es = Elastijk->new(es_arguments());

corre();

###--- La terra de subroutines al dessota ---###

sub corre {
  carrega() if $carregar;
  my $resultats = cerca($mot_cercar);
  presenta($resultats);
}

sub carrega {

  my $font_de_dades    = 'http://jobs.perl.org/rss/standard.rss?limit=50';
  my $feed = XML::FeedPP->new($font_de_dades, utf8_flag => 1);
  my $ug               = Data::UUID->new;
  # Diu que bulk és possible
  foreach my $job ($feed->get_item()) {
    my $doc = fer_doc($job);

    # Fem un identificador universal que és estàtic basat en la ubicació
    my $uuid = $ug->create_from_name_str(NameSpace_URL, $doc->{url});

    # Ja hem vist aquesta recepta?
    my ($status, $response) = $es->get(id => $uuid);
    next if ($status == 200);

    # Indexa la
    $es->index(id => $uuid, body => $doc);
  }
}

sub cerca {
  my $mot = shift;
  my $cerca = { query => { match => { '_all' => $mot } }, };
  return $es->search(body => $cerca);
}

sub presenta {
  my $resultats = shift;
  foreach my $hit (@{ $resultats->{hits}{hits} }) {
    my $camps = $hit->{_source};
    print $camps->{títol}, ' : ', $camps->{url}, "\n";
  }
}


sub fer_doc {
  my $doc = shift;

  # Heus aquí el recepta (document) per indexar
  return {
    descripció  => $doc->description,
    títol                => $doc->title,
    url                  => $doc->link,
  };
}

# On posem les receptes a dins elasticsearch
sub es_arguments {
  return (
    host  => 'localhost',
    port  => 9200,
    index => 'jobs',
    type => 'perl',
  );
}
