package AnyMQ::Topic::Trait::ZeroMQ;

use Any::Moose 'Role';
use AnyEvent::ZeroMQ::Subscribe;

has 'publisher_only' => (is => "ro", isa => "Bool");
has 'debug' => (is => "rw", isa => "Bool", default => 0);

# we do not want to notify subscribers of events being published on
# our publisher bus, otherwise we will get duplicates if we are
# subscribed to those events.
has 'publish_to_queues' => (is => 'rw', default => 0);

has 'read_callback' => (is => 'rw', isa => 'CodeRef');

sub BUILD {}; after 'BUILD' => sub {
    my $self = shift;

    return if $self->publisher_only;
    return unless $self->name;
    return unless $self->bus->subscribe_address;

    # subscribe to events
    my $read_cb = sub {
        my ($event) = @_;
        # is this an event we are listening for?
        if (! $event->{type} || $event->{type} ne $self->name) {
            warn "discarding $event->{type} event" if $self->debug;
            return;
        }
        
        $self->append_to_queues($event);
    };
    $self->read_callback($read_cb);
    
    $self->bus->subscribe($read_cb);
};

sub DEMOLISH {}; after 'DEMOLISH' => sub {
    my ($self, $igd) = @_;

    # program shutting down, whatever
    return if $igd;

    # uninstall our callback
    $self->bus->unsubscribe($self->read_callback)
        if $self->read_callback;
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
