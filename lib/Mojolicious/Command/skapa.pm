package Mojolicious::Command::skapa;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::File qw(path);
use Mojo::Util qw(class_to_path decamelize);

our $VERSION = '0.01';

has description => 'Scaffolding toolkit (make:*, subcommands below)';
has usage       => <<'USAGE';
Usage: APPLICATION skapa <subcommand> [args]

Subcommands:
  make:controller <Name>   Create a controller under lib/<App>/Controller/
  make:plugin     <Name>   Create a plugin under lib/<App>/Plugin/
  make:moo        <Name>   Create a Moo class under lib/<App>/
  make:route      <Name>   Create a route group under lib/<App>/Route/
  make:middleware <Name>   Create a middleware under lib/<App>/Middleware/
  make:command    <name>   Create an app command under lib/<App>/Command/
  make:helper     <Name>   Create a plugin with an $app->helper stub under lib/<App>/Plugin/
  make:test       <name>   Create t/<name>.t with a Test::Mojo skeleton
  make:minion     <Name>   Create a Minion task under lib/<App>/Minion/
  make:request    <Name>   Create a FormRequest validation class under lib/<App>/Requests/
  make:translatable [locale]  Create i18n/<locale>.json (default: en)
  make:policy     <Name>   Create a policy under lib/<App>/Policy/
  serve [-l URL]           Run the app with morbo (default: http://*:3000)
  orm <args...>            Forward to the Mimir ORM command (migrate, make:model, make:migration, ...)
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
  elsif ($sub eq 'make:command')      { $self->_make_command(@args) }
  elsif ($sub eq 'make:secret')       { $self->_make_secret(@args) }
  elsif ($sub eq 'make:helper')       { $self->_make_helper(@args) }
  elsif ($sub eq 'make:test')         { $self->_make_test(@args) }
  elsif ($sub eq 'make:minion')       { $self->_make_minion(@args) }
  elsif ($sub eq 'make:request')      { $self->_make_request(@args) }
  elsif ($sub eq 'make:policy')       { $self->_make_policy(@args) }
  elsif ($sub eq 'make:translatable') { $self->_make_translatable(@args) }
  elsif ($sub eq 'serve')             { $self->_serve(@args) }
  elsif ($sub eq 'orm')               { $self->_orm(@args) }
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
      my \$result = \$next->();
      return \$result;
    });
    return;
  }

  return \$app->routes->under(sub (\$c) {
    # return 1 to allow, 0 to stop
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

sub _make_command ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:command <name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Command::" . $name;
  my $file    = $self->_target_file('Command', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $content = <<"EOF";
package $package;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => '$name command';
has usage       => "Usage: APPLICATION $name [args]\\n";

sub run (\$self, \@args) {
  say 'Hello from $name';
}

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);

  my $startup_file = path($self->app->home, 'lib', class_to_path($app));
  my $ns_line      = "push \@{\$self->commands->namespaces}, '${app}::Command';";

  say "Created: $file";
  say '';
  say "To make it available, ensure startup in $startup_file contains:";
  say "  $ns_line";
  say '';
  say "Then run it with:";
  say "  ./script/<script-name> $name";
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

sub _make_helper ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:helper <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Plugin::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Plugin', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $helper_name = lc($name);
  $helper_name =~ s{/}{_}g;
  $helper_name =~ s/([a-z])([A-Z])/$1_$2/g;
  $helper_name = lc $helper_name;

  my $content = <<"EOF";
package $package;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register (\$self, \$app, \$conf) {
  \$app->helper($helper_name => sub (\$c, \@args) {
    return "Hello from $helper_name";
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
  say "Load it in $startup_file by adding this line inside startup:";
  say "  plugin '$plugin_line';";
  say '';
  say "Then use it in controllers/templates:";
  say "  \$c->$helper_name";
}

sub _make_test ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:test <name>'; return }

  my $app     = $self->_app_class;
  my $moniker = decamelize($name);
  my $file    = path($self->app->home, 't', "$moniker.t");

  if (-e $file) { say "File already exists: $file"; return }

  my $content = <<"EOF";
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

my \$t = Test::Mojo->new('$app');

\$t->get_ok('/')->status_is(200);

done_testing();

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);
  say "Created: $file";
}

sub _make_minion ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:minion <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Minion::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Minion', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $method = join '_', split m{/}, $name;
  $method =~ s/([a-z])([A-Z])/$1_$2/g;
  $method = lc $method;

  my $content = <<"EOF";
package $package;
use Mojo::Base -base, -signatures;

sub $method (\$self, \$job, \@args) {
  # \$job->app is available here
  # \$job->finish(...) to signal completion
  return;
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
  say 'Register the task where Minion is started (usually in startup):';
  say "  use $package;";
  say "  \$self->minion->add_task($method => '$package');";
  say "  ($startup_file)";
}

sub _make_request ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:request <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Requests::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Requests', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $content = <<"EOF";
package $package;
use Mojo::Base 'Mojolicious::Plugin::FormRequest::Base', -signatures;

sub rules (\$self, \$c) {
  return {
    # name  => 'required|min:3|max:50',
    # email => 'required|email|unique:users,email',
  };
}

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);

  say "Created: $file";
  say '';
  say 'Requires Mojolicious::Plugin::FormRequest loaded in startup:';
  say "  plugin 'FormRequest';";
  say '';
  say 'Use it in a controller:';
  say "  my \$data = \$self->form_request('$package')->validate_or_fail;";
  say '  return unless defined $data;';
}

sub _make_translatable ($self, $locale = undef) {
  $locale //= 'en';

  unless ($locale =~ /\A[a-z]{2}(?:-[A-Z]{2})?\z/) {
    say "Invalid locale: $locale (expected e.g. 'en', 'de', 'pt-BR')";
    return;
  }

  my $file = path($self->app->home, 'i18n', "$locale.json");

  if (-e $file) {
    say "File already exists: $file";
    return;
  }

  my $content = <<"EOF";
{
  "welcome": "Welcome"
}
EOF

  $file->dirname->make_path;
  $file->spew($content);

  say "Created: $file";
  say '';
  say 'Requires Mojolicious::Plugin::Translatable loaded in startup:';
  say "  plugin 'Translatable';";
  say '';
  say 'Then use it in controllers and templates:';
  say "  \$c->trans('welcome');";
  say "  <%= trans 'welcome' %>";
}

sub _make_policy ($self, $name) {
  unless ($name) { say 'Usage: APPLICATION skapa make:policy <Name>'; return }

  my $app     = $self->_app_class;
  my $package = "${app}::Policy::" . join('::', split m{/}, $name);
  my $file    = $self->_target_file('Policy', $name);

  if (-e $file) { say "File already exists: $file"; return }

  my $policy_name = join '::', split m{/}, $name;

  my $content = <<"EOF";
package $package;
use Mojo::Base -base, -signatures;

# Each method receives (\$self, \$c, \$object) and must return true
# to allow, false to deny. The plugin passes the object being checked
# as the third argument.

# sub view (\$self, \$c, \$obj) {
#   return 0 unless \$c->current_user;
#   return 1;
# }

sub view   (\$self, \$c, \$obj) { return 0 }
sub create (\$self, \$c, \$obj) { return 0 }
sub update (\$self, \$c, \$obj) { return 0 }
sub delete (\$self, \$c, \$obj) { return 0 }

1;
EOF

  $file->dirname->make_path;
  $file->spew($content);

  say "Created: $file";
  say '';
  say 'Requires Mojolicious::Plugin::Policy loaded in startup:';
  say "  plugin 'Policy' => {";
  say "    policies => {";
  say "      $policy_name => '$package',";
  say '    },';
  say '  };';
  say '';
  say 'Use it in a controller:';
  say "  \$c->authorize('update', \$object);";
  say "  my \$ok = \$c->allowed('view', \$object);";
}

sub _serve ($self, @args) {
  my $app     = ref $self->app;
  my $moniker = decamelize($app);
  my $script  = path($self->app->home, 'script', $moniker);

  unless (-f $script) {
    say "Script not found: $script";
    return 1;
  }

  # exec replaces this process; only returns on failure
  { no warnings 'exec'; exec 'morbo', $script->to_string, @args; }

  say "Failed to exec morbo: $!";
  say '';
  say 'If port 3000 is busy, pick another listen address:';
  say "  APPLICATION skapa serve -l http://*:4000";
  return 1;
}

sub _orm ($self, @args) {
  require Mimir;

  my $mimir = Mimir->instance;
  unless ($mimir) {
    say 'Mimir is not loaded. Add this line to startup:';
    say "  plugin 'Mimir';";
    return 1;
  }

  if (!@args || $args[0] =~ /^(?:-h|--help|help)$/) {
    say 'Usage: APPLICATION skapa orm <command> [options]';
    say '';
    say 'Commands:';
    say '  migrate                     Run pending migrations';
    say '  migrate --pretend           Show the SQL only';
    say '  migrate --step              One batch per migration';
    say '  rollback [--step N]         Undo last batch (or last N migrations)';
    say '  reset                       Undo everything';
    say '  refresh                     Reset, then migrate';
    say '  fresh                       Drop all tables, then migrate';
    say '  status                      Show which migrations have run';
    say '  make:migration NAME         Create a migration file';
    say '    --create TABLE              ...with a create-table stub';
    say '    --table TABLE               ...with an alter-table stub';
    say '  make:model NAME             Create a model file';
    say '    --migration                 ...and a matching migration';
    say '';
    say 'Options (all commands):';
    say '  -c, --connection NAME       Use another configured connection';
    say '';
    say 'Run "APPLICATION skapa orm <command> --help" for command specifics.';
    return 0;
  }

  require Mojolicious::Plugin::Mimir::Command::mimir;
  my $cmd = Mojolicious::Plugin::Mimir::Command::mimir->new(app => $self->app);
  return $cmd->run(@args);
}

1;
