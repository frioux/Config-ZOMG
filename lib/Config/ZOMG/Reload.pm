package Config::ZOMG::Reload;
#ABSTRACT: Configuration files via Config::ZOMG, reloaded on changes

use v5.14;

use Moo;
use Sub::Quote 'quote_sub';

use Config::ZOMG; # requires 0.002000;
use Digest::MD5 qw(md5_hex);
use Try::Tiny;

=head1 SYNOPSIS

    my $config = Config::ZOMG::AutoReload->new(
        wait => 60,     # check at most every minute (default)
        ...             # passed to Config::ZOMG
    );

    my $config_hash = $config->load;

    sleep(60);

    $config_hash = $config->load;   # reloaded

=head1 DESCRIPTION

This Perl package loads config files via L<Config::ZOMG>. Configuration is
reloaded on file changes (based on file names and last modification time).

This package is highly experimental!

=cut

has 'wait'  => (
    is => 'rw',
    default => quote_sub q{ 60 },
);

has 'error' => ( is => 'rw' );
has 'checked' => ( is => 'rw' );
has 'md5' => ( is => 'rw' );

has '_found' => ( is => 'rw', default => quote_sub q{ [ ] } );
has '_zomg' => ( is => 'rw', handles => [qw(find)] );

=head1 METHODS

=head2 new( %arguments )

In addition to L<Config::ZOMG>, one can specify a minimum time of delay between
checks with argument 'delay'.

=cut

sub BUILD {
    my $self = shift;
    my $given = shift;

    # don't pass to Config::ZOMG
    delete $given->{$_} for qw(wait error checked zomg);

    $self->_zomg( Config::ZOMG->new($given) );
}

=head2 load

Get the configuration hash, possibly (re)loading configuration files.

=cut

sub load {
    my $self = shift;
    my $zomg = $self->_zomg;

    if ($zomg->loaded) {
        if (time < $self->checked + $self->wait) {
            return ( $self->error ? { } : $zomg->load );
        } elsif ($self->md5 ne $self->_md5( $zomg->find )) {
            $zomg->loaded(0);
        }
    }

    $self->checked(time);

    try {
        if (!$zomg->loaded) {
            $self->error(undef);
            $zomg->load;
        }
        # save files to prevent Config::ZOMG::Source::Loader::read
        $self->_found([ $zomg->found ]);
        $self->md5( $self->_md5( $self->found ) );
    } catch {
        $self->error($_);
        $self->md5( $self->_md5() );
        $self->_found([ ]);
        return { };
    };

    return ( $self->error ? { } : $zomg->load );
}

=head wait

Number of seconds to wait between checking. Set to 60 by default.

=head checked

Timestamp of last time the files were loaded or checked.

=head2 md5

MD5 hash value based on files that have been found, their modification times and sizes.

=head2 find

A list of files that would be loaded.

=head2 found

A list of files found. In contrast to Config::ZOMG, calling this method
never triggers a load.

=cut

sub found {
    @{ $_[0]->_found };
}

sub _md5 {
    my $self = shift;
    md5_hex( map { my @s = stat($_); ($_, $s[9], $s[7]) } sort @_ );
}

1;
