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
    my $cb = shift;

    if ($self->session("repo")) {
        my $repo = $self->session("repo");

        my @output = qx{/usr/bin/sudo /usr/bin/docker ps};
        foreach my $line (@output) {
            if ($line =~ m/^(\S+)\s+$repo.*0.0.0.0:(80\d+)/) {
                $self->stash->{_container} = $1;
                $self->stash->{_port} = $2;
                $self->stash->{_repo} = $repo;
                $cb->($self);
                return;
            }
        }

        delete $self->session->{image};
    }

    my @output = qx{/usr/bin/sudo /usr/bin/docker ps};
    if (31 <= scalar(@output)) {
        my $msg = "No more slots<br>The max number of people using the app has been reached.<br>Please try again later.\n";
        return $self->render(inline => '[% INCLUDE tutorial/template.html.tt %]', previous => 0, error => $msg, code => "", html => "", subtitle => "");
    }

    my $repo = sprintf("bpmedley-%d/mojolicious-tutorial", time . $$);
    $self->session(repo => $repo);
    # Need a slot

    my $build_it = sub {
        my $self = shift;

        my $repo = $self->session("repo");
        $self->app->log->debug($repo);
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

        if ($out =~ m/^Successfully built (\S+)/m) {
            my $image = $1;
            $self->app->log->debug("Successfully built $image");

            my @joy = `/usr/bin/sudo /opt/liveperl.us/bin/docker_start.pl $repo 2>&1`;
            $self->app->log->debug("Joy: " . join("", @joy));

            my @output = qx{/usr/bin/sudo /usr/bin/docker ps};
            foreach my $line (@output) {
                if ($line =~ m/^(\S+)\s+$repo.*0.0.0.0:(80\d+)/) {
                    my $container = $1;
                    my $port = $2;
                    $self->stash->{_container} = $container;
                    $self->stash->{_port} = $port;
                    $self->stash->{_repo} = $repo;
                    return;
                }
            }
            die("Unable to run image: $repo\n");
        }
        else {
            die("No container found\n");
        }
    };

    my $html = $self->render(partial => 1, inline => '[% INCLUDE tutorial/template.html.tt %]', progress => 1);
    $self->stash->{_previous} = 1;
    $self->write_chunk($html => sub { 
        eval {
            $build_it->($self);
            $cb->($self);
        };
        if ($@) {
            $self->app->log->debug($@);
            my $html = $self->render(partial => 1, progress => 0, inline => '[% INCLUDE tutorial/template.html.tt %]', previous => 1, error => $@, code => "", html => "", subtitle => "");
            $self->write_chunk($html => sub { $self->finish });
        }
    });
}

sub _section {
    my $self = shift->render_later;
    my $ops = shift;

    $self->stash->{_tx} = $self->tx;
    $self->stash->{_app} = $self->app;
    Mojo::IOLoop->stream($self->tx->connection)->timeout(100);

    my $cb = sub {
        my $self = shift;
        my ($repo, $port) = ($self->stash->{_repo}, $self->stash->{_port});
        my $code = $self->param("code");

        my ($unique) = $repo =~ m#bpmedley-(\d+)#;

        $self->app->log->debug("repo: $repo: unique: $unique");

        if ($code && $code =~ m/\w/) {
            spurt($code, "/tmp/playground-$unique/lite.pl");
        }
        else {
            $code = slurp("/opt/liveperl.us/data/samples/$$ops{file}.txt");
            spurt($code, "/tmp/playground-$unique/lite.pl");
        }
        $self->stash(code => $code);

        my $html = sprintf($ops->{html}, $unique, $port);
        my $output = $self->render(port => $port, partial => 1, progress => 0, inline => '[% INCLUDE tutorial/template.html.tt %]', previous => $self->stash->{_previous} // 0, code => $code, html => $html, subtitle => $ops->{subtitle});
        $self->write_chunk($output => sub { $self->finish });
    };

    $self->_docker($cb);
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

sub autosave {
    my $self = shift;

    my $code = $self->param("code");
    my $repo = $self->session("repo");

    return $self->render(json => { ret => 0 }) unless $repo;

    my ($unique) = $repo =~ m#bpmedley-(\d+)#;

    $self->app->log->debug("autosave: repo: $repo: unique: $unique");
    spurt($code, "/tmp/playground-$unique/lite.pl");

    return $self->render(json => { ret => 1 });
}

1;
