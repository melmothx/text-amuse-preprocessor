#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Text::Amuse::Preprocessor::Footnotes;
use Data::Dumper;
use Getopt::Long;

my $verbose;

GetOptions("v|verbose" => \$verbose) or die;

foreach my $file (@ARGV) {
    my $pp = Text::Amuse::Preprocessor::Footnotes->new(input => $file);
    $pp->process;
    if (my $error = $pp->error) {
        if ($verbose) {
            print "$file: " . Dumper($error);
        }
        else {
            print "$file: found: $error->{footnotes} references: $error->{references}\n";
        }
    }
}
