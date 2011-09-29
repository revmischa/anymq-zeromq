package AnyMQ::Topic::Trait::ZeroMQ;

use Any::Moose 'Role';
use JSON;

sub BUILD {}; after 'BUILD' => sub {
    my ($self) = @_;

};

before publish => sub {
    my ($self, @events) = @_;

    my $pub = $self->bus->_zmq_pub;

    foreach my $event (@events) {
        $self->bus->_zmq_pub->publish(JSON::to_json($event));
    }
};

1;
