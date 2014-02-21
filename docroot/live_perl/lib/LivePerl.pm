package LivePerl;

use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->log->level("debug");

    $self->plugin("Config");
    my $site_dir = $self->config('site_dir');
    my $secret = $self->config('secret');

    $self->plugin(AccessLog => {log => "$site_dir/docroot/live_perl/log/access.log", format => '%h %l %u %t "%r" %>s %b %D "%{Referer}i" "%{User-Agent}i"'});
    $self->plugin(tt_renderer => {template_options => {CACHE_SIZE => 0, COMPILE_EXT => undef, COMPILE_DIR => "/tmp/liveperl.us/templates"}});
    $self->renderer->default_handler('tt');

    $self->secrets([$secret]);
    
    my $r = $self->routes;
    
    $r->get('/')->to(controller => 'Index', action => 'slash');

    $r->any('/tutorial/start')->to(controller => 'Tutorial', action => 'start');
    $r->any('/tutorial/hello')->to(controller => 'Tutorial', action => 'hello');
}

1;
