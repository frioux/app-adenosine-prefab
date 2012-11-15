package App::Adenosine;

use strict;
use warnings;

# ABSTRACT: Handy CLI HTTP tool

use URI;
use Getopt::Long qw(:config pass_through no_ignore_case);
use File::Path 'mkpath';
use URI::Escape 'uri_escape';
use File::Spec::Functions 'splitpath';
use Path::Class;
use Text::ParseWords;
use Scalar::Util 'blessed';

our $verb_regex = '(?:HEAD|OPTIONS|GET|DELETE|PUT|POST|TRACE)';

sub verbose { $_[0]->{verbose} }
sub plugins { @{$_[0]->{plugins}} }

sub new {
   my ($class, $args) = @_;

   if (my $p = $args->{plugins}) {
      die "plugins must be an arrayref" unless ref $p && ref $p eq 'ARRAY';
      $args->{plugins} = [
         map {;
            my $ret = $_;
            $ret = $ret->new unless blessed($ret);
            $ret;
         } @{$args->{plugins}}];
   } else {
      $args->{plugins} = []
   }

   my $self = { %$args };

   bless $self, $class;

   local @ARGV = @{$self->argv};

   my $action = shift @ARGV;

   my $uri_base = $self->uri_base;

   $self->stdout("$uri_base\n"), return if !$action;

   if ($action =~ m/^$verb_regex$/) {
      my $quote = 1;
      my $interactive_edit = 0;
      my $query = '';
      $self->{verbose} = 0;

      my ($path, $data);
      $path   = shift @ARGV unless $ARGV[0] && $ARGV[0] =~ /^-/;
      $data   = shift @ARGV unless $ARGV[0] && $ARGV[0] =~ /^-/;

      $path ||= '';
      $data ||= '';

      GetOptions (
         Q     => sub { $quote = 0 },
         "q=s" => \$query,
         V     => \$interactive_edit,
         v     => sub { $self->{verbose} = 1 },
      );

      my @extra = (@ARGV, $self->_get_extra_options);
      my $wantdata;
      $wantdata = 1 if $action =~ m/^(?:PUT|POST|TRACE)$/;
      if ($wantdata && $interactive_edit) {
         require File::Temp;
         my ($fh, $fn) = File::Temp::tempfile();

         system($ENV{EDITOR} || 'vi', $fn);

         $data = file($fn)->slurp;
         unlink $fn;
      }

      push @extra, '--data-binary' if $data;
      push @extra, '-I' if $action eq 'HEAD';

      my $_path = $uri_base;
      $_path =~ s/\*/$path/;

      $query = uri_escape($query) if $quote;

      push @extra, $self->host_method_config( $self->host($uri_base), $action );

      $query = "?$query" if $query;

      my @curl = @{$self->curl_command({
         method => $action,
         data   => $data,
         cookie_jar => $self->cookie_jar($uri_base),
         rest => \@extra,
         location => "$_path$query",
      })};

      $self->stderr(join(" ", map "'$_'", @curl) . "\n") if $self->verbose;

      my ($out, $err, $ret) = $self->capture_curl(@curl);
      return $self->handle_curl_output($out, $err, $ret);
   } else {
      my $uri_base = $self->uri_base($action);
      $self->_set_extra_options(@ARGV);
      $self->stdout("$uri_base\n"), return
   }
}

sub config_location {
   my $loc;
   if (my $h = $ENV{XDG_CONFIG_HOME}) {
      $loc = "$h/resty"
   } else {
      $loc = "$ENV{HOME}/.resty"
   }
   my $ret = dir($loc);

   $ret->mkpath unless -d $ret->stringify;

   $ret
}

sub stdout { print STDOUT $_[1] }
sub stderr { print STDERR $_[1] }

sub capture_curl {
   my ($self, @rest) = @_;

   require Capture::Tiny;
   Capture::Tiny::capture(sub { system(@rest) });
}

sub handle_curl_output {
   my ($self, $out, $err, $ret) = @_;

   my ( $http_code ) = ($err =~ m{.*HTTP/1\.[01] (\d)\d\d });
   if ($self->verbose) {
      my @filters = grep { $_->does('App::Adenosine::Role::FiltersStdErr') }
         $self->plugins;
      $err = $_->filter_stderr($err) for @filters;
      $self->stderr($err)
   }
   $out .= "\n" unless $out =~ m/\n\Z/m;
   $self->stdout($out);
   return if $http_code == 2;
   return $http_code;
}

sub argv { $_[0]->{argv} }

sub uri_base {
   my ($self, $base) = @_;

   if ($base) {
      $base .= '*' unless $base =~ /\*/;
      $base = "http://$base" unless $base =~ m(^https?://);
      $self->_set_uri_base($base);
      return $base
   } else {
      $self->_get_uri_base
   }
}

sub _set_uri_base {
   my ($self, $base) = @_;

   my $file = $self->config_location->file('host');

   $file->touch unless -f $file->stringify;
   $file->spew($base);
}

sub _get_uri_base {
   my $self = shift;

   my $file = $self->config_location->file('host');
   ($file->slurp(chomp => 1))[0]
}

sub _set_extra_options {
   my ($self, @rest) = @_;

   my $file = $self->config_location->file('options');

   $file->touch unless -f $file->stringify;
   $file->spew(@rest);
}

sub _get_extra_options {
   my $self = shift;

   my $file = $self->config_location->file('options');
   $file->slurp(chomp => 1)
}

sub curl_command {
   my %arg = %{$_[1]};

   [qw(curl -sLv), $arg{data} || (), '-X', $arg{method},
      '-b', $arg{cookie_jar}, '-c', $arg{cookie_jar},
      @{$arg{rest}}, $arg{location}]
}

sub cookie_jar {
   my ($self, $uri) = @_;
   my $cookie_dir = $self->config_location->subdir('c');
   $cookie_dir->mkpath;
   my $path = $cookie_dir->file($self->host($uri));

   $path->touch unless -f $path->stringify;

   return $path->stringify;
}

sub _load_host_method_config {
   my ($self, $host) = @_;

   my $file = $self->config_location->file($host);
   $file->touch unless -f $file->stringify;
   $file->slurp(chomp => 1);
}

sub host_method_config {
   my ($self, $host, $method) = @_;

   my %config = map {
      m/^\s*($verb_regex)\s+(.*)/
         ? (uc($1), $2)
         : ()
   } $self->_load_host_method_config($host);

   if (my $ret = $config{$method}) {
      return ( shellwords($ret) )
   }
   return ()
}

sub host { URI->new($_[1])->host }

1;
