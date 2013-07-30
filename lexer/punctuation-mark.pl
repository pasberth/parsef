#!/usr/bin/env perl -p
s/(?<!^)($r)/\n$1/g ;
s/($r)(?!\n|$)/$1\n/g ;

BEGIN {
  my @as = () ;
  foreach my $a ( @ARGV ) {
    push @as, quotemeta $a
  }

  @ARGV = () ;
  $r = join '|', @as ;
}