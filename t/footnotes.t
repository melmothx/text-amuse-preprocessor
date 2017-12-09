#!perl

use utf8;
use strict;
use warnings;

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}



use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Preprocessor;
use Text::Amuse::Preprocessor::Footnotes;

use Test::More tests => 20;
use Data::Dumper;

my @tests = ([ good => undef ],
             [ 'good2' => undef ],
             [ 'good3' => undef ],
             [ bad => {
                       references => 3,
                       footnotes => 2,
                       references_found => '[1] [2] [4]',
                       footnotes_found  => '[1] [1]',
                      } ],
             [ bad2 => {
                        references => 3,
                        footnotes => 4,
                        references_found => '[1] [2] [4]',
                        footnotes_found  => '[1] [1] [4] [5]',
                       } ],
            );

my $out = catfile(qw/t footnotes out.muse/);
foreach my $test (@tests) {
    my $input    = catfile(qw/t footnotes/, $test->[0] . '.in');
    my $expected = catfile(qw/t footnotes/, $test->[0] . '.out');
    unlink $out if -f $out;
    diag "Testing $input => $expected";
    ok(! -f $out, "$out doesn't exist");
    my $pp = Text::Amuse::Preprocessor->new(input => $input,
                                         output => $out,
                                         fix_footnotes  => 1,
                                         debug  => 0,
                                        );
    my $ok = $pp->process;
    if ($test->[1]) {
        ok (!$ok, "No success");
        ok (! -f $out, "$out not written");
        is_deeply ($pp->error, $test->[1], 'Error is correct');
    }
    else {
        ok ($ok, "success") or diag Dumper($pp->error);
        ok (!$pp->error);
        eq_or_diff([split /\n/, Text::Amuse::Preprocessor->_read_file($out)],
                   [split /\n/, Text::Amuse::Preprocessor->_read_file($expected)],
                   "$out is equal to $expected");
    }
}
unlink $out if -f $out;

