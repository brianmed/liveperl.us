package LivePerl::Sample::Mooseinheritance;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://perldoc.perl.org/perlootut.html#Inheritance';
has description => q(Inheritance lets you create a specialized version of an existing class. Inheritance lets the new class reuse the methods and attributes of another class.);
has title => 'Moose: Inheritance';

1;
__DATA__
package Point;
use Moose;

use feature qw(say);

has 'x' => (is => 'rw', isa => 'Int');
has 'y' => (is => 'rw', isa => 'Int');

sub output {
    my $self = shift;

    say(sprintf("x: %d, y: %d", $self->x, $self->y));
}

sub clear {
    my $self = shift;
    $self->x(0);
    $self->y(0);
}

############################
############################

package Point3D;
use Moose;

use feature qw(say);

extends 'Point';

has 'z' => (is => 'rw', isa => 'Int');

sub output {
    my $self = shift;

    say(sprintf("x: %d, y: %d: z: %z", $self->x, $self->y, $self->z));
}

after 'clear' => sub {
    my $self = shift;
    $self->z(0);
}

############################
############################

package main;

use v5.20;
use feature qw(say);

my $point = Point->new(ssn => '123456789');
my $point3d = Point3d->new(ssn => '123456789', username => "Bilbert");

foreach my $obj ($person, $user) {
    say("ssn: ", $obj->ssn);
    say("username: ", $obj->ssn) if $obj->can("username");
    say("-==========-") unless $obj == $user;
};
