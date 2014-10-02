use Search::Elasticsearch;
my $es = Search::Elasticsearch->new;

my $query = {
  bool => { 
    should => [
    {
      match => {
        _all => {
          query => 'pomes',
          boost => 10,
        }
      }
    },
    {
      match => {
        _all => {
          query => 'pollastre',
          boost => 10,
        }
      },
    }
  ]
  }
};

my %search_params = (
    index => 'recepta',
    type  => 'cat', 
    body  => {
        query => {
            function_score => {
                query => $query
            }
        }
    },
);
my $matches = $es->search(%search_params)->{hits}->{hits};
use Data::Dumper::Concise;
warn "Matches: ", Dumper $matches;
