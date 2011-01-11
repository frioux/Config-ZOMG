package Config::JFDI;
# ABSTRACT: Just * Do it: A Catalyst::Plugin::ConfigLoader-style layer over Config::Any

use warnings;
use strict;

use Any::Moose;

use Config::JFDI::Source::Loader;

use Config::Any;
use Hash::Merge::Simple;
use Clone qw//;

has package => (
   is => 'ro',
);

has source => (
   is => 'rw',
   handles => [qw/ driver local_suffix no_env env_lookup path found /],
);

has load_once => (
   is => 'ro',
   default => 1,
);

has loaded => (
   is => 'rw',
   default => 0,
);

has default => (
   is => 'ro',
   lazy_build => '1',
);
sub _build_default { {} }

has path_to => (
   is => 'ro',
   reader => '_path_to',
   lazy_build => '1',
);
sub _build_path_to {
    my $self = shift;
    return $self->config->{home} if $self->config->{home};
    return $self->source->path unless $self->source->path_is_file;
    return '.';
}

has _config => (
   is => 'rw',
);

sub BUILD {
    my $self = shift;
    my $given = shift;

    my ($source, %source);
    if ($given->{file}) {

        $given->{path} = $given->{file};
        $source{path_is_file} = 1;
    }

    {
        for (qw/
            name
            path
            driver

            no_local
            local_suffix

            no_env
            env_lookup

        /) {
            $source{$_} = $given->{$_} if exists $given->{$_};
        }

        warn "Warning, 'local_suffix' will be ignored if 'file' is given, use 'path' instead" if
            exists $source{local_suffix} && exists $given->{file};

        $source{local_suffix} = $given->{config_local_suffix} if $given->{config_local_suffix};

        $source = Config::JFDI::Source::Loader->new( %source );
    }

    $self->source($source);
}

sub open {
    if ( ! ref $_[0] ) {
        my $class = shift;
        return $class->new( no_06_warning => 1, 1 == @_ ? (file => $_[0]) : @_ )->open;
    }
    my $self = shift;
    warn "You called ->open on an instantiated object with arguments" if @_;
    return unless $self->found;
    return wantarray ? ($self->get, $self) : $self->get;
}

sub get {
    my $self = shift;

    my $config = $self->config;
    return $config;
    # TODO Expand to allow dotted key access (?)
}

sub config {
    my $self = shift;

    return $self->_config if $self->loaded;
    return $self->load;
}

sub load {
    my $self = shift;

    return $self->get if $self->loaded && $self->load_once;

    $self->_config($self->default);

    $self->_load($_) for $self->source->read;

    $self->loaded(1);

    return $self->config;
}

sub clone {
    my $self = shift;
    return Clone::clone($self->config);
}

sub reload {
    my $self = shift;
    $self->loaded(0);
    return $self->load;
}

sub _load {
    my $self = shift;
    my $cfg = shift;

    my ($file, $hash) = %$cfg;

    $self->_config(Hash::Merge::Simple->merge($self->_config, $hash));
}

1;

=head1 SYNPOSIS

 use Config::JFDI;

 my $config = Config::JFDI->new(
   name => 'my_application',
   path => 'path/to/my/application',
 );
 my $config_hash = $config->get;

This will look for something like (depending on what L<Config::Any> will find):

 path/to/my/application/my_application_local.{yml,yaml,cnf,conf,jsn,json,...}

and

 path/to/my/application/my_application.{yml,yaml,cnf,conf,jsn,json,...}

... and load the found configuration information appropiately, with C<_local>
taking precedence.

You can also specify a file directly:

 my $config = Config::JFDI->new(file => '/path/to/my/application/my_application.cnf');

To later reload your configuration:

 $config->reload;

=head1 DESCRIPTION

C<Config::JFDI> is an implementation of L<Catalyst::Plugin::ConfigLoader>
that exists outside of L<Catalyst>.

C<Config::JFDI> will scan a directory for files matching a certain name. If
such a file is found which also matches an extension that L<Config::Any> can
read, then the configuration from that file will be loaded.

C<Config::JFDI> will also look for special files that end with a C<_local>
suffix. Files with this special suffix will take precedence over any other
existing configuration file, if any. The precedence takes place by merging
the local configuration with the "standard" configuration via
L<Hash::Merge::Simple>.

Finally you can override/modify the path search from outside your application,
by setting the C<< ${NAME}_CONFIG >> variable outside your application (where
C<$NAME> is the uppercase version of what you passed to
L<< Config::JFDI->new|/new >>).

=head1 METHODS

=head2 new

 $config = Config::JFDI->new(...)

Returns a new Config::JFDI object

You can configure the $config object by passing the following to new:

    name                The name specifying the prefix of the configuration file to look for and
                        the ENV variable to read. This can be a package name. In any case,
                        :: will be substituted with _ in <name> and the result will be lowercased.

                        To prevent modification of <name>, pass it in as a scalar reference.

    path                The directory to search in

    file                Directly read the configuration from this file. Config::Any must recognize
                        the extension. Setting this will override path

    no_local            Disable lookup of a local configuration. The 'local_suffix' option will be ignored. Off by default

    local_suffix        The suffix to match when looking for a local configuration. "local" By default
                        ("config_local_suffix" will also work so as to be drop-in compatible with C::P::CL)

    no_env              Set this to 1 to disregard anything in the ENV. The 'env_lookup' option will be ignored. Off by default

    env_lookup          Additional ENV to check if $ENV{<NAME>...} is not found

    driver              A hash consisting of Config:: driver information. This is passed directly through
                        to Config::Any

    path_to             The path to dir to use for the __path_to(...)__ substitution. If nothing is given, then the 'home'
                        config value will be used ($config->get->{home}). Failing that, the current directory will be used.

    default             A hash filled with default keys/values

=head2 open

 $config_hash = Config::JFDI->open( ... )

As an alternative way to load a config C<open> will pass given arguments to
L</new> then attempt to do L</load>

Unlike L</get> or L</load> if no configuration files are found C<open> will
return C<undef> (or the empty list)

This is so you can do something like:

 my $config_hash = Config::JFDI->open( '/path/to/application.cnf' )
   or die "Couldn't find config file!"

In scalar context C<open> will return the config hash, B<not> the config
object. If you want the config object call C<open> in list context:

    my ($config_hash, $config) = Config::JFDI->open( ... )

You can pass any arguments to C<open> that you would to L</new>

=head2 get

 $config->get

=head2 config

 $config->config

=head2 load

 $config->load

Load a config as specified by L</new> and C<ENV> and return a hash

These will only load the configuration once, so it's safe to call them
multiple times without incurring any loading-time penalty

=head2 found

 $config->found

Returns a list of files found

If the list is empty then no files were loaded/read

=head2 clone

 $config->clone

Return a clone of the configuration hash using L<Clone>

This will load the configuration first, if it hasn't already

=head2 reload

 $config->reload

Reload the configuration, examining ENV and scanning the path anew

Returns a hash of the configuration

=head1 SEE ALSO

L<Catalyst::Plugin::ConfigLoader>

L<Config::Any>

L<Catalyst>

L<Config::Merge>

L<Config::General>

=cut

