package LivePerl::Index;

use Mojo::Base 'Mojolicious::Controller';

sub slash {
    my $self = shift;

    $self->render("index/slash");
}

1;
