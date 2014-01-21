#!/usr/bin/perl
use strict;
use warnings;

my $filename = shift;

die "Please pass a file.muse as argument\n" unless $filename;

die "$filename doesn't exist\n"      unless -e $filename;
die "$filename is not a text file\n" unless -T $filename;

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

