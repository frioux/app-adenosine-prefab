#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Devel::Dwarn;

TestResty->new({ argv => ['http://google.com'] });
is($TestResty::stdout, "http://google.com*\n", 'http no *');

TestResty->new({ argv => ['google.com'] });
is($TestResty::stdout, "http://google.com*\n", 'just domain');

TestResty->new({ argv => [] });
is($TestResty::stdout, "http://google.com*\n", 'no args');

TestResty->new({ argv => ['https://google.com/user/*/1'] });
is($TestResty::stdout, "https://google.com/user/*/1\n", 'https + *');

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

$TestResty::curl_stdout = <<'BLUU2';
{"some":"json"}
BLUU2

my $exit_code = TestResty->new({ argv => ['GET'] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv -X GET -b /home/frew/.resty/c/google.com https://google.com/user//1),
], 'GET');
is($TestResty::stdout, $TestResty::curl_stdout, 'output the right stuff!');

ok(!$exit_code, '200 means exit with 0');

$TestResty::curl_stderr =~ s[(< HTTP/1\.1 )2][${1}5];
$exit_code = TestResty->new({ argv => [qw(GET 1 -v)] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv -X GET -b /home/frew/.resty/c/google.com https://google.com/user/1/1),
], 'GET 1');
is($exit_code, 5, '500 exits correctly');
is($TestResty::stderr, "curl -sLv -X GET -b /home/frew/.resty/c/google.com https://google.com/user/1/1
$TestResty::curl_stderr", '-v works');

TestResty->new({ argv => [qw(POST 2), '{"foo":"bar"}'] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv {"foo":"bar"} -X POST -b /home/frew/.resty/c/google.com
      --data-binary https://google.com/user/2/1),
], 'POST 2 $data');

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
}

# to capture: config
