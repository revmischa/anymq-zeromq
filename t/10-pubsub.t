#!perl

use Test::More tests => 3;
use AnyEvent;
use AnyMQ;

BEGIN {
    use_ok( 'AnyMQ::ZeroMQ' ) || print "Bail out!\n";
}

SKIP: {
    skip "Set \$ENV{ZMQ_PUBSUB_TESTS} to test with ZeroMQ::PubSub", 2
        unless $ENV{ZMQ_PUBSUB_TESTS};

    run_tests();
}

sub run_tests {
    test_separate_clients();
    test_single_client();
}

sub test_separate_clients {
    my $pub_bus = AnyMQ->new_with_traits(
        traits            => [ 'ZeroMQ' ],
        publish_address   => 'tcp://localhost:4000',
    );

    my $sub_bus = AnyMQ->new_with_traits(
        traits            => [ 'ZeroMQ' ],
        subscribe_address => 'tcp://localhost:4001',
    );

    test_mq($pub_bus, $sub_bus);
}

sub test_single_client {
    my $bus = AnyMQ->new_with_traits(
        traits            => [ 'ZeroMQ' ],
        publish_address   => 'tcp://localhost:4000',
        subscribe_address => 'tcp://localhost:4001',
    );

    test_mq($bus, $bus);
}

sub test_mq {
    my ($pub_bus, $sub_bus) = @_;
    
    my $pub_topic = $pub_bus->topic('ping');
    my $sub_topic = $sub_bus->topic('ping');

    my $ping_count = 0;
    my $cv = AE::cv;
    $cv->begin;
    $cv->begin;

    # subscribe
    my $listener = $sub_bus->new_listener($sub_topic);
    $listener->poll(sub { $ping_count++; $cv->end });

    # publish
    $pub_topic->publish({ type => 'pong' });
    $pub_topic->publish({ type => 'ping', params => { bleep => 'bloop' } });
    $pub_topic->publish({ type => 'ping', params => { bleep => 'bloop' } });

    $cv->recv;

    $cv = AE::cv;
    my $t = AnyEvent->timer(
        after => 1.5,
        cb => sub {
            $cv->send;
        },
    );
    $cv->recv;
    
    is($ping_count, 2, "Got pings");
}



