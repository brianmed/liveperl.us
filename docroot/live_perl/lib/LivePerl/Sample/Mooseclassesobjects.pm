package LivePerl::Sample::Mooseclassesobjects;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://perldoc.perl.org/perlootut.html#Object';
has description => q(An object is a data structure that bundles together data and subroutines which operate on that data. An object's data is called attributes, and its subroutines are called methods. An object can be thought of as a noun (a person, a web service, a computer).<br>&nbsp;<br>A class defines the behavior of a category of objects. A class is a name for a category (like "File"), and a class also defines the behavior of objects in that category.);
has title => 'Moose: Objects and Classes';

1;
__DATA__
#!/usr/local/bin/perl

package Point;  # A Class

use Moose;
 
has 'x' => (is => 'rw', isa => 'Int');
has 'y' => (is => 'rw', isa => 'Int');
 
package main;

use v5.20;
use feature qw(say);

my $point = Point->new(x => 1, y => 2);  # $point is the Object

say(sprintf("x: %s: y: %s", $point->x, $point->y));
