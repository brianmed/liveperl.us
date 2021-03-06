package LivePerl::Sample::Params;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#GETPOST_parameters';
has description => 'All GET and POST parameters sent with the request are accessible via "param" in Mojolicious::Controller.<br>In addition, The "stash" in Mojolicious::Controller is used to pass data to templates, which can be inlined in the DATA section.<br>Also, routes can be restricted to specific request methods with different keywords. Note the "any" for GET and POST.';
has title => 'GET/POST Parameters';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;
 
any '/' => sub {
    my $self = shift;
 
    # We're dynamic 'yo
    my $project_name = "LivePerl";

    my ($email, $password) = $self->param(["email", "password"]);
    
    my $submitted = 0;
    if ($email || $password) {
        $submitted = 1;
    }
    
    $self->render(template => "slash", project_name => $project_name, email => $email, password => $password, submitted => $submitted);
};

push(@{app->static->paths}, '/src');

app->start;

# o Try changing the placeholder text for either Email or Passsword
# o Did you find the easter egg: hint it's About the password.
# * Can you change the visual feedback when a form submits?

# This template uses layouts.  A layout allows us to wrap generated 
# content into a HTML skeleton.

__DATA__
 
@@ slash.html.ep

% layout "bootstrap";

<!-- See how we use $email and $password -->

% if ($submitted) {
<kbd>Submitted</kbd>
% }

<form role="form" method="post">
  <div class="form-group">
    <label for="exampleInputEmail1">Email address</label>
    <input type="email" class="form-control" placeholder="Enter email" name=email value="<%== $email %>">
  </div>
  <div class="form-group">
    <label for="exampleInputPassword1">Password</label>
    <input type="password" class="form-control" placeholder="Password" name=password value="<%== $password %>">
  </div>
  <button type="submit" class="btn btn-default">Submit</button>
</form>

@@ layouts/bootstrap.html.ep

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

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
          <li class="active"><a href="#">Home</a></li>
          <li><a href="#myModal" data-toggle="modal">About</a></li>
        </ul>
        <h3 class="text-muted"><%= $project_name %></h3>
      </div>

      <div class="jumbotron">
        <h1>Yay Perl!</h1>
        <p class="lead">We ♥ Perl.</p>
      </div>

      <%= content %>

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
        <p><%== $password %></p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->

</body>
</html>
