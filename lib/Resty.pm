package Resty;

use strict;
use warnings;

use Getopt::Long qw(:config pass_through no_ignore_case);
use File::Path 'mkpath';
use URI::Escape 'uri_escape';
use File::Spec::Functions 'splitpath';

our $verb_regex = '(?:HEAD|OPTIONS|GET|DELETE|PUT|POST|TRACE)';

sub verbose { $_[0]->{verbose} }

sub new {
   my ($class, $args) = @_;

   my $self = { %$args };

   bless $self, $class;

   local @ARGV = @{$self->argv};

   my $quote = 1;
   my $history = 1;
   my $interactive_edit = 0;
   my $query = '';
   $self->{verbose} = 0;

   my $action = shift @ARGV;
   my $path   = shift @ARGV unless $ARGV[0] && $ARGV[0] =~ /^-/;
   my $data   = shift @ARGV unless $ARGV[0] && $ARGV[0] =~ /^-/;

   $path ||= '';
   $data ||= '';

   GetOptions (
      Q     => sub { $quote = 0 },
      "q=s" => \$query,
      W     => sub { $history = 0 },
      V     => \$interactive_edit,
      v     => sub { $self->{verbose} = 1 },
   );

   chomp(my $uri_base = load_uri_base());

   $self->stdout("$uri_base\n"), $self->exit if !$action;

   if ($action =~ m/^$verb_regex$/) {
      my @extra = @ARGV;
      my $wantdata;
      $wantdata = 1 if $action =~ m/^(?:PUT|POST|TRACE)$/;
      if ($wantdata && $interactive_edit) {
         require File::Temp;
         my ($fh, $fn) = File::Temp::tempfile();

         system($ENV{EDITOR} || 'vi', $fn);

         $data = slurp($fn);
      }

      push @extra, '--data-binary' if $data;
      push @extra, '-I' if $action eq 'HEAD';

      my $_path = $uri_base;
      $_path =~ s/\*/$path/;

      $query = uri_escape($query) if $quote;

      push @extra, host_method_config( host($uri_base), $action );

      $query = "?$query" if $query;

      my @curl = @{curl_command({
         method => $action,
         data   => $data,
         cookie_jar => cookie_jar($uri_base),
         rest => \@extra,
         location => "$_path$query",
      })};

      warn join(" ", @curl) . "\n" if $self->verbose;

      my ($out, $err, $ret) = $self->capture_curl(@curl);
      $self->handle_curl_output($out, $err, $ret);
   } else {
      store_uri_base($action);
      chomp(my $uri_base = load_uri_base());
      $self->stdout("$uri_base\n"), $self->exit
   }
}

sub stdout { print STDOUT $_[1] }
sub stderr { print STDERR $_[1] }
sub exit { CORE::exit($_[0] || 0) }

sub capture_curl {
   my ($self, @rest) = @_;

   require Capture::Tiny;
   Capture::Tiny::capture(sub { system(@rest) });
}

sub handle_curl_output {
   my ($self, $out, $err, $ret) = @_;

   my ( $http_code ) = ($err =~ m{.*HTTP/1\.[01] (\d)\d\d });
   $self->stderr($err) if $err && $self->verbose;
   $out .= "\n" unless $out =~ m/\n\Z/m;
   $self->stdout($out);
   $self->exit if $http_code == 2;
   $self->exit($http_code);
}

sub argv { $_[0]->{argv} }

sub config_location {
   my $loc;
   if (my $h = $ENV{XDG_CONFIG_HOME}) {
      $loc = "$h/resty"
   } else {
      $loc = "$ENV{HOME}/.resty"
   }
   mkpath($loc) unless -d $loc;
   return $loc;
}

sub host_location { config_location() . '/host' }

sub load_uri_base { slurp(host_location()) }

sub store_uri_base {
   my ($base) = @_;
   $base .= '*' unless $base =~ /\*/;
   $base = "http://$base" unless $base =~ m(^https?://);
   open my $fh, '>', host_location();
   print {$fh} $base;
}

sub slurp { do { local (@ARGV, $/) = $_[0]; <> } }

sub curl_command {
   my %arg = %{$_[0]};

   [qw(curl -sLv), $arg{data} || (), '-X', $arg{method}, '-b', $arg{cookie_jar},
      @{$arg{rest}}, $arg{location}]
}

sub cookie_jar {
   _touch(config_location() . '/c/' . host($_[0]))
}

sub host_method_config {
   my ($host, $method) = @_;

   my %config = map {
      m/\s*($verb_regex)\s+(.*)/
         ? ($1, $2)
         : ()
   } split /\n/, slurp(_touch(config_location() . "/$host")) || '';

   return split /\s+/, $config{$method} || ""
}

sub host {
   my $ret = $_[0];

   $ret =~ s(^\w+://)();
   $ret =~ s(/.*)()g;
   $ret =~ s(\*)();
   return $ret
}

sub _touch {
   my $path = shift;
   my ($drive, $dir, $file) = splitpath($path);
   mkpath("$drive/$dir") unless -d "$drive/$dir";
   open my $fh, '>>', $path unless -f $path;
   return $path
}

1;
