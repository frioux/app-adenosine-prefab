#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

$ENV{PATH} = "t/bin:$ENV{PATH}";
$ENV{EDITOR} = 'bluh';

TestResty->new({ argv => ['http://google.com'] });
is($TestResty::stdout, "http://google.com*\n", 'http no *');
is($TestResty::uri_base, "http://google.com*", 'uri_base set');
cmp_deeply(\@TestResty::extra_options, [], 'extra options set');

TestResty->new({ argv => ['google.com', '-v', '-H', 'Foo: Bar'] });
is($TestResty::stdout, "http://google.com*\n", 'just domain');
is($TestResty::uri_base, "http://google.com*", 'uri_base set');
cmp_deeply(\@TestResty::extra_options, ['-v', '-H', 'Foo: Bar'], 'extra options set');

TestResty->new({ argv => [] });
is($TestResty::stdout, "http://google.com*\n", 'no args');
cmp_deeply(\@TestResty::extra_options, ['-v', '-H', 'Foo: Bar'], 'extra options remain');

TestResty->new({ argv => ['https://google.com/user/*/1'] });
is($TestResty::stdout, "https://google.com/user/*/1\n", 'https + *');
is($TestResty::uri_base, "https://google.com/user/*/1", 'uri_base set');
cmp_deeply(\@TestResty::extra_options, [], 'extra options cleared');

$TestResty::curl_stderr = <<'BLUUU';
* About to connect() to google.com port 80 (#0)
*   Trying 167.10.21.20... connected
> HEAD / HTTP/1.1
> User-Agent: curl/7.22.0 (x86_64-pc-linux-gnu) libcurl/7.22.0 OpenSSL/1.0.1 zlib/1.2.3.4 libidn/1.23 librtmp/2.3
> Host: google.com
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Thu, 08 Nov 2012 23:22:28 GMT
< Server: HTTP::Server::PSGI
< Content-Type: application/json
< X-Catalyst: 5.90015
< Vary: Accept-Encoding,User-Agent
* no chunk, no close, no size. Assume close to signal end
<
* Closing connection #0
BLUUU

%TestResty::host_config = ( 'google.com' => <<'CONFIG' );
 GET -H 'Accept: text/html'

 POST -u foo:bar
CONFIG

$TestResty::curl_stdout = <<'BLUU2';
{"some":"json"}
BLUU2

my $exit_code = TestResty->new({ argv => ['GET'] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv -X GET -b /home/frew/.resty/c/google.com -H ), 'Accept: text/html', 'https://google.com/user//1',
], 'GET');
is($TestResty::stdout, $TestResty::curl_stdout, 'output the right stuff!');

ok(!$exit_code, '200 means exit with 0');

$TestResty::curl_stderr =~ s[(< HTTP/1\.1 )2][${1}5];
$exit_code = TestResty->new({ argv => [qw(GET 1 -v)] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv -X GET -b /home/frew/.resty/c/google.com -H ), 'Accept: text/html', 'https://google.com/user/1/1',
], 'GET 1');
is($exit_code, 5, '500 exits correctly');
is($TestResty::stderr, "'curl' '-sLv' '-X' 'GET' '-b' '/home/frew/.resty/c/google.com' '-H' 'Accept: text/html' 'https://google.com/user/1/1'
$TestResty::curl_stderr", '-v works');

TestResty->new({ argv => [qw(POST 2), '{"foo":"bar"}'] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv {"foo":"bar"} -X POST -b /home/frew/.resty/c/google.com
      --data-binary -u foo:bar https://google.com/user/2/1),
], 'POST 2 $data');

TestResty->new({ argv => [qw(POST 2), '-V'] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv), '["frew","bar","baz"]', qw(-X POST -b /home/frew/.resty/c/google.com
      --data-binary -u foo:bar https://google.com/user/2/1),
], 'POST -V $data');

TestResty->new({ argv => [qw(HEAD -u)] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv -X HEAD -b /home/frew/.resty/c/google.com
     -u -I https://google.com/user//1),
], 'HEAD adds -I');

done_testing;

BEGIN {
   package TestResty;

   use strict;
   use warnings;

   use MRO::Compat;

   use lib 'lib';
   use base 'Resty';

   our @curl_options;
   our $stdout = '';
   our $stderr = '';
   our $curl_stderr;
   our $curl_stdout;
   our $uri_base;
   our %host_config;
   our @extra_options;

   sub _set_uri_base { $uri_base = $_[1] }
   sub _get_uri_base { $uri_base }
   sub _load_host_method_config { split /\n/, $host_config{$_[1] || ''} }

   sub new {
      my $self = shift;

      $stdout = '';
      $stderr = '';

      $self->next::method(@_)
   }

   sub capture_curl {
      my $self = shift;
      @curl_options = @_;

      return ($curl_stdout, $curl_stderr, 0);
   }

   sub stdout { $stdout .= $_[1] }
   sub stderr { $stderr .= $_[1] }

   sub _set_extra_options { my $self = shift; @extra_options = @_ }
   sub _get_extra_options { @extra_options }
}

# to capture: config
