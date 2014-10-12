#!perl

use utf8;
use strict;
use warnings;

use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Preprocessor;
use Text::Amuse::Preprocessor::Footnotes;

use Test::More tests => 9;
use Data::Dumper;

my $good = catfile(qw/t footnotes good.muse/);
my $expected = catfile(qw/t footnotes expected.muse/);
my $out = catfile(qw/t footnotes out.muse/);
my $pp = Text::Amuse::Preprocessor::Footnotes->new(input => $good,
                                                   output => $out,
                                                   debug  => 1,
                                                  );

ok ($pp->process, "success") or diag Dumper($pp->error);
ok (!$pp->error);
compare_files($out, $expected);

my $too_many_refs = catfile(qw/t footnotes bad.muse/);

$pp = Text::Amuse::Preprocessor::Footnotes->new(output => $out,
                                                input => $too_many_refs,
                                                debug  => 1,
                                               );
ok (!$pp->process, "No success");
ok (! -f $out, "$out not written");
is_deeply ($pp->error, {
                        reference => 3,
                        footnotes => 2,
                        references_found => '[1] [2] [4]',
                        footnotes_found  => '[1] [1]',
                       }, "Error found");

my $too_many_fns = catfile(qw/t footnotes bad2.muse/);

$pp = Text::Amuse::Preprocessor::Footnotes->new(output => $out,
                                                input => $too_many_fns,
                                                debug  => 1,
                                               );
ok (!$pp->process, "No success");
ok (! -f $out, "$out not written");
is_deeply ($pp->error, {
                        reference => 3,
                        footnotes => 4,
                        references_found => '[1] [2] [4]',
                        footnotes_found  => '[1] [1] [4] [5]',
                       }, "Error found");


sub compare_files {
    my ($got, $exp) = @_;
    is_deeply([split /\n/, Text::Amuse::Preprocessor->_read_file($got)],
              [split /\n/, Text::Amuse::Preprocessor->_read_file($exp)],
              "$got is equal to $exp") ? unlink $got : die;
}

