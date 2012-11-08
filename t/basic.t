#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Devel::Dwarn;

TestResty->new({ argv => ['http://google.com'] });
Dwarn \@TestResty::curl_options;

TestResty->new({ argv => ['google.com'] });
Dwarn \@TestResty::curl_options;

TestResty->new({ argv => ['https://google.com/user/*/1'] });
Dwarn \@TestResty::curl_options;

TestResty->new({ argv => ['GET'] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv -X GET -b /home/frew/.resty/c/google.com https://google.com/user//1),
], 'GET');

TestResty->new({ argv => [qw(GET 1)] });
cmp_deeply(\@TestResty::curl_options, [
   qw(curl -sLv -X GET -b /home/frew/.resty/c/google.com https://google.com/user/1/1),
], 'GET 1');

TestResty->new({ argv => [qw(POST /), '{"foo":"bar"}'] });
Dwarn \@TestResty::curl_options;

TestResty->new({ argv => [qw(POST /), '{"foo":"bar"}'] });
Dwarn \@TestResty::curl_options;

done_testing;

BEGIN {
   package TestResty;

   use strict;
   use warnings;

   use lib 'lib';
   use base 'Resty';

   our @curl_options;
   our $exit_code;
   our $stdout = '';
   our $stderr = '';

   sub capture_curl {
      my $self = shift;
      @curl_options = @_;

      return ('', '', 0);
   }

   sub exit { $exit_code = shift }
   sub stdout { $stdout .= shift }
   sub stderr { $stderr .= shift }
}

# to capture: stdout, stderr, return code, curl command
