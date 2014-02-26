#!/opt/perl

use Mojo::Base -strict;

my $repo = $ARGV[0];

my ($unique) = $repo =~ m#liveperl_(\d+)_pearls#;

exit unless $unique;

my @cmd = (
	"/usr/bin/docker",
	"run",
    "-m", 
    "70m",
    "-c",
    "15",
	"-v",
	"/tmp/playground-$unique/code:/playground",
    "--rm=true",
    "-t",
    "liveperl_base",
    "/src/ipc.sh"
);
system(@cmd);
