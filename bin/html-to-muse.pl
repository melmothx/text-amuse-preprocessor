#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Usage;
use Text::Amuse::Preprocessor::HTML qw/html_file_to_muse html_to_muse/;
use LWP::UserAgent;
use Getopt::Long;
use Encode qw/decode_utf8/;
use utf8;
binmode STDOUT, ":encoding(utf-8)";
binmode STDERR, ":encoding(utf-8)";

=head1 NAME

html-to-muse.pl

=head1 SYNOPSIS

  html-to-muse.pl [ options... ] file.html

or

  html-to-muse.pl http://example.com/my-file.html

=head2 Options

=over 4

=item --encoding <encoding-name>

Default to utf-8. The switch is used only on local files.

=item --lang

Set the language of the document in the muse output

=item --title

Set the title of the document (otherwise the filename is used).

=back

The result is printed on the standard output, thus you can use it this way:

 html-to-muse.pl my-file.html > myfile.muse

 html-to-muse.pl http://example.com/my-file.html > my-remote-file.muse

=head1 SEE ALSO

L<Text::Amuse::Preprocessor>

=cut


my $encoding = 'utf-8';
my $help;
my $lang = 'en';
my $title = '';

GetOptions ("encoding=s" => \$encoding,
            "lang=s" => \$lang,
            "title=s" => \$title,
            help => \$help) or die;

if ($help || !@ARGV) {
    pod2usage("\n");
    exit;
}

foreach my $f (@ARGV) {
    if ($title) {
        $title = decode_utf8($title);
    }
    else {
        $title = $f;
    }
    print "#title $title\n";
    print "#lang $lang\n\n";
    process_target($f);
}

sub process_target {
    my $f = shift;
    if (-f $f) {
        print html_file_to_muse($f, $encoding);
    }
    else {
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get($f);
        if ($res->is_success) {
            my $body = $res->decoded_content;
            print html_to_muse($body);
        }
        else {
            warn $res->status_line . "\n";

        }
    }
    print "\n\n";
}
