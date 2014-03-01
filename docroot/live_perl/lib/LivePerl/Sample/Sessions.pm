package LivePerl::Sample::Sessions;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Sessions';
has description => 'Signed cookie based sessions just work out of the box as soon as you start using them through the helper "session" in Mojolicious::Plugin::DefaultHelpers, just be aware that all session data gets serialized with Mojo::JSON.';
has title => 'Sessions';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;
 
any '/' => sub {
    my $self = shift;
 
    # We're dynamic 'yo
    my $project_name = "LivePerl";
 
    my $person = $self->session("person") || $self->param("person");
    
    $self->session(person => $person);
    $self->session->{counter}++;
    
    $self->render(template => "slash", project_name => $project_name, person => $person);
};

push(@{app->static->paths}, '/src');

app->start;
 
__DATA__
 
@@ slash.html.ep

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
            You have visited: <%== session("counter") %> times.
        </div>
      </div>

<form role="form" method="post">
  <div class="form-group">
    <label for="exampleName">Name</label>
    <input type="text" class="form-control" placeholder="Enter a person" name=person value="<%== $person %>">
  </div>
  <button type="submit" class="btn btn-default">Submit</button>
</form>
   <br>
   
      <div class="footer">
        <p>Copied 'n pasted</a></p>
        <p><a href="http://modernperlbooks.com/books/modern_perl/">Modern Perl</a></p>
        <p><a href="http://www.quora.com/Perl/What-is-modern-Perl">Quora</a></p>
      </div>

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

    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
  </body>
</html>
