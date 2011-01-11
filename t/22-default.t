use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use Config::JFDI;
my $config;

$config = Config::JFDI->new(
    qw{ name default path t/assets },
    default => {
        home => 'a-galaxy-far-far-away',
        test => 'alpha',
    },
);

is($config->get->{home}, 'a-galaxy-far-far-away');
is($config->get->{path_to}, '__path_to(tatooine)__');
is($config->get->{test}, 'beta');
