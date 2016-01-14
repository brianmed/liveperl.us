package LivePerl::Sample::Mooseattributes;
use Mojo::Base 'LivePerl::Sample';

has doc_url => 'http://search.cpan.org/dist/Moose/lib/Moose/Manual/Attributes.pod';
has description => q(Moose attributes have many properties, and attributes are probably the single most powerful and flexible part of Moose. You can create a powerful class simply by declaring attributes. In fact, it's possible to have classes that consist solely of attribute declarations.
<br><br>
An attribute is a property that every member of a class has. For example, we might say that "every Person object has a first name and last name". Attributes can be optional, so that we can say "some Person objects have a social security number (and some don't)".
<br><br>
At its simplest, an attribute can be thought of as a named value (as in a hash) that can be read and set. However, attributes can also have defaults, type constraints, delegation and much more.);
has title => 'Moose: Attributes';

1;
__DATA__
#!/usr/local/bin/perl

package Person;

use Moose;

has 'ssn' => (
    is        => 'rw',
    clearer   => 'clear_ssn',
    predicate => 'has_ssn',
);

package main;

use v5.20;
use feature qw(say);

my $person = Person->new();
printIt(__LINE__, $person->has_ssn);

$person->ssn(undef);
printIt(__LINE__, $person->ssn);
printIt(__LINE__, $person->has_ssn);

$person->clear_ssn;
printIt(__LINE__, $person->ssn);
printIt(__LINE__, $person->has_ssn);

$person->ssn('123-45-6789');
printIt(__LINE__, $person->ssn);
printIt(__LINE__, $person->has_ssn);

my $person2 = Person->new( ssn => '111-22-3333');
printIt(__LINE__, $person2->has_ssn);

sub printIt {
    my $line = shift;
    my $hrmm = shift;

    if (!defined $hrmm) {
        say("$line: not defined");
    }
    else {
        say("$line: '$hrmm'");
    }
}
