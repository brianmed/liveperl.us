use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojo::Base -strict;

use Mojo::ByteStream 'b';
use Mojo::UserAgent;

# Extract named character references from HTML spec
my $tx = Mojo::UserAgent->new->get(
  'http://www.whatwg.org/specs/web-apps/current-work/');
b($_->at('td > code')->text . ' ' . $_->children('td')->[1]->text)->trim->say
  for $tx->res->dom('#named-character-references-table tbody > tr')->each;

1;
