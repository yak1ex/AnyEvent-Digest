use Test::More tests => 4;
use Test::Exception;

use_ok 'AnyEvent::Digest';

use AnyEvent;
use Digest::MD5;
use File::Temp;

my $ref = Digest::MD5->new;
my $our;
lives_ok { $our = AnyEvent::Digest->new('Digest::MD5', backend => 'aio') } 'construction';

my $count = 0;
my $w; $w = AE::timer 0, 1, sub {
    ++$count;
};

my $fh = File::Temp->new;
print $fh  "\x0" x (1024 * 1024) for 1..512;
seek $fh, 0, 0;
#my $expected = $ref->addfile($fh)->hexdigest;
$expected = 'aa559b4e3523a6c931f08f4df52d58f2';
diag $expected;

my $cv = AE::cv;
$our->addfile_async($fh->filename)->cb(sub {
    is($expected, shift->recv->hexdigest, 'add -> digest');
    ok($count > 0);
    diag($count);
    undef $w;
    $cv->send;
});

$cv->recv;

