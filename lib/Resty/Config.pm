package Resty::Config;

use strict;
use warnings;

use Path::Class;

sub new {
   my ($class, $path) = @_;
   die 'path is a required arg!' unless $path;

   my $guts = { store => my $dir = dir($path) };

   $dir->mkpath unless -d $dir->stringify;

   bless $guts, $class;
}

sub uri_base {
   my $file = $_[0]->{store}->file('host');
   $file->touch unless -f $file->stringify;
   $file->spew($_[1]) if $_[1];
   ($file->slurp(chomp => 1))[0]
}

sub HIVE {
   my ($self, $host, $method) = @_;

   my $file = $_[0]->{store}->file($host);
   $file->touch unless -f $file->stringify;

   my %config = map {
      m/\s*(\w+)\s+(.*)/
         ? (uc($1), $2)
         : ()
   } $file->slurp(chomp => 1);

   if (my $ret = $config{$method}) {
      return [ split /\s+/, $ret ]
   }
   return []
}

1;
