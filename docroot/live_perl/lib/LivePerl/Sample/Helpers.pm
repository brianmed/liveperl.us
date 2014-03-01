package LivePerl::Sample::Helpers;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Helpers';
has description => 'You can also extend Mojolicious with your own helpers, a list of all built-in ones can be found in Mojolicious::Plugin::DefaultHelpers and Mojolicious::Plugin::TagHelpers.';
has title => 'Helpers';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;

# A helper to identify visitors
helper whois => sub {
  my $self  = shift;
  my $agent = $self->req->headers->user_agent || 'Anonymous';
  my $ip    = $self->tx->remote_address;
  return "$agent ($ip)";
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

<!-- Note the whois in the <p> -->

<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">Modern Perl</h4>
      </div>
      <div class="modal-body">
        <p>We ☃ Mojolicious and Modern Perl!!</p>
        <p><%= whois %></p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->

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
        <h1>Grab some Modern Perl today</h1>
        <p class="lead">Modern Perl is one way to describe the way the world's most effective Perl 5 programmers work. They use language idioms. They take advantage of the CPAN. They show good taste and craft to write powerful, maintainable, scalable, concise, and effective code.</p>
      </div>

      <div class="row marketing">
        <div class="col-lg-6">
            <h3>Try clicking about.</h3>
        </div>
      </div>

      <div class="footer">
        <p>Copied 'n pasted</a></p>
        <p><a href="http://modernperlbooks.com/books/modern_perl/">Modern Perl</a></p>
        <p><a href="http://www.quora.com/Perl/What-is-modern-Perl">Quora</a></p>
      </div>

    </div> <!-- /container -->

    <%= content %>

    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
  </body>
</html>
