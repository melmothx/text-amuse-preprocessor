#!perl

use utf8;
use strict;
use warnings;

use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Preprocessor;
use Text::Amuse::Preprocessor::Footnotes;

use Test::More tests => 2;
use Data::Dumper;

my $good = catfile(qw/t footnotes good.muse/);
my $expected = catfile(qw/t footnotes expected.muse/);
my $out = catfile(qw/t footnotes out.muse/);
my $pp = Text::Amuse::Preprocessor::Footnotes->new(input => $good,
                                                   output => $out,
                                                   debug  => 1,
                                                  );

ok ($pp->process, "success") or diag Dumper($pp->error);
compare_files($out, $expected);

sub compare_files {
    my ($got, $exp) = @_;
    is_deeply([split /\n/, Text::Amuse::Preprocessor->_read_file($got)],
              [split /\n/, Text::Amuse::Preprocessor->_read_file($exp)],
              "$got is equal to $exp") ? unlink $got : die;
}

