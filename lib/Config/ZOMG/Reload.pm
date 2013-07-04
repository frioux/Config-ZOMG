package Config::ZOMG::Reload;
#ABSTRACT: Configuration files via Config::ZOMG, reloaded on changes

use v5.14;
use Config::ZOMG 0.002000;
use Digest::MD5 qw(md5);
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

=head1 METHODS

=head2 new( %arguments )

In addition to L<Config::ZOMG>, one can specify a minimum time of delay between
checks with argument 'delay'.

=cut

sub new {
    my ($class, %args) = @_;

    bless {
        wait  => delete $args{delay} // 60,
        zomg  => Config::ZOMG->new( %args ),
    }, $class;
}

=head2 load

Get the configuration hash, possibly (re)loading configuration files.

=cut

sub load {
    my $self = shift;
    my $zomg = $self->{zomg};

    if ($zomg->loaded) {
        if (time < $self->{checked} + $self->{wait}) {
            return ( $self->{error} ? { } : $zomg->load );
        } elsif ($self->{md5} != $self->_md5( $zomg->find )) {
            $zomg->loaded(0);
        }
    }

    try {
        if (!$zomg->loaded) {
            $self->{error} = undef;
            $zomg->load;
        }
        # save files to prevent Config::ZOMG::Source::Loader::read
        $self->{found} = [ $zomg->found ];
        $self->{md5} = $self->_md5( @{ $self->{found} } );
    } catch {
        $self->{error} = $_;
        $self->{md5} = $self->_md5();
        $self->{found} = [ ];
        return { };
    };

    $self->{checked} = time;

    return ( $self->{error} ? { } : $zomg->load );
}

=head checked

Returns a timestamp of last time the files were loaded or checked.

=cut

sub checked {
    $_[0]->{checked};
}

=head2 found

Returns a list of files found. In contrast to Config::ZOMG, calling this method
never triggers a load.

=cut

sub found {
    $_[0]->{found} ? @{ $_[0]->{found} } : ();
}

# calculate MD5 based on file names and last modify time
sub _md5 {
    my $self = shift;
    md5( map { ($_, (stat($_))[9]) } sort @_ );
}

1;
