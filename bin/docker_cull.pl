#!/opt/perl

use Mojo::Base -strict;

use Mojo::JSON qw(j);
use DateTime;
use DateTime::Format::ISO8601;

my @containers = ();

my @output = `/usr/bin/docker ps`;
foreach my $line (@output) {
    if ($line =~ m#^(\S+)\s.*?0.0.0.0:80\d+->3000/tcp#) {
        push(@containers, $1);
    }
}

my $info = "";
foreach my $container (@containers) {
    local $/;

    my $output = `/usr/bin/docker inspect $container`;

    my $hash = j($output);
    if ($hash && $hash->[0] && $hash->[0]{Created}) {
        my $dt = DateTime::Format::ISO8601->parse_datetime($hash->[0]{Created});
        my $now = DateTime->now;
        my $whence = $now - $dt;
        my $hours = $whence->in_units("hours");

        if (1 < $hours) {
            system("/usr/bin/docker", "stop", $container);
            system("/usr/bin/docker", "rm", $container);
            system("/usr/bin/docker", "rmi", $hash->[0]{Image});
        }
    }
}
