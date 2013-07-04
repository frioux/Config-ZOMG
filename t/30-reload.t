use strict;
use warnings;

use Test::More;
plan qw/no_plan/;

use File::Temp qw(tempdir);
use Config::ZOMG::Reload;

my $tempdir = tempdir();
my $inifile = "$tempdir/foo.ini";
my $jsonfile = "$tempdir/foo.json";

create($inifile, "foo = 42");

my $config = Config::ZOMG::Reload->new( 
    path => $tempdir, name => 'foo',
);

ok($config->load, 'load');
is($config->load->{foo}, 42);
is_deeply([ $config->found ], [ $inifile ], 'found file');

append($inifile, "bar = 23");
is($config->load->{bar}, undef);

touch( $inifile, time - 1 );
is($config->load->{bar}, undef, 'wait before checking');

$config->wait(0);
is($config->load->{bar}, 23, 'reload after waiting');

create($inifile, "=");
is_deeply($config->load, { }, 'error');
ok($config->error);

create($inifile, "doz = bar");
is($config->load->{doz}, "bar");
ok(!$config->error, 'error fixed');

is_deeply( [$config->find], [$config->found] );

sub create {
    open my $fh, '>', shift;
    print $fh "$_\n" for @_;
    close $fh;
}

sub append {
    open my $fh, '>>', shift;
    print $fh "$_\n" for @_;
    close $fh;
}

sub touch {
    my $file = shift;
    my $time = @_ ? shift : time;
    utime $time, $time, $file;
}
