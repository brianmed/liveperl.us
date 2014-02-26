#!/opt/perl

use Mojo::Base -strict;

use Mojo::JSON qw(j);
use DateTime;
use DateTime::Format::ISO8601;

my @containers = ();

my @output = `/usr/bin/docker ps`;
foreach my $line (@output) {
    if ($line =~ m#^(\S+)\s.*?0.0.0.0:80\d+->3000/tcp.*bpmedley_(\d+)#) {
        my $container = $1;
        my $unique = $2;

        my $last_edit = time - (stat("/tmp/playground-$unique/lite.pl"))[10];

        if (600 > $last_edit) {
            warn("skipping: $line: $last_edit") if $ARGV[0];
            next;
        }

        push(@containers, $container);
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
        my $minutes = $whence->in_units("minutes");

        if (10 <= $minutes) {  # remember, with the last_edit feature 10 minutes has been fine
            system("/usr/bin/docker", "stop", $container);
            # system("/usr/bin/docker", "rm", $container);
            # system("/usr/bin/docker", "rmi", $hash->[0]{Image});
        }
    }
}

@containers = ();
my @images = ();
my @output = `/usr/bin/docker ps -a`;
foreach my $line (@output) {
    if ($line =~ m#^(\S+)\s+(\S+)\s.*?Exit\s+\d+#) {
        push(@containers, $1);
        push(@images, $2);
    }
}

foreach my $container (@containers) {
    system("/usr/bin/docker", "rm", $container);
}

foreach my $image (@images) {
    next if "d5f67fd405c7" eq $image;   # our current base image
    system("/usr/bin/docker", "rmi", $image);
}
