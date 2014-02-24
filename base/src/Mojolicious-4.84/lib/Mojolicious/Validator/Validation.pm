package Mojolicious::Validator::Validation;
use Mojo::Base -base;

use Carp 'croak';
use Scalar::Util 'blessed';

has [qw(csrf_token topic validator)];
has [qw(input output)] => sub { {} };

sub AUTOLOAD {
  my $self = shift;

  my ($package, $method) = split /::(\w+)$/, our $AUTOLOAD;
  croak "Undefined subroutine &${package}::$method called"
    unless blessed $self && $self->isa(__PACKAGE__);

  croak qq{Can't locate object method "$method" via package "$package"}
    unless $self->validator->checks->{$method};
  return $self->check($method => @_);
}

sub DESTROY { }

sub check {
  my ($self, $check) = (shift, shift);

  return $self unless $self->is_valid;

  my $cb    = $self->validator->checks->{$check};
  my $name  = $self->topic;
  my $input = $self->input->{$name};
  for my $value (ref $input eq 'ARRAY' ? @$input : $input) {
    next unless my $result = $self->$cb($name, $value, @_);
    return $self->error($name => [$check, $result, @_]);
  }

  return $self;
}

sub csrf_protect {
  my $self  = shift;
  my $token = $self->input->{csrf_token};
  $self->error(csrf_token => ['csrf_protect'])
    unless $token && $token eq ($self->csrf_token // '');
  return $self;
}

sub error {
  my ($self, $name) = (shift, shift);
  return $self->{error}{$name} unless @_;
  $self->{error}{$name} = shift;
  delete $self->output->{$name};
  return $self;
}

sub has_data { !!keys %{shift->input} }

sub has_error { $_[1] ? exists $_[0]{error}{$_[1]} : !!keys %{$_[0]{error}} }

sub is_valid { exists $_[0]->output->{$_[1] // $_[0]->topic} }

sub optional {
  my ($self, $name) = @_;

  my $input = $self->input->{$name};
  my @input = ref $input eq 'ARRAY' ? @$input : $input;
  $self->output->{$name} = $input
    unless grep { !defined($_) || !length($_) } @input;

  return $self->topic($name);
}

sub param {
  my ($self, $name) = @_;

  # Multiple names
  return map { scalar $self->param($_) } @$name if ref $name eq 'ARRAY';

  # List names
  return sort keys %{$self->output} unless defined $name;

  my $value = $self->output->{$name};
  my @values = ref $value eq 'ARRAY' ? @$value : ($value);
  return wantarray ? @values : $values[0];
}

sub required {
  my ($self, $name) = @_;
  return $self if $self->optional($name)->is_valid;
  return $self->error($name => ['required']);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Validator::Validation - Perform validations

=head1 SYNOPSIS

  use Mojolicious::Validator;
  use Mojolicious::Validator::Validation;

  my $validator = Mojolicious::Validator->new;
  my $validation
    = Mojolicious::Validator::Validation->new(validator => $validator);
  $validation->input({foo => 'bar'});
  $validation->required('foo')->in(qw(bar baz));
  say $validation->param('foo');

=head1 DESCRIPTION

L<Mojolicious::Validator::Validation> performs L<Mojolicious::Validator>
validation checks.

=head1 ATTRIBUTES

L<Mojolicious::Validator::Validation> implements the following attributes.

=head2 csrf_token

  my $token   = $validation->token;
  $validation = $validation->token('fa6a08...');

CSRF token.

=head2 input

  my $input   = $validation->input;
  $validation = $validation->input({foo => 'bar', baz => [123, 'yada']});

Data to be validated.

=head2 output

  my $output  = $validation->output;
  $validation = $validation->output({});

Validated data.

=head2 topic

  my $topic   = $validation->topic;
  $validation = $validation->topic('foo');

Name of field currently being validated.

=head2 validator

  my $validator = $validation->validator;
  $validation   = $validation->validator(Mojolicious::Validator->new);

L<Mojolicious::Validator> object this validation belongs to.

=head1 METHODS

L<Mojolicious::Validator::Validation> inherits all methods from L<Mojo::Base>
and implements the following new ones.

=head2 check

  $validation = $validation->check('size', 2, 7);

Perform validation check on all values of the current L</"topic">, no more
checks will be performed on them after the first one failed.

=head2 csrf_protect

  $validation = $validation->csrf_protect;

Validate C<csrf_token> and protect from cross-site request forgery.

=head2 error

  my $err     = $validation->error('foo');
  $validation = $validation->error(foo => ['custom_check']);

Get or set details for failed validation check, at any given time there can
only be one per field.

  my ($check, $result, @args) = @{$validation->error('foo')};

=head2 has_data

  my $bool = $validation->has_data;

Check if L</"input"> is available for validation.

=head2 has_error

  my $bool = $validation->has_error;
  my $bool = $validation->has_error('foo');

Check if validation resulted in errors, defaults to checking all fields.

=head2 is_valid

  my $bool = $validation->is_valid;
  my $bool = $validation->is_valid('foo');

Check if validation was successful and field has a value, defaults to checking
the current L</"topic">.

=head2 optional

  $validation = $validation->optional('foo');

Change validation L</"topic">.

=head2 param

  my @names       = $c->param;
  my $foo         = $c->param('foo');
  my @foo         = $c->param('foo');
  my ($foo, $bar) = $c->param(['foo', 'bar']);

Access validated parameters, similar to L<Mojolicious::Controller/"param">.

=head2 required

  $validation = $validation->required('foo');

Change validation L</"topic"> and make sure a value is present and not an
empty string.

=head1 AUTOLOAD

In addition to the L</"ATTRIBUTES"> and L</"METHODS"> above, you can also call
validation checks provided by L<Mojolicious::Validator> on
L<Mojolicious::Validator::Validation> objects, similar to L</"check">.

  $validation->required('foo')->size(2, 5)->like(qr/^[A-Z]/);
  $validation->optional('bar')->equal_to('foo');
  $validation->optional('baz')->in(qw(test 123));

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
