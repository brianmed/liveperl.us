package LivePerl::Tutorial;

use Mojo::Base 'Mojolicious::Controller';

use File::Path qw(make_path);
use File::Copy qw(copy);
use Mojo::Util qw(spurt slurp);
use Mojo::JSON qw(j);

use Encode qw(encode decode);

has sample => sub {
  my $self = shift;
  my $name = ucfirst $self->stash('name') || 'Hello';

  $name =~ /^\w+$/ or die "Invalid sample name";
  eval "require LivePerl::Sample::$name; 1" or die $@;
  "LivePerl::Sample::$name"->new;
};

sub _docker {
    my $self = shift;
    my $cb = shift;

    if ($self->session("repo")) {
        my $repo = $self->session("repo");

        foreach my $line ($self->docker('ps')) {
            if ($line =~ m/^(\S+)\s+.*0.0.0.0:(80\d+).*$repo/) {
                $self->stash->{_container} = $1;
                $self->stash->{_port} = $2;
                $self->stash->{_repo} = $repo;
                $cb->($self);
                return;
            }
        }

        delete $self->session->{repo};
    }

    if (50 <= scalar $self->docker('ps')) {
        my $msg = "No more slots<br>The max number of people using the app has been reached.<br>Please try again later.\n";
        return $self->render(inline => '[% INCLUDE tutorial/go.html.tt %]', previous => 0, error => $msg);
    }

    my $repo = sprintf("bpmedley_%013d_liveperl", time . int(rand(1000)));
    $self->session(repo => $repo);

    # Need a slot

    my $build_it = sub {
        my $self = shift;

        my $repo = $self->session("repo");
        $self->app->log->debug($repo);
        my @build = $self->docker(build => -t => $repo, '/opt/liveperl.us/docker');
        my $out = join("\n", @build);
###         my ($in, $out, $err) = ("", "", "");
###         my $cmd = join(" ", @build);
###         $self->app->log->debug($cmd);
###         {
###             local $/;
### 
###             $out = `$cmd 2>&1`;
###         }

        if ($out =~ m/^Successfully built (\S+)/m) {
            my $image = $1;
            $self->app->log->debug("Successfully built $image: $repo");

            my @joy = `/usr/bin/sudo /opt/liveperl.us/bin/docker_start.pl $repo 2>&1`;
            $self->app->log->debug("Joy: " . join("", @joy));

            foreach my $line ($self->docker('ps')) {
                if ($line =~ m/^(\S+)\s+.*0.0.0.0:(80\d+).*$repo/) {
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
            $self->app->log->debug("No container found: $out");
            die("No container found\n");
        }
    };

    my $html = $self->render_to_string(partial => 1, inline => '[% INCLUDE tutorial/go.html.tt %]', progress => 1);
    $self->stash->{_previous} = 1;
    $self->write_chunk($html => sub { 
        eval {
            $build_it->($self);
            $cb->($self);
        };
        if ($@) {
            $self->app->log->debug($@);
            my $html = $self->render_to_string(partial => 1, progress => 0, inline => '[% INCLUDE tutorial/go.html.tt %]', previous => 1, error => $@);
            $self->write_chunk($html => sub { $self->finish });
        }
    });
}

sub _section {
    my $self = shift->render_later;

    $self->stash->{_tx} = $self->tx;
    $self->stash->{_app} = $self->app;
    Mojo::IOLoop->stream($self->tx->connection)->timeout(100);

    my $cb = sub {
        my $self = shift;
        my ($repo, $port) = ($self->stash->{_repo}, $self->stash->{_port});
        my $code = $self->param("code");
        my $output;

        my ($unique) = $repo =~ m#bpmedley_(\d+)#;

        $self->app->log->debug("repo: $repo: unique: $unique");

        if ($code && $code =~ m/\w/) {
            spurt(encode("utf8", $code), "/tmp/playground-$unique/lite.pl");
        }

        my $clam = $self->url_for("/pearls/clam")->to_abs;

        my $path = "/tmp/playground-$unique";
        my $_output = "Press Run for Fun";
        if (-f "$path/json/output.json") {
            my $bytes = slurp("$path/json/output.json");
            my $hash = j($bytes) // {};
            $_output = $hash->{output};
        }

        $output = $self->render_to_string(clam => $clam, _output => $_output, unique => $unique, port => $port, partial => 1, progress => 0, inline => '[% INCLUDE tutorial/go.html.tt %]', previous => $self->stash->{_previous} // 0);
        $self->write_chunk($output => sub { $self->finish });
    };

    $self->_docker($cb);
}

sub go {
    my $self = shift;

    return $self->_section unless $ENV{TEST_EDITOR};
    return $self->render(
          $ENV{TEST_EDITOR} eq 'error'    ? (error => 'Some error')
        : $ENV{TEST_EDITOR} eq 'progress' ? (progress => 1)
        :                                   ()
    );
}

sub logs {
    my $self = shift;

    my $repo = $self->session("repo");

    return $self->render(json => { output => "No session data found" }) unless $repo;

    my ($unique) = $repo =~ m#bpmedley_(\d+)#;

    my (@output, $container);
    foreach my $line ($self->docker('ps')) {
        if ($line =~ m/^(\w+).*$unique/) {
            $container = $1;
        }
    }

    return $self->render(json => { output => "No container found" }) unless $container;

    foreach my $line ($self->docker('logs', $container)) {
        push(@output, $line);
    }

    my $i = $#output;
    @output = @output[$i - 10 .. $i] if $i >= 10;

    return $self->render(json => { output => join("\n", @output) });
}

sub run {
    my $self = shift;

    my $repo = $self->session("repo");

    return $self->render(json => { output => "No session data found" }) unless $repo;

    my ($unique) = $repo =~ m#bpmedley_(\d+)#;

    my $output;
    {
        local $/;
        $output = `/usr/bin/sudo /opt/liveperl.us/bin/docker_run.pl $repo`; 
    }

    spurt(j({ output => $output}), "/tmp/playground-$unique/json/output.json");

    $self->render(json => { output => $output });
}

sub autosave {
    my $self = shift;

    my $code = $self->param("code");
    my $repo = $self->session("repo");

    return $self->render(json => { ret => 0 }) unless $repo;

    my ($unique) = $repo =~ m#bpmedley_(\d+)#;

    $self->app->log->debug("autosave: repo: $repo: unique: $unique");
    mkdir("/tmp/playground-$unique/json") unless -d "/tmp/playground-$unique/json";
    spurt(encode("UTF-8", $code), "/tmp/playground-$unique/lite.pl");

    my $path = "/tmp/playground-$unique";
    my $_output = "Press Run for Fun";
    if (-f "$path/json/output.json") {
        my $bytes = slurp("$path/json/output.json");
        my $hash = j($bytes) // {};
        $_output = $hash->{output};
    }

    return $self->render(json => { ret => 1, output => $_output });
}

sub clam {
    my $self = shift;

    my $repo = $self->session("repo");

    my ($unique) = $repo =~ m#bpmedley_(\d+)#;

    my $url = $self->url_for('http://pearls.liveperl.us/');

    if (!$unique) {
        $self->flash(info => "No session found.");
        $self->app->log->debug(__LINE__ . " " . $self->flash("info"));
        return($self->redirect_to($url));
    }

    if (!-f "/tmp/playground-$unique/lite.pl") {
        $self->flash(info => "No code found.  How odd?");
        $self->app->log->debug(__LINE__ . "$unique: ". $self->flash("info"));
        return($self->redirect_to($url));
    }

    my $dir = $self->clam_path($unique);

    if (-d $dir) {
        my $clam = $self->url_for("http://pearls.liveperl.us/pearls/clam/$unique")->to_abs;
        $self->flash(info => "Pearl was already Clammed<br><a style='color: blue;' href='$clam'>$clam</a>");
        $self->app->log->debug(__LINE__ . " " . $self->flash("info"));
        $url = $self->url_for($clam);
        return($self->redirect_to($url));
    }

    $self->app->log->debug("make_path: $dir");
    make_path($dir);
    make_path("$dir/code");
    make_path("$dir/json");

    copy("/tmp/playground-$unique/lite.pl", "$dir/code/lite.pl");
    copy("/tmp/playground-$unique/json/output.json", "$dir/json/output.json");

    my $clam = $self->url_for("http://pearls.liveperl.us/pearls/clam/$unique")->to_abs;
    $self->flash(info => "Clam created<br><a style='color: blue;' href='$clam'>$clam</a>");

    $self->app->log->debug(__LINE__ . " " . $self->flash("info"));
    $url = $self->url_for($clam);
    return($self->redirect_to($url));
}

1;
