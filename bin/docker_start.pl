#!/opt/perl

use Mojo::Base -strict;
use File::Copy;

my $repo = $ARGV[0];

my ($unique) = $repo =~ m#bpmedley-(\d+)#;

mkdir("/tmp/playground-$unique");
copy("/opt/liveperl.us/bin/hello.txt", "/tmp/playground-$unique/lite.pl");
my ($login,$pass,$uid,$gid) = getpwnam("mojo");
chown($uid, $gid, "/tmp/playground-$unique");
chown($uid, $gid, "/tmp/playground-$unique/lite.pl");

my @output = `/usr/bin/docker ps`;
my %ports = ();
foreach my $line (@output) {
    if ($line =~ m#0.0.0.0:(\d+)->3000#) {
        $ports{$1} = 1;
    }
}

my $port = 0;
foreach my $nbr (8000 .. 8029) {
    $port = $nbr if !$ports{$nbr};
    last if $port;
}

my @cmd = (
	"/usr/bin/docker",
	"run",
    "-m", 
    "100m",
    "-c",
    "15",
	"-v",
	"/tmp/playground-$unique:/playground",
	"-p",
	"$port:3000",
	"-d",
	$repo
);
system(@cmd);
