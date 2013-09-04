use Test::More;
use Test::Exception;

BEGIN 
{
    eval { require Test::Without::Module; };
    plan skip_all => "Test::Without::Module is required: $@" if $@;
}

plan tests => 3;

use_ok 'AnyEvent::Digest';

my $our;

use Test::Without::Module qw(AnyEvent::AIO);
throws_ok { $our = AnyEvent::Digest->new('Digest::MD5', backend => 'aio') } qr/aio backend requires IO::AIO and AnyEvent::AIO/, 'without AnyEvent::AIO';

no  Test::Without::Module qw(AnyEvent::AIO);
use Test::Without::Module qw(IO::AIO);
throws_ok { $our = AnyEvent::Digest->new('Digest::MD5', backend => 'aio') } qr/aio backend requires IO::AIO and AnyEvent::AIO/, 'without IO::AIO';
