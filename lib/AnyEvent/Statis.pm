package AnyEvent::Statis;

use 5.010;
use strict;
use warnings;

=head1 NAME

AnyEvent::Statis - AnyEvent model for Statis applications

=cut

our $VERSION = 0.01;

use AnyEvent;
use AnyEvent::Redis;
use JSON qw//;
use List::MoreUtils qw/all any/;

use AnyEvent::Statis::State;
use AnyEvent::Statis::Event;

sub new {
    my $class = shift;

    bless {
        db => {},
        channel => 'events',
        @_
    }, $class;
}

# Listen
sub listen {
    my $self = shift;

    $self->db('sub')->subscribe(
        $self->{channel},
        sub { $self->process(@_) }
    );
}

# Send
sub send {
    my $self = shift;
    my $state = AnyEvent::Statis::State->new(@_);

    $self->find(
        $state->id,
        sub {
            my $found = shift->recv;
            my $cv = AnyEvent->condvar;

            # Unconditional state event
            $cv->begin;
            my $e = AnyEvent::Statis::Event->new(
                event => 'on_receive',
                state => $state
            )->to_json;
            $self->db('pub')->publish(
                $self->{channel},
                $e,
                sub {
                    $cv->end;
                }
            );

            # Trigger on_create on state object not found
            if (!$found) {
                $cv->begin;
                $self->db('pub')->publish(
                    $self->{channel},
                    AnyEvent::Statis::Event->new(
                        event => 'on_create',
                        state => $state
                    )->to_json,
                    sub {
                        $cv->end;
                    }
                );
            }
            else {
                if ($self->changed($found, $state)) {
                    # Trigger on_update event on update of fields
                    $self->db('pub')->publish(
                        $self->{channel},
                        AnyEvent::Statis::Event->new(
                            event => 'on_update',
                            state => $state
                        )->to_json,
                        sub {
                            $cv->end;
                        }
                    );
                    # TODO trigger per field?
                }
            }

            # Save it
            $cv->begin;
            $self->save($state, sub{
                $cv->end;
            });
        }
    );
}

# Database functions
sub db {
    my $self = shift;
    my $method = shift // 'get';
    if (!$self->{db}->{$method}) {
        $self->{db}->{$method} = AnyEvent::Redis->new(
            host => $self->{host},
            port => $self->{port}
        );
    }
    return $self->{db}->{$method};
}

sub find {
    my $self = shift;
    my $id = shift;
    my $callback = shift // sub {};

    # TODO check id here
    my $cv = AnyEvent->condvar;
    $self->db->get(
        $id,
        sub {
            my ($val, $err) = @_;
            my $state;
            $state = AnyEvent::Statis::State->from_json($val)
              if ($val);
            $cv->send($state);
        }
    );
    $cv->cb($callback);
    return $cv;
}

sub save {
    my $self = shift;
    my $state = shift;
    my $callback = shift // sub {};

    # TODO check id here
    if (!$state->id) {
        $state->id($state->slug);
    }

    my $cv = AnyEvent->condvar;
    $self->db->set(
        $state->id,
        $state->to_json,
        sub {
            my ($val, $err) = @_;
            $cv->send($state);
        }
    );
    $cv->cb($callback);
    return $cv;
}

# Process lines for events
sub process {
    my ($self, $raw, $channel) = @_;

    my $event = AnyEvent::Statis::Event->from_json($raw);
    return unless ($event->state->id);

    if ($self->{$event->event}) {
        $self->{$event->event}->($event->state);
    }
}

sub changed {
    my ($self, $curr, $state) = @_;
    my @fields = qw/id type value title/;

    return (any { ($state->{$_} ne $curr->{$_}) } @fields);
}

1;
__END__

=head1 AUTHOR

Anthony Johnson, C<< <aj at ohess.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Anthony Johnson.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
