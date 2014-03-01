package LivePerl;

use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->log->level("debug");

    $self->plugin("Config");
    $self->plugin(AccessLog => {log => $self->home->rel_file('log/access.log'), format => '%h %l %u %t "%r" %>s %b %D "%{Referer}i" "%{User-Agent}i"'});
    $self->plugin(tt_renderer => {template_options => {CACHE_SIZE => 0, COMPILE_EXT => undef, COMPILE_DIR => "/tmp/liveperl.us/templates"}});
    $self->plugin('HeaderCondition');

    $self->renderer->default_handler('tt');
    $self->sessions->cookie_name("liveperl_mojolicious");
    $self->secrets([$self->config('secret') || time]);
    
    my $r = $self->routes;
    
    $r->get('/')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "start");
    $r->get('/pearls/run')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "run");
    $r->get('/pearls/start_over')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "start_over");
    $r->get('/pearls/clam/:unique')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "open");
    $r->post('/pearls/autosave')->over(headers => {Host => qr/pearls\.liveperl\.us/})->to(controller => "Pearls", action => "autosave");

    $r->get('/')->to(template => "tutorial/start");
    $r->get('/about')->to(template => 'about');
    $r->get('/tutorials')->to(template => 'tutorials');
    $r->post('/tutorial/autosave')->to(controller => "Tutorial", action => "autosave");
    $r->get("/tutorial/logs")->to(controller => "Tutorial", action => "logs");
    $r->any('/tutorial/:name')->to('tutorial#go');

    $self->helper(docker => sub {
        my($c, @command) = @_;
        my @output;

        $c->app->log->debug("docker: /usr/bin/sudo /usr/bin/docker @command 2>&1");
        @output = `/usr/bin/sudo /usr/bin/docker @command 2>&1`;

        return @output;
    });
}

1;
