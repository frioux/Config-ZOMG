use strict;
use warnings;

use Test::More;
use Test::Deep;

use Config::ZOMG;

sub has_Config_General {
    return eval "require Config::General;";
}

{
    my $config = Config::ZOMG->new( file => 't/assets/some_random_file.pl', quiet_deprecation => 1 );

    ok( $config->load );
    ok( keys %{ $config->load } );
    ok( $config->found );
    cmp_deeply( [ $config->found ], bag( 't/assets/some_random_file.pl' ) );
}

{
    my $config = Config::ZOMG->new( qw{ name xyzzy path t/assets } );
    ok( $config->load );
    ok( keys %{ $config->load } );
    ok( $config->found );
    cmp_deeply( [ $config->found ], bag( 't/assets/xyzzy.pl', 't/assets/xyzzy_local.pl' ) );
}

{
    my $config = Config::ZOMG->new( file => 't/assets/missing-file.pl', quiet_deprecation => 1 );

    ok( $config->load );
    cmp_deeply( $config->load, {} );
    ok( !$config->found );
}

{
    my $config = Config::ZOMG->new( file => 't/assets/some_random_file.pl', quiet_deprecation => 1 );

    ok( $config->found ); # Do ->read via ->found
    ok( $config->load );
    ok( keys %{ $config->load } );
    cmp_deeply( [ $config->found ], bag( 't/assets/some_random_file.pl' ) );
}

done_testing;
