#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use Text::Amuse::Preprocessor;
use Getopt::Long;
use Data::Dumper;

my ($fix_links, $fix_typography, $fix_nbsp, $remove_nbsp, $fix_footnotes, $help);

GetOptions (
            links => \$fix_links,
            typography => \$fix_typography,
            nbsp => \$fix_nbsp,
            'remove-nbsp' => \$remove_nbsp,
            footnotes => \$fix_footnotes,
            help => \$help,
           ) or die;

if ($help or @ARGV != 2) {
    pod2usage("Using Text::Amuse::Preprocessor version " .
              $Text::Amuse::Preprocessor::VERSION . "\n");
    exit;
}

=head1 NAME

muse-preprocessor.pl -- fix your muse document

=head1 SYNOPSIS

 muse-preprocessor.pl [ options ] inputfile.muse outputfile.muse

The input file is processed according to the options and the output is
left in the output file. Both arguments are mandatory.

Options:

=over 4

=item links

Makes all the links active

=item typography

Apply typographical fixes according to the language of the document

=item nbsp

Add non-breaking spaces according to the language of the document (if
applicable).

=item remove-nbsp

Unconditionally remove all the invisible non-breaking spaces

=item footnotes

Rearrange the footnotes.

=item help

Show this help and exit

=back

=cut

my ($infile, $outfile) = @ARGV;

die "$infile is not a file" unless -f $infile;

my $pp = Text::Amuse::Preprocessor->new(
                                        fix_links      => $fix_links,
                                        fix_nbsp       => $fix_nbsp,
                                        remove_nbsp    => $remove_nbsp,
                                        fix_footnotes  => $fix_footnotes,
                                        fix_typography => $fix_typography,
                                        input => $infile,
                                        output => $outfile,
                                       );
if ($pp->process) {

}
else {
    die Dumper($pp->error);
}
