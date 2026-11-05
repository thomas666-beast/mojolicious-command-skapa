package Mojolicious::Command::skapa;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::File qw(path);
use Mojo::Util qw(class_to_path decamelize);

has description => 'Scaffolding toolkit (make:controller, make:plugin, make:moo, make:route, make:middleware, make:secret)';
has usage       => <<'USAGE';
Usage: APPLICATION skapa <subcommand> [args]

Subcommands:
  make:controller <Name>   Create a controller under lib/<App>/Controller/
  make:plugin     <Name>   Create a plugin under lib/<App>/Plugin/
  make:moo        <Name>   Create a Moo class under lib/<App>/
  make:route      <Name>   Create a route group under lib/<App>/Route/
  make:middleware <Name>   Create a middleware (plugin + around_action hook) under lib/<App>/Middleware/
  make:secret              Generate an app secret and write to the config file
USAGE

sub run ($self, @args) {
  my $sub = shift @args;

  if    (!$sub)                       { say $self->usage }
  elsif ($sub eq 'make:controller')   { $self->_make_controller(@args) }
  elsif ($sub eq 'make:plugin')       { $self->_make_plugin(@args) }
  elsif ($sub eq 'make:moo')          { $self->_make_moo(@args) }
  elsif ($sub eq 'make:route')        { $self->_make_route(@args) }
  elsif ($sub eq 'make:middleware')   { $self->_make_middleware(@args) }
  elsif ($sub eq 'make:secret')       { $self->_make_secret(@args) }
  else                                { say "Unknown skapa subcommand: $sub"; say $self->usage }
}

sub _app_class ($self) { ref $self->app }

sub _target_file ($self, $subdir, $name) {
  my $app   = $self->_app_class;
  my @parts = split /::/, $app;
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

sub _make_middleware ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:middleware <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Middleware::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Middleware', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $content = <<"EOF";
package $package;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

# WHAT IS THIS?
# A middleware is just a plugin. Where you load it decides its scope.
#
# TWO WAYS TO USE IT
#
# 1) ROUTE-SCOPED (only some routes)
#    From a route file, chain on the returned subtree:
#
#      my \$r = \$app->plugin('${package}');
#      \$r->get('/dashboard' => sub (\$c) { ... });   # guarded
#      \$r->get('/users'     => sub (\$c) { ... });   # guarded
#
#    Routes added to the main \$app->routes are NOT guarded.
#
# 2) GLOBAL (every dispatched action)
#    From startup, install it as a hook instead of returning a subtree:
#
#      \$app->plugin('${package}', { global => 1 });
#
#    In that mode register installs around_action and wraps every action.

sub register (\$self, \$app, \$conf) {
  if (\$conf->{global}) {
    \$app->hook(around_action => sub (\$next, \$c, \$action, \$last) {
      # --- before action ---
      my \$result = \$next->();
      # --- after action ---
      return \$result;
    });
    return;
  }

  # --- route-scoped mode (default) ---
  return \$app->routes->under(sub (\$c) {
    # return 1 to allow, 0 to stop (e.g. after \$c->redirect_to)
    return 1;
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
  say 'Use it route-scoped (in a route file):';
  say "  my \$r = \$app->plugin('$package');";
  say '  $r->get(...)   # guarded';
  say '';
  say 'Or globally (in startup):';
  say "  plugin '$plugin_line', { global => 1 };";
  say "  ($startup_file)";
}

sub _make_secret ($self) {
  require Mojo::Util;
  require Mojo::File;

  my $secret = Mojo::Util::generate_secret();

  my $app     = ref $self->app;
  my $moniker = Mojo::Util::decamelize($app);
  my $file    = Mojo::File::path($self->app->home, "$moniker.yml");

  my $block = "secrets:\n  - $secret\n";

  if (!-e $file) {
    say 'Config file not found. Copy the following into your config file:';
    say '';
    say $block;
    return;
  }

  my $content = $file->slurp;

  my @out;
  my $in_secrets = 0;

  for my $line (split /\n/, $content, -1) {
    if ($in_secrets) {
      if ($line =~ /\A\s/ || $line =~ /\A\s*-\s/) { next }
      $in_secrets = 0;
    }
    if ($line =~ /\Asecrets\s*:/) { $in_secrets = 1; next }
    push @out, $line;
  }

  my $new = join("\n", @out);
  $new =~ s/\n+\z/\n/;
  $new .= "\n" unless $new =~ /\n\z/;
  $new .= $block;

  $file->spew($new);
  say "Secret generated and written to: $file";
}

1;
