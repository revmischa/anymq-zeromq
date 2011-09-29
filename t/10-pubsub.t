#!perl

use Test::More tests => 1;
use AnyEvent;
use AnyMQ;

BEGIN {
    use_ok( 'AnyMQ::ZeroMQ' ) || print "Bail out!\n";
}

my $pub_bus = AnyMQ->new_with_traits(
    traits            => [ 'ZeroMQ' ],
    publish_address   => 'tcp://localhost:4000',
);

my $sub_bus = AnyMQ->new_with_traits(
    traits            => [ 'ZeroMQ' ],
    subscribe_address => 'tcp://localhost:4001',
);

my $pub_topic = $pub_bus->topic('ping');
my $sub_topic = $sub_bus->topic('ping');

my $cv = AE::cv;

# subscribe
my $listener = $sub_bus->new_listener($sub_topic);
$listener->poll(sub { warn "got ping!"; $cv->send });

# publish
$pub_topic->publish({ bleep => 'bloop' });

$cv->recv;



