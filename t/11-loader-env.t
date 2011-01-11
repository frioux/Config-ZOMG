use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use Config::JFDI;

$ENV{XYZZY_CONFIG} = "t/assets/some_random_file.pl";

my $config = Config::JFDI->new(qw{ name xyzzy path t/assets });

ok($config->load);
is($config->load->{'Controller::Foo'}->{foo},       'bar');
is($config->load->{'Model::Baz'}->{qux},            'xyzzy');
is($config->load->{'view'},                         'View::TT');
is($config->load->{'random'},                        1);
#is($config->load->{'foo_sub'},                      '__foo(x,y)__' );
#is($config->load->{'literal_macro'},                '__literal(__DATA__)__');

$ENV{XYZZY_CONFIG} = "t/assets/some_non_existent_file.pl";

$config->reload;

ok($config->load);
is(scalar keys %{ $config->load }, 0);
