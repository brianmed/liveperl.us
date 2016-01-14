package LivePerl;

use Mojo::Base 'Mojolicious';

use Mojo::Util qw(md5_sum);

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->log->level("debug");

    $self->plugin("Config" => {file => $self->home->rel_file('../config')});
    $self->plugin(AccessLog => {log => $self->home->rel_file('log/access.log'), format => '%h %l %u %t "%r" %>s %b %D "%{Referer}i" "%{User-Agent}i"'});
    $self->plugin(tt_renderer => {template_options => {CACHE_SIZE => 0, COMPILE_EXT => undef, COMPILE_DIR => undef}});
    $self->plugin('HeaderCondition');

    $self->renderer->default_handler('tt');
    $self->sessions->cookie_name("liveperl_mojolicious");
    $self->secrets([$self->config->{secret}]);

    my $listen = [];
    push(@{ $listen }, "http://45.55.49.245:80");
    $self->config(hypnotoad => {listen => $listen, workers => 4, user => "mojo", group => "mojo", inactivity_timeout => 15, heartbeat_timeout => 15, heartbeat_interval => 15, accepts => 100});

    my $r = $self->routes;
    
    $r->get('/')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "start");
    $r->get('/pearls/run')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "run");
    $r->get('/pearls/start_over')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "start_over");
    $r->get('/pearls/clam')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "create");
    $r->get('/pearls/clam/:unique')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "open");
    $r->get('/pearls/clam/:unique/raw')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "raw");
    $r->post('/pearls/autosave')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "autosave");

    $r->get('/')->to(template => "tutorial/start");
    $r->get('/about')->to(template => 'about');
    $r->get('/tutorials')->to(template => 'tutorials');
    $r->post('/tutorial/autosave')->to(controller => "Tutorial", action => "autosave");
    $r->get("/tutorial/logs")->to(controller => "Tutorial", action => "logs");
    $r->any('/tutorial/run')->to(controller => "Tutorial", action => "run");
    $r->any('/tutorial/:name')->to(controller => "Tutorial", action => "go");
    $r->get('/pearls/clam')->to(controller => "Tutorial", action => "clam");

    $self->helper(docker => sub {
        my($c, @command) = @_;
        my @output;

        $c->app->log->debug("docker: /usr/bin/sudo /usr/bin/docker @command 2>&1");
        @output = `/usr/bin/sudo /usr/bin/docker @command 2>&1`;

        return @output;
    });

    $self->helper(clam_path => sub {
        my($c, $unique) = @_;

        die("Nothing unique found") unless $unique;

        my $md5 = md5_sum($unique);
        $md5 =~ s#^(.)(.)(.)(.*)#$1/$2/$3/$4#;

        return $c->app->home->rel_dir("../../clams/$md5");
    });
}

1;
