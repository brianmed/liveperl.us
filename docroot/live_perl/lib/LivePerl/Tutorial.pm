package LivePerl::Tutorial;

use Mojo::Base 'Mojolicious::Controller';

use IPC::Run qw( run timeout );
use Mojo::Util qw(slurp spurt);
use Mojo::JSON qw(j);

sub start {
    my $self = shift;
    
    $self->render();
}

sub _docker {
    my $self = shift;

    if ($self->session("image")) {
        my $image = $self->session("image");

        my $repo = "||undef|";
        my @output = qx{/usr/bin/sudo /usr/bin/docker images};
        foreach my $line (@output) {
            if ($line =~ m#^(\S+)\s.*?$image#) {
                $repo = $1;
            }
        }


        $self->app->log->debug("repo: $repo");
        @output = qx{/usr/bin/sudo /usr/bin/docker ps};
        foreach my $line (@output) {
            if ($line =~ m/$repo.*0.0.0.0:(80\d+)/) {
                return($image, $1);
            }
        }

        delete $self->session->{image};
    }

    my @output = qx{/usr/bin/sudo /usr/bin/docker ps};
    if (31 <= scalar(@output)) {
        die("No more slots<br>The max number of people using the app has been reached.<br>Please try again later.\n");
    }

    # Need a slot

    my $repo = sprintf("bpmedley-%d/mojolicious-tutorial", time);
    my @build = (
        "/usr/bin/sudo",
        "docker", "build",
        "-t", 
        $repo,
        "/opt/liveperl.us/docker"
    );
    my ($in, $out, $err) = ("", "", "");
    my $cmd = join(" ", @build);
    $self->app->log->debug($cmd);
    eval {
        run(\@build, \$in, \$out, \$err, timeout(90)) or die("error: $cmd: $!: $?\n");
    };
    if ($@) {
        die("error: run: $cmd: $@\n");
    }

    my $image = "";
    if ($out =~ m/^Successfully built (\S+)/m) {
        $image = $1;
        $self->session(image => $image);
        $self->app->log->debug("Successfully bulit $image");

        my @joy = `/usr/bin/sudo /opt/liveperl.us/bin/docker_start.pl $image 2>&1`;
        $self->app->log->debug("Joy: " . join("", @joy));

        my @output = qx{/usr/bin/sudo /usr/bin/docker ps};
        foreach my $line (@output) {
            if ($line =~ m/$repo.*0.0.0.0:(80\d+)/) {
                return($image, $1);
            }
        }
        die("Unable to run image: $image\n");
    }
    else {
        die("No container found\n");
    }
}

sub _section {
    my $self = shift;
    my $ops = shift;

    my $code = $self->param("code");
    my $section = $self->param("section");

    Mojo::IOLoop->stream($self->tx->connection)->timeout(100);

    eval {
        my ($slot, $port) = $self->_docker;
        $self->app->log->debug("slot: $slot");

        if ($code && $code =~ m/\w/) {
            spurt($code, "/tmp/playground-$slot/lite.pl");
        }
        else {
            $code = slurp("/opt/liveperl.us/data/samples/$$ops{file}.txt");
            spurt($code, "/tmp/playground-$slot/lite.pl");
        }
        $self->stash(code => $code);

        my $html = sprintf($ops->{html}, $slot, $port);
        $self->render(inline => '[% INCLUDE tutorial/template.html.tt %]', code => $code, html => $html, subtitle => $ops->{subtitle});
    };
    if ($@) {
        $self->render(inline => '[% INCLUDE tutorial/template.html.tt %]', error => $@, code => "", html => "", subtitle => $ops->{subtitle});
    }
}

sub go {
    my $self = shift;

    my $file = $self->param("file");

    my $data = slurp("/opt/liveperl.us/data/samples/$file.json");
    my $hash = j($data);

    $self->_section({
        %$hash,
        file => $file,
    });
}

1;
