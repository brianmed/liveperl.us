package LivePerl::Sample::Websockets;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#WebSockets';
has description => 'WebSocket applications have never been this simple before. Just receive messages by subscribing to events such as "json" in Mojo::Transaction::WebSocket with "on" in Mojolicious::Controller and return them with "send" in Mojolicious::Controller.';
has title => 'WebSockets';

1;
__DATA__
use Mojolicious::Lite;

websocket '/echo' => sub {
  my $self = shift;
  $self->on(json => sub {
    my ($self, $hash) = @_;
    $hash->{msg} = "echo: $hash->{msg}";
    $self->send({json => $hash});
  });
};

get '/' => 'index';

app->start;
__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Echo</title>
    %= javascript begin
      var ws = new WebSocket('<%= url_for('echo')->to_abs %>');
      ws.onmessage = function (event) {
        document.body.innerHTML += JSON.parse(event.data).msg;
      };
      ws.onopen = function (event) {
        ws.send(JSON.stringify({msg: 'I ♥ Mojolicious!'}));
      };
    % end
  </head>
</html>
