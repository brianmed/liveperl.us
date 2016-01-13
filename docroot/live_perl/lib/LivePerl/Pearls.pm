package LivePerl::Pearls;

use Mojo::Base 'Mojolicious::Controller';
use File::Copy qw();
use Mojo::Util qw(slurp spurt);
use Mojo::JSON qw(j);
use Encode qw(encode);
use Data::UUID;
use File::Path qw(make_path);
use File::Copy qw(copy);

sub _fortune {
    my $self = shift;

    my @fortune = `/usr/bin/fortune -n 120 -s`; 
    my $fortune;
    foreach my $line (@fortune) {
        chomp($line);
        $fortune .= "$line<br>";    
    }

    return($fortune);
}

sub start {
    my $self = shift;

    my $code = $self->param("code");
    my $pearls = $self->session("pearls");

    # Reload the browser
    if (!$code || $code !~ m/\w/) {
        if ($pearls) {
            $self->app->log->debug("reload: $pearls");
            my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;
            $code = slurp("/tmp/playground-$unique/code/lite.pl");
        }
    }

    if (!$pearls) {
        foreach (1 .. 100) {
            $pearls = sprintf("liveperl_%13d_pearls", time . int(rand(1000)));

            my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;
            last if !-d "/tmp/playground-$unique";
        }

        $self->app->log->debug("init: $pearls");
        $self->session(pearls => $pearls);
    }

    $self->app->log->debug("start: $pearls");

    my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;

    if (!$code || $code !~ m/\w/) {
        mkdir("/tmp/playground-$unique");
        mkdir("/tmp/playground-$unique/code");
        mkdir("/tmp/playground-$unique/json");
        File::Copy::copy("/opt/liveperl.us/bin/world.txt", "/tmp/playground-$unique/code/lite.pl");
        $code = slurp("/tmp/playground-$unique/code/lite.pl");
    }

    if ($self->flash("info")) {
        $self->stash("info", $self->flash("info"));
    }

    my $fortune = $self->_fortune;
    my $clam = $self->url_for("/pearls/clam")->to_abs;
    return($self->render("pearls/start", fortune => $fortune, unique => $unique, code => $code, clam => $clam, have_output => 1));
}

sub start_over {
    my $self = shift;

    delete($self->session->{pearls});

    my $url = $self->url_for('/');
    return($self->redirect_to($url));
}

sub run {
    my $self = shift;

    my $pearls = $self->session("pearls");

    if (!$pearls) {
        $self->render(json => { error => 1, msg => "Session expired" });
    }

    my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;

    my $output;
    {
        local $/;
        $output = `/usr/bin/sudo /opt/liveperl.us/bin/docker_run.pl $pearls`; 
    }

    spurt(j({ output => $output}), "/tmp/playground-$unique/json/output.json");

    $self->render(json => { output => $output });
}

sub create {
    my $self = shift;

    my $pearls = $self->session("pearls");

    my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;

    if (!$unique) {
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    if (!-f "/tmp/playground-$unique/code/lite.pl") {
        $self->flash(info => "No code found.  How odd?");
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $dir = $self->clam_path($unique);

    if (-d $dir) {
        my $clam = $self->url_for("/pearls/clam/$unique")->to_abs;
        $self->flash(info => "Pearl was already Clammed<br><a style='color: blue;' href='$clam'>$clam</a>");
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    $self->app->log->debug("make_path: $dir");
    make_path($dir);
    make_path("$dir/code");
    make_path("$dir/json");

    copy("/tmp/playground-$unique/code/lite.pl", "$dir/code/lite.pl");
    copy("/tmp/playground-$unique/json/output.json", "$dir/json/output.json");

    my $clam = $self->url_for("/pearls/clam/$unique")->to_abs;
    $self->flash(info => "Clam created<br><a style='color: blue;' href='$clam'>$clam</a>");

    my $url = $self->url_for('/');
    return($self->redirect_to($url));
}

sub open {
    my $self = shift;

    my ($unique) = $self->param("unique");

    if (!$unique) {
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $path = $self->clam_path($unique);

    if (!-f "$path/code/lite.pl") {
        $self->flash(info => "No code found.  How odd.");
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $code = slurp("$path/code/lite.pl");

    my $fortune = $self->_fortune;

    my $output;
    if (-f "$path/json/output.json") {
        my $bytes = slurp("$path/json/output.json");
        my $hash = j($bytes) // {};
        $output = $hash->{output};
    }

    # delete($self->session->{pearls});

    my $raw = $self->url_for("/pearls/clam/$unique/raw")->to_abs;
    return($self->render("pearls/start", fortune => $fortune, unique => $unique, code => $code, from_clam => 1, raw => "$raw", have_output => defined $output ? 1 : 0, output => $output // ""));
}

sub raw {
    my $self = shift;

    my ($unique) = $self->param("unique");

    if (!$unique) {
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $path = $self->clam_path($unique);

    if (!-f "$path/code/lite.pl") {
        $self->flash(info => "No code found.  How odd.");
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $code = slurp("$path/code/lite.pl");

    $self->render(text => $code, format => "txt");
}

sub autosave {
    my $self = shift;

    my $code = $self->param("code");
    my $pearls = $self->session("pearls");

    return $self->render(json => { ret => 0 }) unless $pearls;

    my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;

    $self->app->log->debug("autosave: pearls: $pearls: unique: $unique");
    spurt(encode("UTF-8", $code), "/tmp/playground-$unique/code/lite.pl");

    return $self->render(json => { ret => 1 });
}

1;
