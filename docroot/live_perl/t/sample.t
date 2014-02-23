use Mojo::Base -strict;
use LivePerl::Sample::Hello;
use Test::More;

my $t = LivePerl::Sample::Hello->new;

like $t->description, qr{Hello World}, 'description()';
like $t->doc_url, qr{\#Hello_World}, 'doc_url()';
like $t->title, qr{Hello World}, 'title()';
like $t->code, qr{app->start}, 'code()';

done_testing;
