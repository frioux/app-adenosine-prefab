package App::Adenosine::Plugin::Rainbow;

use Moo;
use Term::ExtendedColor ':all';

with 'App::Adenosine::Role::FiltersStdErr';

our %old_colormap = (
   red => 1,
   green => 2,
   yellow => 3,
   blue => 4,
   purple => 5,
   cyan => 6,
   white => 7,
   gray => 8,
   bright_red => 9,
   bright_green => 10,
   bright_yellow => 11,
   bright_blue => 12,
   magenta => 13,
   bright_cyan => 14,
   bright_white => 15,
);

sub colorize {
   my ($self, $arg, $str) = @_;

   $arg = { fg => $arg } unless ref $arg;

   for (qw(fg bg)) {
      $arg->{$_} = $old_colormap{$arg->{$_}}
         if $arg->{$_} && exists $old_colormap{$arg->{$_}}
   }

   $str = fg($arg->{fg}, $str ) if $arg->{fg};
   $str = bg($arg->{bg}, $str ) if $arg->{bg};
   $str = bold($str           ) if $arg->{bold};
   $str = italic($str         ) if $arg->{italic};
   $str = underline($str      ) if $arg->{underline};

   return $str;
}

has response_header_colon_color => (
   is => 'ro',
   default => sub { 'blue' },
);

has response_header_name_color => (
   is => 'ro',
   default => sub { 'cyan' },
);

has response_header_value_color => (
   is => 'ro',
   default => sub { 'bright_cyan' },
);

has request_header_colon_color => (
   is => 'ro',
   default => sub { 'red' },
);

has request_header_name_color => (
   is => 'ro',
   default => sub { 'purple' },
);

has request_header_value_color => (
   is => 'ro',
   default => sub { 'magenta' },
);

has info_star_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has response_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has request_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has request_method_color => (
   is => 'ro',
   default => sub { 'red' },
);

has request_uri_color => (
   is => 'ro',
   default => sub { {} },
);

has request_protocol_color => (
   is => 'ro',
   default => sub { {} },
);

has request_protocol_version_color => (
   is => 'ro',
   default => sub { 'bright_white' },
);

has response_protocol_color => (
   is => 'ro',
   default => sub { {} },
);

has response_protocol_version_color => (
   is => 'ro',
   default => sub { 'bright_white' },
);

has response_status_code_color => (
   is => 'ro',
   default => sub { 'red' },
);

has response_status_text_color => (
   is => 'ro',
   default => sub { {} },
);

has response_ellided_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has response_ellided_body_color => (
   is => 'ro',
   default => sub { 'blue' },
);

has request_ellided_bracket_color => (
   is => 'ro',
   default => sub { 'yellow' },
);

has request_ellided_body_color => (
   is => 'ro',
   default => sub { 'blue' },
);
our $timestamp_re = qr/^(.*?)(\d\d):(\d\d):(\d\d)\.(\d{6})(.*)$/;
# this is probably not right...
our $header_re = qr/^(.+?):\s*(.+)$/;
our $methods_re = qr/HEAD|PUT|POST|GET|DELETE|OPTIONS|TRACE/;
our $request_re = qr<^($methods_re) (.*) (HTTP)/(1\.[01])$>;
our $response_re = qr<^(HTTP)/(1\.[01]) (\d{3}) (.*)$>;

sub filter_request_ellided_body {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   return $pre .
      $self->colorize($self->request_ellided_bracket_color, '} ') .
      $self->colorize($self->request_ellided_body_color, $post)
}
sub filter_response_ellided_body {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   return $pre .
      $self->colorize($self->response_ellided_bracket_color, '{ ') .
      $self->colorize($self->response_ellided_body_color, $post)
}
sub filter_response_init {
   my ($self, $proto, $ver, $code, $status, $colors) = @_;

   return $self->colorize($colors->{protocol}, $proto) . '/' .
          $self->colorize($colors->{protocol_version}, $ver) . ' ' .
          $self->colorize($colors->{status_code}, $code) . ' ' .
          $self->colorize($colors->{status_text}, $status)
}
sub filter_request_init {
   my ($self, $method, $uri, $proto, $version, $colors) = @_;

   return $self->colorize($colors->{method}, $method) . ' ' .
          $self->colorize($colors->{uri}, $uri) . ' ' .
          $self->colorize($colors->{protocol}, $proto) . '/' .
          $self->colorize($colors->{protocol_version}, $version)
}
sub filter_header {
   my ($self, $name, $value, $colors) = @_;

   return $self->colorize($colors->{name}, $name)  .
          $self->colorize($colors->{colon}, ': ').
          $self->colorize($colors->{value}, $value)

}
sub filter_timestamp {
   my ($self, $pre, $h, $m, $s, $u, $post) = @_;

   return "$pre$h:$m:$s.$u$post";
}
sub filter_info {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   return $pre .
      $self->colorize($self->info_star_color, '* ') .
      $post
}
sub filter_response {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   if (my @match = $post =~ $header_re ){
      $post = $self->filter_header(@match, {
         name  => $self->response_header_name_color,
         colon => $self->response_header_colon_color,
         value => $self->response_header_value_color,
      })
   } elsif (my @match2 = $post =~ $response_re) {
      $post = $self->filter_response_init(@match2, {
         protocol         => $self->response_protocol_color,
         protocol_version => $self->response_protocol_version_color,
         status_code      => $self->response_status_code_color,
         status_text      => $self->response_status_text_color,
      })
   }
   return $pre .
      $self->colorize($self->response_bracket_color, '< ') .
      $post
}
sub filter_request {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   if (my @match = ( $post =~ $header_re ) ) {
      $post = $self->filter_header(@match, {
         name  => $self->request_header_name_color,
         colon => $self->request_header_colon_color,
         value => $self->request_header_value_color,
      })
   } elsif (my @match2 = ( $post =~ $request_re ) ) {
      $post = $self->filter_request_init(@match2, {
         method           => $self->request_method_color,
         uri              => $self->request_uri_color,
         protocol         => $self->request_protocol_color,
         protocol_version => $self->request_protocol_version_color,
      })
   }
   return $pre .
      $self->colorize($self->request_bracket_color, '> ') .
      $post
}
sub filter_stderr {
   my ($self, $err) = @_;

   my @out;
   for my $line (map { s/\r$//; $_ } split /\n/, $err) {
      if ($line =~ /^(.*)\* (.*)$/) {
         $line = $self->filter_info($1, $2)
      } elsif ($line =~ /^(.*)< (.*)$/) {
         $line = $self->filter_response($1, $2)
      } elsif ($line =~ /^(.*)> (.*)$/) {
         $line = $self->filter_request($1, $2)
      } elsif ($line =~ /^(.*){ (.*)$/) {
         $line = $self->filter_response_ellided_body($1, $2)
      } elsif ($line =~ /^(.*)} (.*)$/) {
         $line = $self->filter_request_ellided_body($1, $2)
      }
      push @out, $line
   }
   return join "\n", @out, ''
}

1;
