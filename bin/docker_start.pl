#!/opt/perl

use File::Copy;

my $image = $ARGV[0];

mkdir("/tmp/playground-$image");
copy("/opt/liveperl.us/data/samples/hello.txt", "/tmp/playground-$image/lite.pl");
my ($login,$pass,$uid,$gid) = getpwnam("mojo");
chown($uid, $gid, "/tmp/playground-$image");
chown($uid, $gid, "/tmp/playground-$image/lite.pl");

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
	"/tmp/playground-$image:/playground",
	"-p",
	"$port:3000",
	"-d",
	$image
);
system(@cmd);
