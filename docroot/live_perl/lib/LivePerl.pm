package LivePerl;

use Mojo::Base 'Mojolicious';

$ENV{PATH} ||= '';
my @DOCKER;

for my $path (split /:/, $ENV{PATH}) {
  next unless -x "$path/docker";
  push @DOCKER, "$path/docker";
  last;
}

for my $path (split /:/, $ENV{PATH}) {
  next unless @DOCKER and -x "$path/sudo";
  unshift @DOCKER, "$path/sudo";
  last;
}

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->log->level("debug");

    $self->plugin("Config");
    my $site_dir = $self->config('site_dir');
    my $secret = $self->config('secret');

    $self->sessions->cookie_name("liveperl_mojolicious");

    $self->plugin(AccessLog => {log => "$site_dir/docroot/live_perl/log/access.log", format => '%h %l %u %t "%r" %>s %b %D "%{Referer}i" "%{User-Agent}i"'});
    $self->plugin(tt_renderer => {template_options => {CACHE_SIZE => 0, COMPILE_EXT => undef, COMPILE_DIR => "/tmp/liveperl.us/templates"}});
    $self->renderer->default_handler('tt');

    $self->secrets([$secret]);
    
    my $r = $self->routes;
    
    $r->get('/')->to('tutorial#start');
    $r->get('/tutorials')->to(template => 'tutorials');
    $r->post('/tutorial/autosave')->to('tutorial#autosave')->name('autosave');
    $r->any('/tutorial/:file')->to('tutorial#go');

    unless(grep { /docker/ } @DOCKER) {
      $self->log->error("Could not find docker executable!");
    }

    $self->helper(docker => sub {
        my($c, @command) = @_;
        my @output;

        return @output unless @DOCKER;

        $c->app->log->debug("open -| @DOCKER @command");
        open my $DOCKER, '-|', @DOCKER, @command;
        while(<$DOCKER>) {
          chomp;
          push @output, $_;
        }

        return @output;
    });

    $self->helper(sample => sub {
        return if $_[1] =~ /\.\./;
        return "$site_dir/data/samples/$_[1]";
    });
}

1;
