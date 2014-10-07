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
  benefits      => 'very',
  git           => 'very',
  postgresql    => 'very',
  plack         => 'very',
  'node.js'     => 'very',
  json          => 'very',
  moo           => 'very',
  moose         => 'very',
  catalyst      => 'very',
  test          => 'very',
  cpan          => 'very',
  debian          => 'very',
  ubuntu          => 'very',
  mvc          => 'somewhat',
  math          => 'somewhat',
  mojolicious   => 'somewhat',
  dancer        => 'somewhat',
  nginx         => 'somewhat',
  javascript    => 'somewhat',
  jquery        => 'somewhat',
  ajax          => 'somewhat',
  mysql         => 'somewhat',
  sql           => 'somewhat',
  agile         => 'somewhat',
  scrum         => 'somewhat',

  subversion => 'somewhat_neg',
  apache     => 'somewhat_neg',
  svn        => 'somewhat_neg',
  java       => 'somewhat_neg',
  c          => 'somewhat_neg',
  cvs        => 'very_neg',
  microsoft  => 'very_neg',
  windows    => 'very_neg',
  oracle     => 'very_neg',
  eligo      => 'mandatory_neg',
  taxsys     => 'mandatory_neg',
);

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
);
my $matches = $es->search(%search_params)->{hits}->{hits};
if ( ref($matches) and ref($matches) eq 'ARRAY' ) {
  foreach my $job ( @{$matches} ) {
    my $fields = $job->{_source};
    say "Title: ", $fields->{'títol'};
    say "Score: ", $job->{_score};
    say "URL: ",   $fields->{url};
  }
}
