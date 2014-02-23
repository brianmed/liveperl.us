package LivePerl::Sample::Sessions;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Sessions';
has description => 'Signed cookie based sessions just work out of the box as soon as you start using them through the helper "session" in Mojolicious::Plugin::DefaultHelpers, just be aware that all session data gets serialized with Mojo::JSON.';
has title => 'Sessions';

1;
__DATA__
use Mojolicious::Lite;

# Access session data in action and template
get '/' => sub {
  my $self = shift;
  $self->session->{counter}++;
  $self->render("slash");
};

app->start;
__DATA__

@@ slash.html.ep
Counter: <%= session 'counter' %>
