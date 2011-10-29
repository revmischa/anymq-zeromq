package AnyMQ::Topic::Trait::ZeroMQ;

use Any::Moose 'Role';
use AnyEvent::ZeroMQ::Subscribe;

has publisher_only => (is => "ro", isa => "Bool");

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

        $self->receive_events($event);
    });
};

# when publishing events, send them to the ZeroMQ server
before publish => sub {
    my ($self, @events) = @_;

    $self->send_events(@events);
};

# this is the same as calling $self->publish, but does not trigger
# publishing an event to the ZeroMQ server.
sub receive_events {
    my ($self, @events) = @_;

    $self->reap_destroyed_listeners;
    for (values %{$self->queues}) {
        $_->append(@events);
    }
    $self->install_reaper if $self->reaper_interval;
}

# send events to ZeroMQ server
sub send_events {
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
}

1;
