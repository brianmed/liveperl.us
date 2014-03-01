package LivePerl::Sample::Stash;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Stash_and_templates';
has description => 'The "stash" in Mojolicious::Controller is used to pass data to templates, which can be inlined in the DATA section.';
has title => 'Stash and templates';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;
 
get '/' => sub {
    my $self = shift;
 
    # We're dynamic 'yo
    my $project_name = "LivePerl";
    
    # These will be programmatically inserted in the template via the stash.
    my $sub_headings = [
    {
        "Flag Ship Modules" => qq(
            Using flagship modules like Moose, DBIx::Class, Catalyst, Plack, and Perl::Critic. For all but the simplest OOP scripts, Moose is the de-facto way of writing object-oriented code in Perl, versus manually blessing anonymous hashes.
        ),
    },
    {
        Relevant => qq(
            Relevant, up-to-date feedback regarding Perl's use in the modern era versus comments like "I wrote a CGI script 10 years ago and it was horrible".
        ),
    }
    ];
    
    $self->render(template => "slash", project_name => $project_name, sub_headings => $sub_headings);
};

push(@{app->static->paths}, '/src');

app->start;
 
__DATA__
 
@@ slash.html.ep

% layout "bootstrap";

<div class="row marketing">
  <div class="col-lg-6">
    <h4>Quality</h4>
    <p>A continued emphasis on well-documented, well-tested code; Using best practices like lexical file handles and three-argument open.</p>

    <h4>Errors: less is more</h4>
    <p>Using strict and warnings. What was once considered optional is no longer. The foundation of modern development starts with a much more restricted/predictable vocabulary that helps reduce developer error.</p>

    <h4>Recent Perl</h4>
    <p>Using a version of Perl greater than 5.8 and being in step with the increasing rate of change to Perl core. Perl 5.10 had a influx of new features like say, the smart match operator, and the switch statement. Perl is up to 5.18 at the time of this writing.</p>
  </div>

  <div class="col-lg-6">
    <h4>Advertising</h4>
    <p>A concerted effort to highlight Perl in social/Internet media, such as this Quora answer!.</p>

     <!-- **** NOTE the programmatic stash **** -->

     % foreach my $sub (@$sub_headings) {
     %     my ($subheading) = keys(%$sub);
     %     my ($text) = values(%$sub);
           <h4><%= $subheading %></h4>
           <p><%= $text %></p>
     % }
  </div>
</div>

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
          <li class="active"><a href="#">Home</a></li>
          <li><a href="#myModal" data-toggle="modal">About</a></li>
        </ul>
        <h3 class="text-muted"><%= $project_name %></h3>
      </div>

      <div class="jumbotron">
        <h1>Grab some Modern Perl today</h1>
        <p class="lead">Modern Perl is one way to describe the way the world's most effective Perl 5 programmers work. They use language idioms. They take advantage of the CPAN. They show good taste and craft to write powerful, maintainable, scalable, concise, and effective code.</p>
      </div>
      
      <%= content %>

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

</body>
</html>
