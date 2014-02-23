use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'Cannot read docker from mocked path' unless $ENV{PATH} and -x 't/bin/docker' and -x '/usr/bin/env';
$ENV{PATH} = "t/bin:$ENV{PATH}";

my $t = Test::Mojo->new('LivePerl');
my @output = $t->app->docker('ps');

like "@output", qr{^argv=ps$}m, 'got mocked docker output';

done_testing;
