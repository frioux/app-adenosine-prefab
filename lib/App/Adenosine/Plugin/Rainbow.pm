package App::Adenosine::Plugin::Rainbow;

use Moo;
use Term::ANSIColor 'colored';

with 'App::Adenosine::Role::FiltersStdErr';

has response_header_colon_color => (
   is => 'ro',
   default => sub { [qw(blue)] },
);

has response_header_name_color => (
   is => 'ro',
   default => sub { [qw(cyan)] },
);

has response_header_value_color => (
   is => 'ro',
   default => sub { [qw(bold cyan)] },
);

has request_header_colon_color => (
   is => 'ro',
   default => sub { [qw(red)] },
);

has request_header_name_color => (
   is => 'ro',
   default => sub { [qw(magenta)] },
);

has request_header_value_color => (
   is => 'ro',
   default => sub { [qw(bold magenta)] },
);

has info_star_color => (
   is => 'ro',
   default => sub { [qw(yellow)] },
);

has response_bracket_color => (
   is => 'ro',
   default => sub { [qw(yellow)] },
);

has request_bracket_color => (
   is => 'ro',
   default => sub { [qw(yellow)] },
);

has request_method_color => (
   is => 'ro',
   default => sub { [qw(red)] },
);

has request_uri_color => (
   is => 'ro',
   default => sub { [] },
);

has request_protocol_color => (
   is => 'ro',
   default => sub { [] },
);

has request_protocol_version_color => (
   is => 'ro',
   default => sub { [qw(bold white)] },
);

has response_protocol_color => (
   is => 'ro',
   default => sub { [] },
);

has response_protocol_version_color => (
   is => 'ro',
   default => sub { [qw(bold white)] },
);

has response_status_code_color => (
   is => 'ro',
   default => sub { [qw(red)] },
);

has response_status_text_color => (
   is => 'ro',
   default => sub { [qw()] },
);

has response_ellided_bracket_color => (
   is => 'ro',
   default => sub { [qw(yellow)] },
);

has response_ellided_body_color => (
   is => 'ro',
   default => sub { [qw(blue)] },
);

has request_ellided_bracket_color => (
   is => 'ro',
   default => sub { [qw(yellow)] },
);

has request_ellided_body_color => (
   is => 'ro',
   default => sub { [qw(blue)] },
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
      colored($self->request_ellided_bracket_color, '} ') .
      colored($self->request_ellided_body_color, $post)
}
sub filter_response_ellided_body {
   my ($self, $pre, $post) = @_;

   if (my @m = $pre =~ $timestamp_re) {
      $pre = $self->filter_timestamp(@m)
   }

   return $pre .
      colored($self->response_ellided_bracket_color, '{ ') .
      colored($self->response_ellided_body_color, $post)
}
sub filter_response_init {
   my ($self, $proto, $ver, $code, $status, $colors) = @_;

   return colored($colors->{protocol}, $proto) . '/' .
          colored($colors->{protocol_version}, $ver) . ' ' .
          colored($colors->{status_code}, $code) . ' ' .
          colored($colors->{status_text}, $status)
}
sub filter_request_init {
   my ($self, $method, $uri, $proto, $version, $colors) = @_;

   return colored($colors->{method}, $method) . ' ' .
          colored($colors->{uri}, $uri) . ' ' .
          colored($colors->{protocol}, $proto) . '/' .
          colored($colors->{protocol_version}, $version)
}
sub filter_header {
   my ($self, $name, $value, $colors) = @_;

   return colored($colors->{name}, $name)  .
          colored($colors->{colon}, ': ').
          colored($colors->{value}, $value)

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
      colored($self->info_star_color, '* ') .
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
      colored($self->response_bracket_color, '< ') .
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
      colored($self->request_bracket_color, '> ') .
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
