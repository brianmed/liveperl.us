package LivePerl::Sample::Hello;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://mojolicio.us/perldoc/Mojolicious/Lite#Hello_World';
has description => 'A simple Hello World application can look like this, strict, warnings, utf8 and Perl 5.10 features are automatically enabled and a few functions imported when you use Mojolicious::Lite, turning your script into a full featured web application.';
has title => 'Hello World';

1;
__DATA__
#!/usr/local/bin/perl

use Mojolicious::Lite;

get '/' => sub {
    my $self = shift;

    $self->render(text => 'Hello World!');
};

app->start;
