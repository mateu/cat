#!/usr/bin/env perl
use 5.014;
use utf8;
use Data::Dumper::Concise;

use Search::Elasticsearch;
my $es    = Search::Elasticsearch->new(trace_to => ['File', 'es.log']);
my %scale = (
  irrelevant    => 1,
  little        => 1.5,
  little_neg    => 0.666,
  somewhat      => 3,
  somewhat_neg  => 0.5,
  very          => 10,
  very_neg      => 0.05,
  mandatory     => 50,
  mandatory_neg => 0.001,
);
%scale = (
  irrelevant    => 1,
  little        => 1,
  little_neg    => 1,
  somewhat      => 1,
  somewhat_neg  => 1,
  very          => 1,
  very_neg      => 1,
  mandatory     => 10,
  mandatory_neg => 0.01,
);
my %profile = (
  linux       => 'mandatory',
  telecommute => 'mandatory',
  elasticsearch => 'mandatory',
  benefits    => 'very',
  git         => 'very',
  postgresql  => 'very',
  plack  => 'very',
  nginx  => 'very',
  javascript  => 'somewhat',
  jquery      => 'somewhat',
  ajax        => 'somewhat',
  mysql       => 'somewhat',
  sql         => 'somewhat',

  subversion     => 'somewhat_neg',
  svn            => 'somewhat_neg',
  java           => 'somewhat_neg',
  microsoft      => 'very_neg',
  windows        => 'very_neg',
  oracle         => 'very_neg',
);

my $query = {match_all => {}};
my $functions = [
      map {
        {
          filter => {
            bool => {
              should => [
                {terms => {'descripció' => [$_]}},
                {terms => {'títol' => [$_]}},
              ]
            }
          },
          boost_factor => $scale{$profile{$_}},
        },
      } keys %profile
];

my %search_params = (
  index => 'jobs',
  type  => 'perl',
  body  => {query => {
    function_score => {
      query => $query,
      boost_mode => 'replace',
      score_mode => 'multiply',
      functions => $functions,
    }
  }},
  #size  => 7,
  id => 'E433C08D-5785-3964-927F-32784E5338C5',
);
#my $matches = $es->explain(%search_params)->{hits}->{hits};
my $matches = $es->explain(%search_params);
warn "Explain: ", Dumper $matches;

#foreach my $job (@{$matches}) {
#  my $fields = $job->{_source};
#  say "Title: ", $fields->{'títol'};
#  say "Score: ", $job->{_score};
#  say "URL: ",   $fields->{url};
#}
