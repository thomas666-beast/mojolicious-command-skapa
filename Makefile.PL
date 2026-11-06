use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Mojolicious::Command::skapa',
  VERSION_FROM     => 'lib/Mojolicious/Command/skapa.pm',
  ABSTRACT         => 'Scaffolding commands for Mojolicious applications',
  AUTHOR           => 'Thomas <selfworker112@mailfence.com>',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.020',
  PREREQ_PM        => {
    'Mojolicious' => '9.0',
    'Moo'         => '2.0',
  },
);

