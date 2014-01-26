#!/usr/bin/perl
use strict;
use warnings;
use Pod::Usage;

=head1 NAME

muse-rearrange-footnotes.pl

=head1 DESCRIPTION

This script takes a file as argument, and rearrange the footnotes
numbering, barfing if the footnotes found in the body don't match the
footnotes themselves. This is handy if you inserted footnotes at
random position, or if the footnotes are numbered by section or
chapter.

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
  
The original file is never overwritten.

=head1 SYNOPSIS

  muse-rearrange-footnotes.pl file.muse

=head1 SEE ALSO

L<Text::Amuse::Preprocessor>

=cut

my $filename = shift;

die pod2usage("Please pass a file.muse as argument\n") unless $filename;

die pod2usage("$filename doesn't exist\n")      unless -e $filename;
die pod2usage("$filename is not a text file\n") unless -T $filename;

my $outputfile = $filename . ".fixed" ; 
print "Processing $filename, I'll output on $outputfile\n Please double check the result\n";

open(my $in, "<", $filename) or die "Cannot open $filename, $!\n";

# read the file.
my $fn_counter = 0; 
my $body_fn_counter = 0;
my $last_was_fn = 0;
my @fnotes;
my @orig_body;

while (my $r = <$in>) {
	if ($r =~ m/^\s*\[\d+\]\s*/) {
		$r =~ s/^\s*\[\d+\]/"[" . ++$fn_counter . "]"/e;
		# the footnotes at the end go in a separate array
		push @fnotes, $r;
        $last_was_fn = 1;
        next;
	}

    # check if we have a broken footnote and skip the first empty line
    # after that.
    if ($last_was_fn) {
        if ($r =~ m/^\s*$/) {
            $last_was_fn = 0;
            next;
        }
        else {
            die "Broken footnote detected: " . $fnotes[$#fnotes];
        }
    }

    # then process the page
    $r =~ s/\[\d{1,4}\]/"[" . ++$body_fn_counter . "]"/ge;
    push @orig_body, $r; 
}

close $in;

if ($body_fn_counter != $fn_counter) {
    warn "Counter mismatch: body has $body_fn_counter reference, " 
      . "but $fn_counter footnotes found\n";
    $outputfile .= ".broken.muse";
    warn "Output on $outputfile\n";
}


# write the body file
open(my $out, ">", $outputfile) or die "I cannot open $outputfile, $!";

while (@orig_body) {
	print $out shift(@orig_body);
}
while (@fnotes) {
	print $out shift(@fnotes), "\n";
}
close $out;

