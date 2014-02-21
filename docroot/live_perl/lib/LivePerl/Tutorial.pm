package LivePerl::Tutorial;

use Mojo::Base 'Mojolicious::Controller';

use File::Temp;
use IPC::Run qw( run timeout );
use IO::Scalar;
use Mojo::Util qw(slurp spurt);

sub start {
    my $self = shift;
    
    $self->render();
}

sub _data {
    my $self = shift;
    my $section = shift;

    my $code = read_file("/opt/liveperl.us/data/samples/$section.txt") ;
    my $dump = read_file("/opt/liveperl.us/data/samples/$section.dump") ;

    return($code, $dump);
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

    my @images = `/usr/bin/sudo /usr/bin/docker images`;
    @images = sort @images;

    my $last = "";
    foreach my $image (@images) {
        # $self->app->log->debug("image: $image");
        if ($image =~ /^bpmedley-\S+-tutorial/) {
            $last = $image;
            chomp($last);
        }
    }

    my $nbr;
    if ($last) {
        $self->app->log->debug("last: $last");
        if ($last =~ m/bpmedley-(\d+)/) {
            $nbr = $1;
            $nbr =~ s#^0+##;
            ++$nbr;
        }
    }

    my $repo = "";
    if ($nbr) {
        $repo = sprintf("bpmedley-%07d/mojolicious-tutorial", $nbr);
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
            run(\@build, \$in, \$out, \$err, timeout(30)) or die("error: $cmd: $!: $?\n");
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
    else {
        die("No previous image found\n");
    }
}

sub hello {
    my $self = shift;

    my $code = $self->param("code");
    my $section = $self->param("section");

    Mojo::IOLoop->stream($self->tx->connection)->timeout(60);

    eval {
        my ($slot, $port) = $self->_docker;
        $self->app->log->debug("slot: $slot");

        if ($code && $code =~ m/\w/) {
            spurt($code, "/tmp/playground-$slot/lite.pl");
        }
        else {
            $code = slurp("/tmp/playground-$slot/lite.pl");
        }
        $self->stash(code => $code);

        my $blurb = qq(A simple Hello World application can look like this, strict, warnings, utf8 and Perl 5.10 features are automatically enabled and a few functions imported when you use Mojolicious::Lite, turning your script into a full featured web application.);
        my $subtitle = q(<a style="color: #df0019;" href=http://mojolicio.us/perldoc/Mojolicious/Lite#Hello_World>Hello World</a>);
        my $html = qq(Slot: $slot<br><a href="http://liveperl.us:$port" target=code>Live code</a><br>$blurb);
        $self->render(inline => '[% INCLUDE tutorial/template.html.tt %]', code => $code, html => $html, subtitle => $subtitle);
    };
    if ($@) {
        my $subtitle = q(<a style="color: #df0019;" href=http://mojolicio.us/perldoc/Mojolicious/Lite#Hello_World>Hello World</a>);
        $self->render(inline => '[% INCLUDE tutorial/template.html.tt %]', error => $@, code => "", html => "", subtitle => $subtitle);
    }
}

1;
