package LivePerl::Pearls;

use Mojo::Base 'Mojolicious::Controller';
use File::Copy qw();
use Mojo::Util qw(slurp spurt);
use Mojo::JSON qw(j);
use Encode qw(encode);

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
            my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;
            $code = slurp("/tmp/playground-$unique/code/lite.pl");
        }
    }

    if (!$pearls) {
        $pearls = sprintf("liveperl_%013d_pearls", time . int(rand(1000)));
        $self->session(pearls => $pearls);
    }

    my ($unique) = $pearls =~ m#liveperl_(\d+)_pearls#;

    if (!$code || $code !~ m/\w/) {
        mkdir("/tmp/playground-$unique");
        mkdir("/tmp/playground-$unique/code");
        mkdir("/tmp/playground-$unique/json");
        File::Copy::copy("/opt/liveperl.us/bin/world.txt", "/tmp/playground-$unique/code/lite.pl");
        $code = slurp("/tmp/playground-$unique/code/lite.pl");
    }

    my $fortune = $self->_fortune;
    my $clam = $self->url_for("/pearls/clam/$unique")->to_abs;
    return($self->render("pearls/start", fortune => $fortune, unique => $unique, code => $code, clam => $clam));
}

sub run {
    my $self = shift;

    my $pearls = $self->session("pearls");

    if (!$pearls) {
        $self->render(json => { error => 1 });
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

sub open {
    my $self = shift;

    my ($unique) = $self->param("unique");

    if (!$unique) {
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    if (!-f "/tmp/playground-$unique/code/lite.pl" || !-f "/tmp/playground-$unique/json/output.json") {
        my $url = $self->url_for('/');
        return($self->redirect_to($url));
    }

    my $code = slurp("/tmp/playground-$unique/code/lite.pl");

    my $fortune = $self->_fortune;

    my $bytes = slurp("/tmp/playground-$unique/json/output.json");
    my $hash = j($bytes) // {};
    my $output = $hash->{output};

    delete($self->session->{pearls});

    return($self->render("pearls/start", fortune => $fortune, unique => $unique, code => $code, from_clam => 1, output => $output));
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
