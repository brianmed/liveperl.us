package LivePerl::Sample::Stash;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Stash_and_templates';
has description => 'The "stash" in Mojolicious::Controller is used to pass data to templates, which can be inlined in the DATA section.';
has title => 'Stash and templates';

1;
__DATA__
use Mojolicious::Lite;

# Route leading to an action that renders a template
get '/' => sub {
  my $self = shift;
  $self->stash(one => 23);
  $self->render('slash', two => 24);
};

app->start;

__DATA__

@@ slash.html.ep
The magic numbers are <%= $one %> and <%= $two %>.
