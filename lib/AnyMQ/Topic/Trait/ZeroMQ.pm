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
	my ($subscription, $event) = @_;

        my $json = $self->bus->_zmq_json->decode($event);
	$self->publish($event);
    });
};

before publish => sub {
    my ($self, @events) = @_;

    # if this bus is just listening for events, we don't need to
    # publish the event to the zeromq server, just call callbacks
    return unless $self->bus->publish_address;

    my $pub = $self->bus->_zmq_pub;

    # encode events as JSON and transmit them
    foreach my $event (@events) {
        my $json = $self->bus->_zmq_json->encode($event);
        $self->bus->_zmq_pub->publish($json);
    }
};

1;
