package AnyEvent::Digest;

use strict;
use warnings;

# ABSTRACT: A tiny AnyEvent wrapper for Digest::*
# VERSION

use Carp;
use AnyEvent;
use Scalar::Util qw(refaddr);

# Most methods are falled back to Digest
our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;
    my $called = $AUTOLOAD =~ s/.*:://r;
    $self->{base}->$called(@_);
}

sub DESTROY {}

sub _by_idle
{
    my ($self, $cv, $work) = @_;
    my $call; $call = sub {
        if($work->()) {
            my $w; $w = AE::idle sub {
                undef $w;
                $call->();
            };
        } else {
            $cv->send($self);
        }
    };
    $call->();
}

sub _file_by_idle
{
    my ($self, $cv, $fh, $work) = @_;
    $self->_by_idle($cv, sub {
        read $fh, my $dat, $self->{unit};
        return $work->($dat);
    });
}

my %dispatch = (
    idle => \&_file_by_idle,
);

sub _dispatch
{
    my $method = $dispatch{$_[0]->{backend}};
    croak "Unknown backend $_[0]->{backend}" unless defined $method;
    return $method->(@_);
}

sub new
{
    my ($class, $base, %args) = @_;
    $class = ref $class || $class;
    $args{unit} ||= 65536;
    $args{backend} ||= 'idle';
    return bless {
        base => $base->new(@{$args{opts}}),
        map { $_, $args{$_} } qw(backend unit),
    }, $class;
}

sub add_async
{
    my $self = shift;
    my $cv = AE::cv;
    my (@dat) = @_;
    $self->_by_idle($cv, sub {
        my $dat = shift @dat;
        $self->{base}->add($dat);
        return scalar @dat;
    });
    return $cv;
}

sub addfile_async
{
    my ($self, $target, $mode) = @_;
    my $cv = AE::cv;
    my $fh;
    if(ref $target) {
        $fh = $target;
    } else {
        open $fh, '<:raw', $target;
    }
    $self->_dispatch($cv, $fh, sub {
        my $dat = shift;
        $self->{base}->add($dat);
        close $fh if eof $fh;
        return ! eof $fh;
    });
    return $cv;
}

sub addfile
{
    return shift->addfile_async(@_)->recv;
}

sub addfile_base
{
    return shift->{base}->addfile(@_);
}

sub add_bits_async
{
    my $self = shift;
    my $cv = AE::cv;
    $self->{base}->add_bits(@_);
    $cv->send($self);
    return $cv;
}

1;
__END__

=head1 SYNOPSIS

  use AnyEvent::Digest;
  use Digest::SHA;
  my $ctx = AnyEvent::Digest->new('SHA', opts => [1], unit => 65536, backend => 'IO::AIO');
  # In addition that $ctx can be used as Digest::* object, you can call add*_async()
  $ctx->addfile_async($file)->recv(sub {
    # Do something like the followings
    my $ctx = $_[0]->recv;
    print $ctx->hexdigest;
  });

=head1 DESCRIPTION

To calculate message digest for large files may take several seconds.
It may block your program even if you use L<AnyEvent>.
This module is a tiny AnyEvent wrapper for Digest::* modules,
not to block your program during digest calculation.

=head1 METHODS

In addition to the following methods, other methods are forwarded to the base module.

=method C<new($base, %args)>

This is a constructor method.
C<$base> specifies a module name for base implementation, which is expected to be one of C<Digest::*> modules.
Available keys of C<%args> are as follows:

=for :list
= C<opts>
passed to C<$base::new> as C<@{$args{opts}}>. It must be an array reference.
= C<unit>
specifies an amount of one time read for addfile(). Defaults to 65536 = 64KiB.
= C<backend>
specifies a backend module to handle asynchronous read. Currently, only C<'idle'> is available and default.

=method C<add_async(@dat)>

Each item in C<@dat> are added by C<add($dat)>.
Between the adjacent C<add()>, other AnyEvent watchers have chances to run.
It returns a condition variable receiving this object itself.

=method C<addfile_async($filename)>

=method C<addfile_async(*handle)>

C<add()> is called repeatedly read from C<$filename> or C<*handle> by the specified unit.
Between the adjacent C<add()>, other AnyEvent watchers have chances to run.
It returns a condition variable receiving this object itself.

=method C<add_bits_async()>

Same as C<add_bits()>, except it returns a condition variable receiving this object itself.

=method C<addfile()>

This method uses blocking wait + C<addfile_async()>.

=method C<addfile_base()>

Forwarded to C<addfile()> in the base module.

=cut
