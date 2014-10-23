#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Timer;

use AnyEvent;
use AnyEvent::Future;

# TODO - suggest this for Test::Timer
sub time_about
{
   my ( $code, $limit, $name ) = @_;
   time_between $code, $limit * 0.9, $limit * 1.1, $name;
}

{
   my $future = AnyEvent::Future->new;

   AnyEvent::postpone { $future->done( "result" ) };

   is_deeply( [ $future->get ], [ "result" ], '$future->get on AnyEvent::Future' );
}

# new_delay
{
   my $future = AnyEvent::Future->new_delay( after => 1 );

   time_about( sub { $future->await }, 1, '->new_delay future is ready' );

   is_deeply( [ $future->get ], [], '$future->get returns empty list on new_delay' );
}

# Check that ->cancel does not crash
{
   my $future = AnyEvent::Future->new_delay( after => 0.1 );
   $future->cancel;

   AnyEvent::Future->new_delay( after => 0.3 )->get;

   ok( $future->is_cancelled, '$future is cancelled after ->cancel' );
}

# new_timeout
{
   my $future = AnyEvent::Future->new_timeout( after => 1 );

   time_about( sub { $future->await }, 1, '->new_timeout is ready' );

   ok( $future->is_ready, '$future is ready from new_timeout' );
   is( $future->failure, "Timeout", '$future failed with "Timeout" for new_timeout' );
}

done_testing;
