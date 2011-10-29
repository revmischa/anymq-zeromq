#!perl

use Test::More tests => 2;
use AnyEvent;
use AnyMQ;

BEGIN {
    use_ok( 'AnyMQ::ZeroMQ' ) || print "Bail out!\n";
}

SKIP: {
    skip "Set \$ENV{ZMQ_PUBSUB_TESTS} to test with ZeroMQ::PubSub", 1
        unless $ENV{ZMQ_PUBSUB_TESTS};

    run_tests();
}

sub run_tests {
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
    $listener->poll(sub { $cv->send });

    # publish
    $pub_topic->publish({ __type => 'ping', __params => { bleep => 'bloop' } });

    $cv->recv;
    ok("Got ping");
}



