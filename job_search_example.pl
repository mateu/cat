#!/usr/bin/env perl
use 5.014;
use utf8;

use Search::Elasticsearch;
my $es    = Search::Elasticsearch->new;
my %pesat = (
  perl        => 10,
  linux       => 10,
  javascript  => 5,
  jQuery      => 7,
  AJAX        => 5,
  MySQL       => 5,
  SQL         => 7,
  benefits    => 5,
  wellness    => 10,
  telecommute   => 100,
  catalunya   => 10,
  amsterdam   => 5,
  git         => 5,
  subversion  => -2,
  svn         => -2,
  microsoft   => -5,
  windows     => -5,
  oracle      => -5,
);

my $query = {
  bool => {
    should => [
      map { { match => { _all => { query => $_, boost => $pesat{$_}, } } } }
        keys %pesat
    ]
  }
};

my %search_params = (
  index => 'jobs',
  type  => 'perl',
  body  => {
    query => {
      function_score => {
        query => $query
      }
    }
  },
  size => 20,
);
my $matches = $es->search(%search_params)->{hits}->{hits};

foreach my $job ( @{$matches} ) {
  my $fields = $job->{_source};
  say "Title: ", $fields->{'títol'};
  say "Score: ", $job->{_score};
  say "URL: ", $fields->{url};
}
