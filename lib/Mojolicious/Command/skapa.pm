package Mojolicious::Command::skapa;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => 'Scaffolding toolkit';
has usage       => "Usage: APPLICATION skapa <subcommand> [args]\n";

sub run ($self, @args) {
  my $sub = shift @args;
  say $sub ? "Unknown skapa subcommand: $sub" : $self->usage;
}

1;
