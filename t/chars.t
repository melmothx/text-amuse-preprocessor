#!perl

use strict;
use warnings;

use Text::Amuse::Preprocessor::TypographyFilters;

use Test::More tests => 7 * 5;

my $chars = Text::Amuse::Preprocessor::TypographyFilters::characters();

foreach my $lang (keys %$chars) {
    foreach my $token (qw/ldouble rdouble lsingle rsingle apos emdash endash/) {
        ok($chars->{$lang}->{$token}, "Found $token for $lang");
    }
}

