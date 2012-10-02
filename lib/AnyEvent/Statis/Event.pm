package AnyEvent::Statis::Event;

use 5.010;
use strict;
use warnings;

use Mouse;
use JSON qw//;

use AnyEvent::Statis::Event;

has 'event' => (
    is => 'rw',
    default => ''
);

has 'state' => (
    is => 'rw',
    isa => 'AnyEvent::Statis::State'
);

sub from_json {
    my ($class, $json) = @_;
    my $data = JSON->new->allow_nonref->decode($json);
    AnyEvent::Statis::Event->new(
        event => $data->{event},
        state => AnyEvent::Statis::State->new(
            $data->{state}
        )
    );
}

sub to_json {
    my $self = shift;
    my $json = JSON->new->allow_nonref->allow_blessed->convert_blessed;
    $json->encode($self);
}

sub TO_JSON {
    my $self = shift;
    return {
        event => $self->event,
        state => $self->state
    };
}

1;
