package LivePerl::Sample::Http;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#HTTP_methods';
has description => 'Routes can be restricted to specific request methods with different keywords.';
has title => 'HTTP Methods';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;
 
get '/' => sub {
    my $self = shift;
 
    $self->render(template => "slash");
};
 
post '/' => sub {
    my $self = shift;
 
    my $name  = $self->param("name");
    $self->render(template => "slash", name => $name);
};
 
app->start;
 
__DATA__
 
@@ slash.html.ep
Hello, world<%= stash('name') ? ": " . stash('name') : '' %>.
%= form_for "/" => (method => "POST") => begin
    Name:
    %= text_field "name"
    %= submit_button
% end
