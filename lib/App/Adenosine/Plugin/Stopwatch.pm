package App::Adenosine::Plugin::Stopwatch;

use Moo;

use Time::HiRes qw(gettimeofday tv_interval);

with 'App::Adenosine::Role::WrapsCurlCommand';

sub wrap {
   my ($self, $cmd) = @_;

   return sub {
      my $t0 = [gettimeofday];
      my @ret = $cmd->(@_);
      $ret[1] .= "* Total Time: " . $self->render_duration(tv_interval ( $t0 ));
      return @ret;
   }
}

sub render_duration {
   my ($self, $seconds) = @_;
   if ($seconds < 1 ) {
      return sprintf('%0.f ms', $seconds * 1000);
   } else {
      return sprintf('%1.3f s', $seconds);
   }
}

1;

__END__

=pod

=head1 DESCRIPTION

Appends handy timer information to curl's stderr, giving the user a simple way
to understand the duration of a requestion.

=method render_duration

Takes a scalar of seconds and renders them as a string.  If you are subclassing
this plugin to add color coding, for example, you just need to override this
method.

=method wrap

(internal) wraps the curl command to get timing data and append the duration.
