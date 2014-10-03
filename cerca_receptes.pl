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
use HTML::Parse;
use HTML::FormatText;

my $carregar   = 0;
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

  # Dades sota Creative Commons \o/ moltes gràcies http://receptes.cat/
  my $font_de_dades    = 'http://receptes.cat/feed/';
  my $feed_de_receptes = XML::FeedPP->new($font_de_dades, utf8_flag => 1);
  my $ug               = Data::UUID->new;

  # Diu que bulk és possible
  foreach my $recepta ($feed_de_receptes->get_item()) {
    my $recepta_doc = fer_doc($recepta);

    # Fem un identificador universal que és estàtic basat en la ubicació
    my $uuid = $ug->create_from_name_str(NameSpace_URL, $recepta_doc->{url});

    # Ja hem vist aquesta recepta?
    my ($status, $response) = $es->get(id => $uuid);
    next if ($status == 200);

    # Indexa la
    $es->index(id => $uuid, body => $recepta_doc);
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
  my $recepta = shift;

  my $description = prep_descripció($recepta->description);

  # Heus aquí el recepta (document) per indexar
  return {
    descripció           => $description,
    descripció_original  => $recepta->description,
    categoria            => $recepta->category,
    títol                => $recepta->title,
    url                  => $recepta->link,
  };
}

sub prep_descripció {
  my $description = shift;

  $description = HTML::FormatText->new->format(parse_html($description));
  # Canviem o suprimim alguns textos innecessaris
  $description =~ s/\r+/\n/g;
  $description =~ s/\s+Seguir llegint//g;
  $description =~ s/»//g;

  return $description;
}

# On posem les receptes a dins elasticsearch
sub es_arguments {
  return (
    host  => 'localhost',
    port  => 9200,
    index => 'cat',
    type => 'recepta',
  );
}
