package AnyMQ::Topic::Trait::ZeroMQ;

use Any::Moose 'Role';
use AnyEvent::ZeroMQ::Subscribe;

has 'publisher_only' => (is => "ro", isa => "Bool");

# we do not want to notify subscribers of events being published on
# our publisher bus, otherwise we will get duplicates if we are
# subscribed to those events.
has '+publish_to_queues' => (default => sub { 0 });

sub BUILD {}; after 'BUILD' => sub {
    my $self = shift;

    return if $self->publisher_only;
    return unless $self->name;
    return unless $self->bus->subscribe_address;

    # subscribe to events
    $self->bus->_zmq_sub->on_read(sub {
        my ($subscription, $json) = @_;

        my $event = $self->bus->_zmq_json->decode($json);

        unless ($event) {
            warn "Got invalid JSON: $json";
            return;
        }

        $self->append_to_queues($event);
    });
};

# send events to ZeroMQ server
after 'dispatch_messages' => sub {
    my ($self, @events) = @_;
    
    # if this bus is just listening for events, we don't need to
    # publish the event to the zeromq server, just call callbacks
    return unless $self->bus->publish_address;

    my $pub = $self->bus->_zmq_pub;

    # encode events as JSON and transmit them
    foreach my $event (@events) {
        my $json = $event;
        if (ref $json) {
            $json = $self->bus->_zmq_json->encode($event);
        }

        $self->bus->_zmq_pub->publish($json);
    }
};

1;
