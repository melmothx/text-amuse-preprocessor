#!/usr/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Text::Amuse::Preprocessor::Footnotes;
use Getopt::Long;
use File::Copy qw/move/;

=head1 NAME

muse-rearrange-footnotes.pl

=head1 DESCRIPTION

This script takes an arbitrary number of files as argument, and
rearrange the footnotes numbering, barfing if the footnotes found in
the body don't match the footnotes themselves. This is handy if you
inserted footnotes at random position, or if the footnotes are
numbered by section or chapter.

The only thing that matters is the B<order>.

Example input file content:

  This [1] is a text [1] with three footnotes [4]

  [1] first
  
  [1] second
  
  [2] third


Output in file with C<.fixed> extension:

  This [1] is a text [2] with three footnotes [3]

  [1] first
  
  [2] second
  
  [3] third
  
The original file is overwritten if the option --overwrite is provided.

=head1 SYNOPSIS

  muse-rearrange-footnotes.pl file.muse

=head1 SEE ALSO

L<Text::Amuse::Preprocessor::Footnotes>

=cut

my $overwrite;

GetOptions(overwrite => \$overwrite) or die;

die pod2usage("Please one or more muse file as arguments\n") unless @ARGV;

foreach my $file (@ARGV) {
    my $output = $file . ".fixed";
    my $pp = Text::Amuse::Preprocessor::Footnotes->new(input => $file,
                                                       output => $output);
    $pp->process;
    if (my $error = $pp->error) {
        print "Error $file: found footnotes: $error->{footnotes} "
          . "($error->{footnotes_found})\n"
            . "found references: $error->{references} "
              . "($error->{references_found})\n\n";
        next;
    }
    elsif (! -f $output) {
        die "$output not produced, this shouldn't happen!\n";
    }
    if ($overwrite) {
        move $output, $file or die "Cannot move $output into $file: $!";
    }
    else {
        print "Output left in $output\n";
    }
}


