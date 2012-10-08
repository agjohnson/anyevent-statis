package AnyEvent::Statis::State;

use 5.010;
use strict;
use warnings;

use Mouse;
use JSON qw//;

use Statis::Model;

has 'id' => (
    is => 'rw',
    default => ''
);

has 'title' => (
    is => 'rw',
    default => '',
    trigger => sub {
        my ($self, $value) = @_;
        $self->id($self->slug)
          if (!$self->id);
    }
);

has 'type' => (
    is => 'rw',
    default => 'state'
);

has 'value' => (
    is => 'rw',
    default => 'pass'
);

has 'extra' => (
    is => 'rw',
    default => ''
);

has 'checks' => (
    is => 'rw',
    default => 0
);

# State return
sub passing { return (shift->value eq 'pass') }

sub failing { return (shift->value eq 'fail') }

sub warning { return (shift->value eq 'warn') }

# Statistics
sub count {
    my $self = shift;
    $self->checks($self->checks + 1);
}

sub from_json {
    my ($class, $json) = @_;
    my $data = JSON->new->allow_nonref->decode($json);
    AnyEvent::Statis::State->new($data);
}

sub TO_JSON {
    my $self = shift;
    my %trimmed = map { $_ => $self->{$_} } (qw/id title type value extra/);
    return \%trimmed;
}

sub to_json {
    my $self = shift;
    my $json = JSON->new->allow_nonref->allow_blessed->convert_blessed;
    $json->encode($self);
}

sub slug {
    my $self = shift;
    my $slug = $self->title;
    $slug =~ s/\W/-/g;
    $slug =~ s/[\-]+/-/g;
    return lc($slug);
}

1;
