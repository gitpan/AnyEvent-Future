#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package AnyEvent::Future;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw( Future );
Future->VERSION( '0.05' ); # to respect subclassing

use Exporter 'import';
our @EXPORT_OK = qw(
   as_future
   as_future_cb
);

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

Or

 use AnyEvent::Future qw( as_future_cb );

 print Future->await_any(
    as_future_cb {
       some_async_function( ..., cb => shift )
    },
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

# Forward
sub as_future(&);

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

sub new_delay
{
   shift;
   my %args = @_;

   as_future {
      my $f = shift;
      AnyEvent->timer( %args, cb => sub { $f->done } );
   };
}

sub new_timeout
{
   shift;
   my %args = @_;

   as_future {
      my $f = shift;
      AnyEvent->timer( %args, cb => sub { $f->fail( "Timeout" ) } );
   };
}

sub await
{
   my $self = shift;

   my $cv = AnyEvent->condvar;
   $self->on_ready( sub { $cv->send } );

   $cv->recv;
}

=head1 UTILTIY FUNCTIONS

The following utility functions are exported as a convenience.

=cut

=head2 $f = as_future { CODE }

Returns a new leaf future instance, which is also passed in to the block of
code. The code is called in scalar context, and its return value is stored on
the future. This will be deleted if the future is cancelled.

 $w = CODE->( $f )

This utility is provided for the common case of wanting to wrap an C<AnyEvent>
function which will want to receive a callback function to inform of
completion, and which will return a watcher object reference that needs to be
stored somewhere.

=cut

sub as_future(&)
{
   my ( $code ) = @_;

   my $f = AnyEvent::Future->new;

   $f->{w} = $code->( $f );
   $f->on_cancel( sub { undef shift->{w} } );

   return $f;
}

=head2 $f = as_future_cb { CODE }

A futher shortcut to C<as_future>, where the code is passed two callback
functions for C<done> and C<fail> directly, avoiding boilerplate in the common
case for creating these closures capturing the future variable. In many cases
this can reduce the code block to a single line.

 $w = CODE->( $done_cb, $fail_cb )

=cut

sub as_future_cb(&)
{
   my ( $code ) = @_;

   &as_future( sub {
      my $f = shift;
      $code->( $f->done_cb, $f->fail_cb );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
