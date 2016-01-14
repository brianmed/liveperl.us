package LivePerl::Sample::Moosemethods;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://perldoc.perl.org/perlootut.html#Methods';
has description => q(A method is a subroutine that operates on an object. You can think of a method as the things that an object can do. If an object is a noun, then methods are its verbs (save, print, open).);
has title => 'Moose: Methods';

1;
__DATA__
#!/usr/local/bin/perl

package Point;

use Moose;
 
has 'x' => (is => 'rw', isa => 'Int');
has 'y' => (is => 'rw', isa => 'Int');
 
sub clear {  # A method
    my $self = shift;
    $self->x(0);
    $self->y(0);
}

package main;

use v5.20;
use feature qw(say);

my $point = Point->new(x => 1, y => 2);

say(sprintf("x: %s: y: %s", $point->x, $point->y));

$point->clear;

say(sprintf("x: %s: y: %s", $point->x, $point->y));
