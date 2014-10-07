#!/usr/bin/env perl
use 5.014;
use utf8;
use Data::Dumper::Concise;

use Search::Elasticsearch;
my $es = Search::Elasticsearch->new( trace_to => [ 'File', 'es.log' ] );
my %scale = (
  irrelevant    => 1,
  little        => 1.5,
  little_neg    => 0.666,
  somewhat      => 3,
  somewhat_neg  => 0.5,
  very          => 10,
  very_neg      => 0.05,
  mandatory     => 50,
  mandatory_neg => 0,
);
my %profile = (
  linux         => 'mandatory',
  telecommute   => 'mandatory',
  elasticsearch => 'mandatory',
  moo        => 'very',
  mysql  => 'somewhat',
  cvs        => 'very_neg',
);

my $id            = '9A188682-1C27-3EE1-A287-748C5FA815F0';
my $query       = { match_all => {} };
my $functions = [
  map {
    {
      filter => {
        bool => {
          should => [
            { terms => { 'títol'      => [$_] } },
            { terms => { 'descripció' => [$_] } },
          ]
        }
      },
      boost_factor => $scale{ $profile{$_} },
    },
  } keys %profile
];

my %search_params = (
  index => 'jobs',
  type  => 'perl',
  body  => {
    query => {
      function_score => {
        query      => $query,
        boost_mode => 'replace',
        score_mode => 'multiply',
        functions  => $functions,
      }
    }
  },

    id => $id,
);
my $matches = $es->explain(%search_params);
warn "Explain: ", Dumper $matches;

