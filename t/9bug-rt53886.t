#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;

use Config::JFDI;

warning_is { Config::JFDI->new( local_suffix => 'local' ) } undef;
warning_like { Config::JFDI->new( file => 'xyzzy',local_suffix => 'local' ) } qr/will be ignored if 'file' is given, use 'path' instead/;

done_testing;
