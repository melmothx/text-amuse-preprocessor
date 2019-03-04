#!perl

#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 2;
use Text::Amuse::Preprocessor;

for (1,2) {
    my $input = <<'MUSE';
#title The Text::Amuse markup manual
#lang en

If you need to start a line with an hash, wrap it in =<verbatim>= E.g.

{{{
#hashtag verbatim.
=#hashtag= verbatim as code.
}}}

Yielding:

<verbatim>#hashtag</verbatim> verbatim.

MUSE
    my $output = '';
    my $pp = Text::Amuse::Preprocessor->new(input => \$input,
                                            output => \$output,
                                            fix_links => 0,
                                            fix_typography => 0,
                                            fix_nbsp => 0,)->process;
    ok $output;
    diag $output;
}


my $inp
