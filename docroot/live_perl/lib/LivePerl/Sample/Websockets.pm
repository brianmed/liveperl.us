package LivePerl::Sample::Websockets;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#WebSockets';
has description => 'WebSocket applications have never been this simple before. Just receive messages by subscribing to events such as "json" in Mojo::Transaction::WebSocket with "on" in Mojolicious::Controller and return them with "send" in Mojolicious::Controller.';
has title => 'WebSockets';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;

websocket '/echo' => sub {
  my $self = shift;
  $self->on(json => sub {
    my ($self, $hash) = @_;
    my @options = ("☀", "★", "☃", "☘", "♬");
    my $replace = $options[int(rand(scalar(@options)))];
    
    $hash->{msg} =~ s#♥#$replace#;
    
    $hash->{msg} = "echo: $hash->{msg}: " . scalar(localtime);
    $self->send({json => $hash});
  });
};

get '/' => sub {
    my $self = shift;
 
    # We're dynamic 'yo
    my $project_name = "LivePerl";

    $self->render(template => "slash", project_name => $project_name);
};


push(@{app->static->paths}, '/src');

app->start;

__DATA__

@@ slash.html.ep

% layout "bootstrap";

    %= javascript begin
      var ws = new WebSocket('<%= url_for('echo')->to_abs %>');
      ws.onmessage = function (event) {
        $('#echoTbl tr:last').after('<tr><td>' + JSON.parse(event.data).msg + '</td></tr>');
      };
    % end

    <script>
        $( document ).ready(function() {
        $("#echoBtn").click(function(e) {
            ws.send(JSON.stringify({msg: $("#echoTxt").val()}));
        });
        });
    </script>

@@ layouts/bootstrap.html.ep

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Narrow Jumbotron Template for Bootstrap</title>

    <!-- Bootstrap core CSS -->
    <link href="/bootstrap/css/bootstrap.min.css" rel="stylesheet">

    <!-- Custom styles for this template -->
    <link href="/bootstrap/jumbotron-narrow.css" rel="stylesheet">

    <script type="text/javascript" src="/bootstrap/js/jquery-1.11.0.min.js"></script>

    <script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>

<%= content %>

  </head>

  <body>

    <div class="container">
      <div class="header">
        <ul class="nav nav-pills pull-right">
          <li class="active"><a href="/">Home</a></li>
          <li><a href="#myModal" data-toggle="modal">About</a></li>
        </ul>
        <h3 class="text-muted"><%= $project_name %></h3>
      </div>

      <div class="jumbotron">
        <h1>Yay Perl!</h1>
        <p class="lead">We ♥ Perl.</p>
      </div>

<form class="form-inline" role="form">
  <button type="button" id="echoBtn" class="btn btn-primary">Echo</button>
  <div class="form-group">
  <label class="sr-only" for="echoTxt">Echo text</label>
    <input type="text" class="form-control" id="echoTxt" value="I ♥ Mojolicious!">
  </div>
</form>

    <br>
    
    <table class="table table-striped" id="echoTbl">
    <tr><th>Message</th></tr>
</table>

    </div> <!-- /container -->

<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">Modern Perl</h4>
      </div>
      <div class="modal-body">
        <p>We ☃ Mojolicious and Modern Perl!!</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->

</body>
</html>
