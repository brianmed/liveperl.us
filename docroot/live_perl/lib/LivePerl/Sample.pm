package LivePerl::Sample;

=head1 NAME

LivePerl::Sample - Code sample container

=head1 DESCRIPTION

This is a superclass for all modules in the L<LivePerl::Sample> namespace.

=cut

use Mojo::Base -base;

my %TEMPLATES;

=head1 ATTRIBUTES

=head2 doc_url

Holds an url back to where you can read more about the template.

=head2 description

Holds a description for this template.

=head2 title

Holds the title of this template.

=head2 code

Returns the template code.

=cut

sub code {
  my $self = shift;
  my $class = ref $self || $self;

  no strict 'refs';
  $TEMPLATES{$class} ||= do {
    my $FH = *{"${class}::DATA"};
    local $/;
    readline $FH;
  };
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
