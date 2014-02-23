package LivePerl::Sample::Params;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#GETPOST_parameters';
has description => 'All GET and POST parameters sent with the request are accessible via "param" in Mojolicious::Controller.<br>In addition, The "stash" in Mojolicious::Controller is used to pass data to templates, which can be inlined in the DATA section.';
has title => 'GET/POST Parameters';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;
 
get '/' => sub {
    my $self = shift;
 
    my $name  = $self->param("name");
    $self->render(template => "slash", name => $name);
};
 
app->start;
 
__DATA__
 
@@ slash.html.ep
Hello, world<%= stash('name') ? ": " . stash('name') : '' %>.
%= form_for "/" => begin
    Name:
    %= text_field "name"
    %= submit_button
% end
