#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 4;
use Text::Amuse::Preprocessor;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;

my $input = <<'INPUT';
U+FB00	ﬀ	ef ac 80	LATIN SMALL LIGATURE FF       ﬀ
U+FB01	ﬁ	ef ac 81	LATIN SMALL LIGATURE FI       ﬁ
U+FB02	ﬂ	ef ac 82	LATIN SMALL LIGATURE FL       ﬂ
U+FB03	ﬃ	ef ac 83	LATIN SMALL LIGATURE FFI      ﬃ
U+FB04	ﬄ	ef ac 84	LATIN SMALL LIGATURE FFL      ﬄ
INPUT

my $expected = <<'OUT';
U+FB00    ff    ef ac 80    LATIN SMALL LIGATURE FF       ff
U+FB01    fi    ef ac 81    LATIN SMALL LIGATURE FI       fi
U+FB02    fl    ef ac 82    LATIN SMALL LIGATURE FL       fl
U+FB03    ffi    ef ac 83    LATIN SMALL LIGATURE FFI      ffi
U+FB04    ffl    ef ac 84    LATIN SMALL LIGATURE FFL      ffl
OUT

test_strings(ligatures => $input, $expected);

test_strings(missing_nl => "hello\nthere", "hello\nthere\n");

sub test_strings {
    my ($name, $input, $expected, $typo, $links, $fn) = @_;

    my $input_string = $input;
    my $output_string = '';

    my $pp = Text::Amuse::Preprocessor->new(input => \$input_string,
                                            output => \$output_string,
                                            fix_links => $links,
                                            fix_typography => $typo,
                                            fix_footnotes => $fn,
                                           );
    $pp->process;
    is_deeply([ split /\n/, $output_string ],
              [ split /\n/, $expected ],
              "$name with reference works");
    
    # and the file variant
    my $dir = File::Temp->newdir(CLEANUP => 0);
    my $wd = $dir->dirname;
    my $infile = catfile($wd, 'in.muse');
    my $outfile = catfile($wd, 'out.muse');
    diag "Using $wd for $name";
    write_file($infile, $input);

    my $pp_file = Text::Amuse::Preprocessor->new(input => $infile,
                                                 output => $outfile,
                                                 fix_links => $links,
                                                 fix_typography => $typo,
                                                 fix_footnotes => $fn,
                                                );
    $pp_file->process;
    is_deeply([ split /\n/, read_file($outfile) ],
              [ split /\n/, $expected ],
              "$name with reference works");
}

sub read_file {
    return Text::Amuse::Preprocessor->_read_file(@_);
}

sub write_file {
    return Text::Amuse::Preprocessor->_write_file(@_);
}
