package LivePerl::Sample::Placeholders;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Placeholders';
has description => 'Route placeholders allow capturing parts of a request path until a / or . separator occurs, results are accessible via "stash" in Mojolicious::Controller and "param" in Mojolicious::Controller.';
has title => 'Placeholders';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;
 
get '/' => sub {
    my $self = shift;
 
    my $name  = $self->param("name");
    $self->render(template => "slash", name => $name, extra => "");
};
 
get '/:name' => sub {
    my $self = shift;
 
    my $name  = $self->param("name");
    $self->render(template => "slash", name => $name, extra => " ... via placeholder");
};
 
app->start;
 
__DATA__
 
@@ slash.html.ep
Hello, world<%= stash('name') ? ": " . stash('name') . stash('extra') : '' %>.
%= form_for "/" => begin
    Name:
    %= text_field "name"
    %= submit_button
% end
<%= tag a => (href => "/" . stash("name")) => begin %><%= stash("name") %><% end %>
