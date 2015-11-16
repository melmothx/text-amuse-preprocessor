#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Pod::Simple::Wiki;

my $parser = Pod::Simple::Wiki->new('muse');


my ($in, $out, $title);
if ( defined $ARGV[0] ) {
    # open in raw mode
    open ($in, '<', $ARGV[0]) or die "Couldn't open $ARGV[0]: $!\n";
    $title = fileparse($ARGV[0], qr{\.(pl|pm|pod)}i);
}
else {
    $in = *STDIN;
    $title = '<STDIN>';
}

# but encode the output layer
if ( defined $ARGV[1] ) {
    open ($out, ">:encoding(UTF-8)", $ARGV[1]) or die "Couldn't open $ARGV[1]: $!\n";
}
else {
    binmode STDOUT, "encoding(UTF-8)";
    $out = *STDOUT;
}
print $out "#title $title\n\n";

$parser->output_fh($out);
$parser->parse_file($in);


