package Mojolicious::Command::skapa;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::File qw(path);

has description => 'Scaffolding toolkit (make:controller, make:plugin, make:moo, ...)';
has usage       => <<'USAGE';
Usage: APPLICATION skapa <subcommand> [args]

Subcommands:
  make:controller <Name>   Create a controller under lib/ForCommand/Controller/
  make:plugin     <Name>   Create a plugin under lib/ForCommand/Plugin/
  make:moo        <Name>   Create a Moo class under lib/ForCommand/
USAGE

sub run ($self, @args) {
  my $sub = shift @args;

  if    (!$sub)                     { say $self->usage }
  elsif ($sub eq 'make:controller') { $self->_make_controller(@args) }
  elsif ($sub eq 'make:plugin')     { $self->_make_plugin(@args) }
  elsif ($sub eq 'make:moo')        { $self->_make_moo(@args) }
  else                              { say "Unknown skapa subcommand: $sub"; say $self->usage }
}

sub _make_controller ($self, $name) {
  unless ($name) {
    say 'Usage: APPLICATION skapa make:controller <Name>';
    return;
  }

  my $package = 'ForCommand::Controller::' . join('::', split m{/}, $name);
  my $file    = path($self->app->home, 'lib', 'ForCommand', 'Controller', "$name.pm");

  if (-e $file) {
    say "File already exists: $file";
    return;
  }

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
  unless ($name) {
    say 'Usage: APPLICATION skapa make:plugin <Name>';
    return;
  }

  my $package = 'ForCommand::Plugin::' . join('::', split m{/}, $name);
  my $file    = path($self->app->home, 'lib', 'ForCommand', 'Plugin', "$name.pm");

  if (-e $file) {
    say "File already exists: $file";
    return;
  }

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
  unless ($name) {
    say 'Usage: APPLICATION skapa make:moo <Name>';
    return;
  }

  my $package = 'ForCommand::' . join('::', split m{/}, $name);
  my $file    = path($self->app->home, 'lib', 'ForCommand', "$name.pm");

  if (-e $file) {
    say "File already exists: $file";
    return;
  }

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

1;
