#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package AnyEvent::Future;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw( Future );
Future->VERSION( '0.05' ); # to respect subclassing

use AnyEvent;

=head1 NAME

C<AnyEvent::Future> - use L<Future> with L<AnyEvent>

=head1 SYNOPSIS

 use AnyEvent;
 use AnyEvent::Future;

 my $future = AnyEvent::Future->new;

 some_async_function( ..., cb => sub { $future->done( @_ ) } );

 print Future->await_any(
    $future,
    AnyEvent::Future->new_timeout( after => 10 ),
 )->get;

=head1 DESCRIPTION

This subclass of L<Future> integrates with L<AnyEvent>, allowing the C<await>
method to block until the future is ready. It allows C<AnyEvent>-using code to
be written that returns C<Future> instances, so that it can make full use of
C<Future>'s abilities, including L<Future::Utils>, and also that modules using
it can provide a C<Future>-based asynchronous interface of their own.

For a full description on how to use Futures, see the L<Future> documentation.

=cut

=head1 CONSTRUCTORS

=cut

=head2 $f = AnyEvent::Future->new

Returns a new leaf future instance, which will allow waiting for its result to
be made available, using the C<await> method.

=cut

=head2 $f = AnyEvent::Future->new_delay( @args )

=head2 $f = AnyEvent::Future->new_timeout( @args )

Returns a new leaf future instance that will become ready at the time given by
the arguments, which will be passed to the C<< AnyEvent->timer >> method.

C<new_delay> returns a future that will complete successfully at the alotted
time, whereas C<new_timeout> returns a future that will fail with the message
C<Timeout>.

=cut

sub _new_timeout
{
   my $self = shift->new;
   my $method = shift;

   $self->{w} = AnyEvent->timer(
      @_,
      cb => sub { $self->$method( $method eq "fail" ? "Timeout" : () ) },
   );

   $self->on_cancel( sub {
      my $self = shift;
      undef $self->{w};
   });

   return $self;
}

sub new_delay   { shift->_new_timeout( done => @_ ) }
sub new_timeout { shift->_new_timeout( fail => @_ ) }

sub await
{
   my $self = shift;

   my $cv = AnyEvent->condvar;
   $self->on_ready( sub { $cv->send } );

   $cv->recv;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
