package LivePerl::Sample::Mooseroles;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://search.cpan.org/~ether/Moose-2.1604/lib/Moose/Manual/Roles.pod';
has description => q(A role encapsulates some piece of behavior or state that can be shared between classes. It is something that classes do. It is important to understand that roles are not classes. You cannot inherit from a role, and a role cannot be instantiated. We sometimes say that roles are consumed, either by classes or other roles.);
has title => 'Moose: Roles';

1;
__DATA__
package Breakable;

use Moose::Role;

has 'is_broken' => (
    is  => 'rw',
    isa => 'Bool',
);

sub break {
    my $self = shift;

    print "I broke\n";

    $self->is_broken(1);
}

############################
############################

package Car;

use Moose;

with 'Breakable';

############################
############################

package main;

use v5.20;

my $car = Car->new;

say($car->is_broken ? 'Busted' : 'Still working');
$car->break;
say($car->is_broken ? 'Busted' : 'Still working');

say("Breakable: ", $car->does('Breakable')); # true
