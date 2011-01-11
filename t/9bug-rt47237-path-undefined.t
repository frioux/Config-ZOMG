#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;

use Config::JFDI;

my $config = Config::JFDI->new( name => '' );
warning_is { $config->_path_to } undef;

done_testing;
