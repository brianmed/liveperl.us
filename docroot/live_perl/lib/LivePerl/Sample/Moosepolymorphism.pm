package LivePerl::Sample::Moosepolymorphism;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://perldoc.perl.org/perlootut.html#Polymorphism';
has description => q(Polymorphism is a fancy way of saying that objects from two different classes share an API. For example, we could have File and WebPage classes which both have a print_content() method. This method might produce different output for each class, but they share a common interface.
<br><br>
While the two classes may differ in many ways, when it comes to the print_content() method, they are the same. This means that we can try to call the print_content() method on an object of either class, and we don't have to know what class the object belongs to!
<br><br>
Polymorphism is one of the key concepts of object-oriented design.);
has title => 'Moose: Polymorphism';

1;
__DATA__
#!/usr/local/bin/perl

package Person;
use Moose;

use v5.20;

sub speak {
    say("I am human");
}

############################
############################

package User;

use v5.20;

use Moose;
extends 'Person';

sub speak {
    say("I am important");
}

############################
############################

package main;

use v5.20;

my $person = Person->new;
my $user = User->new;

foreach my $obj ($person, $user) {
    $obj->speak;
    say("-==========-") unless $obj == $user;
}
