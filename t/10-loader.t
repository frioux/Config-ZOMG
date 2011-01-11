use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use Config::JFDI;

my $config = Config::JFDI->new(qw{ name xyzzy path t/assets });

ok($config->load);
is($config->load->{'Controller::Foo'}->{foo},         'bar');
is($config->load->{'Controller::Foo'}->{new},         'key');
is($config->load->{'Model::Baz'}->{qux},              'xyzzy');
is($config->load->{'Model::Baz'}->{another},          'new key');
is($config->load->{'view'},                           'View::TT::New');
#is($config->load->{'foo_sub'},                       'x-y');
is($config->load->{'foo_sub'},                        '__foo(x,y)__');
#is($config->load->{'literal_macro'},                 '__DATA__');
is($config->load->{'literal_macro'},                  '__literal(__DATA__)__');

ok(1);
