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
        
    $self->render(template => "slash", project_name => $project_name, heading => "Heading");
};

push(@{app->static->paths}, '/src');  # Needed to find bootstrap and jQuery

app->start;
 
# o Try changing the Heading name.
# o How much text can you put in the "Heading text".
# * What happens when you add a new sub heading row?
 
__DATA__
 
@@ slash.html.ep

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Bootstrap core CSS -->
    <link href="/bootstrap/css/bootstrap.min.css" rel="stylesheet">

    <!-- Custom styles for this template -->
    <link href="/bootstrap/jumbotron-narrow.css" rel="stylesheet">
  </head>

  <body>
    <div class="container">
      <div class="header">
        <h3 class="text-muted"><%= $project_name %></h3>
      </div>

      <div class="jumbotron">
        <h1><%= $heading %></h1>
        <p class="lead">Heading text.</p>
      </div>
    
    <div class="row marketing">
      <div class="col-lg-6">
        <h4>Sub-heading #1</h4>
        <p>Text here.</p>

        <h4>Sub-headind: #2</h4>
        <p>More text here.</p>
    </div>

    </div> <!-- /container -->
</body>
</html>

