package Mojolicious::Command::skapa;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::File qw(path);
use Mojo::Util qw(class_to_path);

has description => 'Scaffolding toolkit (make:controller, make:plugin, make:moo, make:route, ...)';
has usage       => <<'USAGE';
Usage: APPLICATION skapa <subcommand> [args]

Subcommands:
  make:controller <Name>   Create a controller under lib/<App>/Controller/
  make:plugin     <Name>   Create a plugin under lib/<App>/Plugin/
  make:moo        <Name>   Create a Moo class under lib/<App>/
  make:route      <Name>   Create a route group under lib/<App>/Route/
USAGE

sub run ($self, @args) {
  my $sub = shift @args;

  if    (!$sub)                     { say $self->usage }
  elsif ($sub eq 'make:controller') { $self->_make_controller(@args) }
  elsif ($sub eq 'make:plugin')     { $self->_make_plugin(@args) }
  elsif ($sub eq 'make:moo')        { $self->_make_moo(@args) }
  elsif ($sub eq 'make:route')      { $self->_make_route(@args) }
  elsif ($sub eq 'make:secret')      { $self->_make_secret(@args) }
  else                              { say "Unknown skapa subcommand: $sub"; say $self->usage }
}

sub _app_class ($self) { ref $self->app }

sub _target_file ($self, $subdir, $name) {
  my $app = $self->_app_class;
  my @parts = $app =~ /::/g ? split /::/, $app : ($app);
  return path($self->app->home, 'lib', @parts, $subdir, "$name.pm");
}

sub _make_controller ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:controller <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Controller::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Controller', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $content = <<"EOF";
package $package;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# sub index (\$self) {
#   \$self->render(text => 'Hello from $name');
# }

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);
  say "Created: $file";
}

sub _make_plugin ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:plugin <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Plugin::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Plugin', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $content = <<"EOF";
package $package;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register (\$self, \$app, \$conf) {
  # \$app->helper(...);
}

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);
  say "Created: $file";
}

sub _make_moo ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:moo <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $content = <<"EOF";
package $package;
use Moo;
use strictures 2;
use namespace::clean;

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);
  say "Created: $file";
}

sub _make_route ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:route <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Route::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Route', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $plugin_name = join '::', split m{/}, $name;

  my $content = <<"EOF";
package $package;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register (\$self, \$app, \$conf) {
  my \$r = \$app->routes;

  \$r->get('/$name' => sub (\$c) {
    \$c->render(text => '$name route');
  });
}

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);

  my $startup_file = path($self->app->home, 'lib', class_to_path($app));
  my $plugin_line  = $package;
  $plugin_line =~ s/^${app}:://;

  say "Created: $file";
  say '';
  say "Load it in $startup_file by adding this line to startup:";
  say "  plugin '$plugin_line';";
}

sub _make_secret ($self) {
  require Mojo::Util;
  my $secret = Mojo::Util::generate_secret();

  say 'Copy the following into the secrets field of your config file:';
  say '';
  say 'secrets:';
  say "  - $secret";
}

1;
