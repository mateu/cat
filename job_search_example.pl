#!/usr/bin/env perl
use 5.014;
use utf8;

use Search::Elasticsearch;
my $es    = Search::Elasticsearch->new;
my %pesat = (
  perl        => 10,
  linux       => 10,
  catalunya   => 10,
  javascript  => 5,
  jQuery      => 7,
  AJAX        => 5,
  MySQL       => 5,
  SQL         => 7,
  benefits    => 5,
  wellness    => 10,
  'laid-back' => 5,
  amsterdam   => 5,
);

my $query = {
  bool => {
    should => [
      {
        match => {
          _all => {
            query => 'javascript',
            boost => 10,
          }
        }
      },
      {
        match => {
          _all => {
            query => 'perl',
            boost => 10,
          }
        },
      }
    ]
  }
};

$query = {
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
);
my $matches = $es->search(%search_params)->{hits}->{hits};

foreach my $job ( @{$matches} ) {
  my $fields = $job->{_source};
  say "Title: ", $fields->{'títol'};
  say "Score: ", $job->{_score};
}
