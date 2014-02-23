package LivePerl::Sample::Helpers;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Helpers';
has description => 'You can also extend Mojolicious with your own helpers, a list of all built-in ones can be found in Mojolicious::Plugin::DefaultHelpers and Mojolicious::Plugin::TagHelpers.';
has title => 'Helpers';

1;
__DATA__
use Mojolicious::Lite;

# A helper to identify visitors
helper whois => sub {
  my $self  = shift;
  my $agent = $self->req->headers->user_agent || 'Anonymous';
  my $ip    = $self->tx->remote_address;
  return "$agent ($ip)";
};

# Use helper in template
get '/' => sub {
  my $self = shift;

  $self->render("slash");
};

app->start;

__DATA__

@@ slash.html.ep
We know who you are <%= whois %>.
