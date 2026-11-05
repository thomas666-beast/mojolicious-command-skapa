package Mojolicious::Command::skapa;
use Mojo::Base 'Mojolicious::Command', -signatures;
use Mojo::File qw(path);

has description => 'Scaffolding toolkit (make:controller, make:plugin, ...)';
has usage       => <<'USAGE';
Usage: APPLICATION skapa <subcommand> [args]

Subcommands:
  make:controller <Name>   Create a controller under lib/ForCommand/Controller/
USAGE

sub run ($self, @args) {
  my $sub = shift @args;

  if    (!$sub)                       { say $self->usage }
  elsif ($sub eq 'make:controller')   { $self->_make_controller(@args) }
  else                                { say "Unknown skapa subcommand: $sub"; say $self->usage }
}

sub _make_controller ($self, $name) {
  unless ($name) {
    say 'Usage: APPLICATION skapa make:controller <Name>';
    return;
  }

  # Admin/Reports -> ForCommand::Controller::Admin::Reports
  my $package = 'ForCommand::Controller::' . join('::', split m{/}, $name);

  # Admin/Reports -> lib/ForCommand/Controller/Admin/Reports.pm
  my $file = path($self->app->home, 'lib', 'ForCommand', 'Controller', "$name.pm");

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

  $file->dirname->make_path;   # create parent dirs only
  $file->spew($content);       # now write the file
  say "Created: $file";
}

1;
