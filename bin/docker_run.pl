#!/opt/perl

use Mojo::Base -strict;

my $repo = $ARGV[0];

my $unique;
my $extra = undef;

if ($repo =~ m/bpmedley/) {
    $extra = "";
    ($unique) = $repo =~ m#bpmedley_(\d+)#;
}
else {
    $extra = "code";
    ($unique) = $repo =~ m#liveperl_(\d+)_pearls#;
}

exit unless $unique;

warn($unique);

my @cmd = (
	"/usr/bin/docker",
	"run",
    "-m", 
    "70m",
    "-c",
    "15",
	"-v",
	"/tmp/playground-$unique/$extra:/playground",
    "--rm=true",
    "-t",
    "liveperl_base",
    "/src/ipc.sh"
);
system(@cmd);
