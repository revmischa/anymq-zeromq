package AnyMQ::Trait::ZeroMQ;

use Any::Moose 'Role';

use AnyEvent::ZeroMQ;
use AnyEvent::ZeroMQ::Publish;
use AnyEvent::ZeroMQ::Subscribe;
use AnyMQ::Topic::Trait::ZeroMQ;
use Carp qw/croak/;
use JSON;

has 'publish_address'   => ( is => 'rw', isa => 'Str' );
has 'subscribe_address' => ( is => 'rw', isa => 'Str' );

has '_zmq_sub' => ( is => 'rw', lazy_build => 1, isa => 'AnyEvent::ZeroMQ::Subscribe' );
has '_zmq_pub' => ( is => 'rw', lazy_build => 1, isa => 'AnyEvent::ZeroMQ::Publish' );
has '_zmq_context' => ( is => 'rw', lazy_build => 1, isa => 'ZeroMQ::Raw::Context' );
has '_zmq_json' => ( is => 'rw', lazy_build => 1, isa => 'JSON' );

has 'on_read_callbacks' => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => 'ArrayRef[CodeRef]',
    default    => sub { [] },
    handles    => {
        all_read_callbacks => 'elements',
        add_read_callback => 'push',
    },
);        

sub _build__zmq_json {
    my ($self) = @_;
    return JSON->new->utf8;
}

sub _build__zmq_context {
    my ($self) = @_;

    my $c = ZeroMQ::Raw::Context->new( threads => 10 );
    return $c;
}

sub _build__zmq_sub {
    my ($self) = @_;

    my $address = $self->subscribe_address
        or croak 'subscribe_address must be defined to publish messages';

    my $sub = AnyEvent::ZeroMQ::Subscribe->new(
        context => $self->_zmq_context,
        connect => $address,
    );

    $sub->on_read(sub { $self->read_event(@_) });

    return $sub;
}

sub _build__zmq_pub {
    my ($self) = @_;

    my $address = $self->publish_address
        or croak 'publish_address must be defined to publish messages';

    my $pub = AnyEvent::ZeroMQ::Publish->new(
        context => $self->_zmq_context,
        connect => $address,
    );

    return $pub;
}

# called when we read some data
sub read_event {
    my ($self, $subscription, $json) = @_;

    my $event = $self->_zmq_json->decode($json);

    unless ($event) {
        warn "Got invalid JSON: $json";
        return;
    }

    # call read callbacks
    foreach my $on_read_callback ($self->all_read_callbacks) {
        $on_read_callback->($event);
    }
}

sub subscribe {
    my ($self, $cb) = @_;

    # make sure our subscription exists
    $self->_zmq_sub;

    # install callback
    $self->add_read_callback($cb);
}

sub unsubscribe {
    my ($self, $cb) = @_;

    my $cbs = $self->on_read_callbacks;
    $cbs = [ grep { $_ != $cb } @$cbs ];
}

sub new_topic {
    my ($self, $opt) = @_;
    
    $opt = { name => $opt } unless ref $opt;

    return AnyMQ::Topic->new_with_traits(
        traits => [ 'ZeroMQ' ],
        %$opt,
        bus => $self,
    );
}

sub DEMOLISH {}; after 'DEMOLISH' => sub {
    my $self = shift;
    my ($igd) = @_;

    return if $igd;

    # cleanup
};

1;
