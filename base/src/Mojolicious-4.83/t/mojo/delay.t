use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;

# Basic functionality
my $delay = Mojo::IOLoop::Delay->new;
my @results;
for my $i (1, 1) {
  my $end = $delay->begin;
  Mojo::IOLoop->timer(0 => sub { push @results, $i; $end->() });
}
my $end  = $delay->begin;
my $end2 = $delay->begin;
$end->();
$end2->();
is_deeply [$delay->wait], [], 'no return values';
is_deeply \@results, [1, 1], 'right results';

# Arguments
$delay = Mojo::IOLoop::Delay->new;
my $result;
$delay->on(finish => sub { shift; $result = [@_] });
for my $i (1, 2) {
  my $end = $delay->begin(0);
  Mojo::IOLoop->timer(0 => sub { $end->($i) });
}
is_deeply [$delay->wait], [1, 2], 'right return values';
is_deeply $result, [1, 2], 'right results';

# Scalar context
$delay = Mojo::IOLoop::Delay->new;
for my $i (1, 2) {
  my $end = $delay->begin(0);
  Mojo::IOLoop->timer(0 => sub { $end->($i) });
}
is scalar $delay->wait, 1, 'right return value';

# Steps
my $finished;
$result = undef;
$delay  = Mojo::IOLoop::Delay->new;
$delay->on(finish => sub { $finished++ });
$delay->steps(
  sub {
    my $delay = shift;
    my $end   = $delay->begin;
    $delay->begin->(3, 2, 1);
    Mojo::IOLoop->timer(0 => sub { $end->(1, 2, 3) });
  },
  sub {
    my ($delay, @numbers) = @_;
    my $end = $delay->begin;
    Mojo::IOLoop->timer(0 => sub { $end->(undef, @numbers, 4) });
  },
  sub {
    my ($delay, @numbers) = @_;
    $result = \@numbers;
  }
);
is_deeply [$delay->wait], [2, 3, 2, 1, 4], 'right return values';
is $finished, 1, 'finish event has been emitted once';
is_deeply $result, [2, 3, 2, 1, 4], 'right results';

# End chain after first step
($finished, $result) = ();
$delay = Mojo::IOLoop::Delay->new;
$delay->on(finish => sub { $finished++ });
$delay->steps(sub { $result = 'success' }, sub { $result = 'fail' });
is_deeply [$delay->wait], [], 'no return values';
is $finished, 1,         'finish event has been emitted once';
is $result,   'success', 'right result';

# End chain after third step
($finished, $result) = ();
$delay = Mojo::IOLoop::Delay->new;
$delay->on(finish => sub { $finished++ });
$delay->steps(
  sub { Mojo::IOLoop->timer(0 => shift->begin) },
  sub {
    $result = 'fail';
    shift->begin->();
  },
  sub { $result = 'success' },
  sub { $result = 'fail' }
);
is_deeply [$delay->wait], [], 'no return values';
is $finished, 1,         'finish event has been emitted once';
is $result,   'success', 'right result';

# End chain after second step
@results = ();
$delay   = Mojo::IOLoop::Delay->new;
$delay->on(finish => sub { shift; push @results, [@_] });
$delay->steps(
  sub { shift->begin(0)->(23) },
  sub { shift; push @results, [@_] },
  sub { push @results, 'fail' }
);
is_deeply [$delay->wait], [23], 'right return values';
is_deeply \@results, [[23], [23]], 'right results';

# Finish steps with event
$result = undef;
$delay  = Mojo::IOLoop::Delay->new;
$delay->on(
  finish => sub {
    my ($delay, @numbers) = @_;
    $result = \@numbers;
  }
);
$delay->steps(
  sub {
    my $delay = shift;
    my $end   = $delay->begin;
    Mojo::IOLoop->timer(0 => sub { $end->(1, 2, 3) });
  },
  sub {
    my ($delay, @numbers) = @_;
    my $end = $delay->begin;
    Mojo::IOLoop->timer(0 => sub { $end->(undef, @numbers, 4) });
  }
);
is_deeply [$delay->wait], [2, 3, 4], 'right return values';
is_deeply $result, [2, 3, 4], 'right results';

# Nested delays
($finished, $result) = ();
$delay = Mojo::IOLoop->delay(
  sub {
    my $first = shift;
    $first->on(finish => sub { $finished++ });
    my $second = Mojo::IOLoop->delay($first->begin);
    Mojo::IOLoop->timer(0 => $second->begin);
    Mojo::IOLoop->timer(0 => $first->begin);
    my $end = $second->begin(0);
    Mojo::IOLoop->timer(0 => sub { $end->(1, 2, 3) });
  },
  sub {
    my ($first, @numbers) = @_;
    $result = \@numbers;
    my $end = $first->begin;
    $first->begin->(3, 2, 1);
    my $end2 = $first->begin(0);
    my $end3 = $first->begin(0);
    $end2->(4);
    $end3->(5, 6);
    $end->(1, 2, 3);
    $first->begin(0)->(23);
  },
  sub {
    my ($first, @numbers) = @_;
    push @$result, @numbers;
  }
);
is_deeply [$delay->wait], [2, 3, 2, 1, 4, 5, 6, 23], 'right return values';
is $finished, 1, 'finish event has been emitted once';
is_deeply $result, [1, 2, 3, 2, 3, 2, 1, 4, 5, 6, 23], 'right results';

# Exception in first step
my $failed;
($finished, $result) = ();
$delay = Mojo::IOLoop::Delay->new;
$delay->on(error => sub { $failed = pop });
$delay->on(finish => sub { $finished++ });
$delay->steps(sub { die 'First step!' }, sub { $result = 'failed' });
is_deeply [$delay->wait], [], 'no return values';
like $failed, qr/^First step!/, 'right error';
ok !$finished, 'finish event has not been emitted';
ok !$result,   'no result';

# Exception in last step
($failed, $finished) = ();
$delay = Mojo::IOLoop::Delay->new;
$delay->on(error => sub { $failed = pop });
$delay->on(finish => sub { $finished++ });
$delay->steps(sub { Mojo::IOLoop->timer(0 => shift->begin) },
  sub { die 'Last step!' });
is scalar $delay->wait, undef, 'no return value';
like $failed, qr/^Last step!/, 'right error';
ok !$finished, 'finish event has not been emitted';

# Exception in second step
($failed, $finished, $result) = ();
$delay = Mojo::IOLoop::Delay->new;
$delay->on(error => sub { $failed = pop });
$delay->on(finish => sub { $finished++ });
$delay->steps(
  sub { Mojo::IOLoop->timer(0 => shift->begin) },
  sub { die 'Second step!' },
  sub { $result = 'failed' }
);
$delay->wait;
like $failed, qr/^Second step!/, 'right error';
ok !$finished, 'finish event has not been emitted';
ok !$result,   'no result';

# Exception in second step (with active event)
($failed, $finished, $result) = ();
$delay = Mojo::IOLoop::Delay->new;
$delay->on(error => sub { $failed = pop });
$delay->on(finish => sub { $finished++ });
$delay->steps(
  sub { Mojo::IOLoop->timer(0 => shift->begin) },
  sub {
    Mojo::IOLoop->timer(0 => sub { Mojo::IOLoop->stop });
    Mojo::IOLoop->timer(0 => shift->begin);
    die 'Second step!';
  },
  sub { $result = 'failed' }
);
Mojo::IOLoop->start;
like $failed, qr/^Second step!/, 'right error';
ok !$finished, 'finish event has not been emitted';
ok !$result,   'no result';

# Fatal exception in second step
Mojo::IOLoop->singleton->reactor->unsubscribe('error');
$delay = Mojo::IOLoop::Delay->new;
ok !$delay->has_subscribers('error'), 'no subscribers';
$delay->steps(sub { Mojo::IOLoop->timer(0 => shift->begin) },
  sub { die 'Oops!' });
eval { $delay->wait };
like $@, qr/Oops!/, 'right error';

done_testing();
