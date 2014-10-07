package Text::Amuse::Preprocessor;

use 5.010001;
use strict;
use warnings;

use Text::Amuse::Preprocessor::HTML;
use Text::Amuse::Preprocessor::Typography qw/get_typography_filter/;
use Text::Amuse::Functions;
use File::Spec;
use File::Temp qw();
use File::Copy qw();
use Data::Dumper;

=head1 NAME

Text::Amuse::Preprocessor - Helpers for Text::Amuse document formatting.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

  use Text::Amuse::Preprocessor;
  my $pp = Text::Amuse::Preprocessor->new(
                                          input => $infile,
                                          output => $outfile,
                                          html => 1,
                                          fix_links => 1,
                                          fix_typography => 1,
                                          fix_footnotes => 1
                                         );
  $pp->process;

=head1 ACCESSORS

The following values are read-only and must be passed to the constructor.

=head2 Mandatory

=head3 input

Can be a string (with the input file path) or a reference to a scalar
with the text to process).

=head3 output

Can be a string (with the output file path) or a reference to a scalar
with the processed text.

=head2 Optional

=head3 html

Before doing anything, convert the HTML input into a muse file. Even
if possible, you're discouraged to do the html import and the fixing
in the same processing. Instead, create two objects, then first do the
HTML to muse convert, save the result somewhere, add the headers, then
reprocess it with the required fixes above.

Notably, the output will be without an header, so the language will
not be detected.

Default to false.

=head3 fix_links

Find the links and add the markup if needed. Default to false.

=head3 fix_typography

Apply the typographical fixes. Default to false.

=head3 fix_footnotes

Rearrange the footnotes if needed. Default to false.

=head3 debug

Don't unlink the temporary files and be verbose

=head1 METHODS

=head2 new(%options)

Constructor. Accepts the above options.

=cut

sub new {
    my ($class, %options) = @_;
    my $self = {
                html => 0,
                fix_links => 0,
                fix_typography  => 0,
                fix_footnotes => 0,
                debug => 0,
                input => undef,
                output => undef,
               };
    foreach my $k (keys %$self) {
        if (exists $options{$k}) {
            $self->{$k} = delete $options{$k};
        }
    }
    $self->{_error} = '';
    die "Unrecognized options: " . join(" ", keys %options) if %options;
    bless $self, $class;
}

sub html {
    return shift->{html};
}

sub fix_links {
    return shift->{fix_links};
}

sub fix_typography {
    return shift->{fix_typography};
}

sub fix_footnotes {
    return shift->{fix_footnotes};
}

sub debug {
    return shift->{debug};
}

sub input {
    return shift->{input};
}

sub output {
    return shift->{output};
}

=head2 process

Process C<input> according to the options passed and write into
C<output>. Return C<output> on success, false otherwise.

=cut

sub _infile {
    my ($self, $arg) = @_;
    if ($arg) {
        die "Infile already set" if $self->{_infile};
        $self->{_infile} = $arg;
    }
    return $self->{_infile};
}

# temporary file for output
sub _outfile {
    my $self = shift;
    return File::Spec->catfile($self->tmpdir, 'output.muse');
}

sub process {
    my $self = shift;
    my $debug = $self->debug;

    my $wd = $self->tmpdir;
    print "# Using $wd to store temporary files\n" if $debug;
    $self->_set_infile;
    my $infile = $self->_infile;
    die "Something went wrong" unless -f $infile;

    if ($self->html) {
        $self->_process_html;
    }

    # then try to get the language
    my $lang;
    if ($self->fix_typography) {
        eval {
            my $info = Text::Amuse::Functions::muse_fast_scan_header($infile);
            print Dumper($info);
            if ($info && $info->{lang}) {
                if ($info->{lang} =~ m/^\s*([a-z]{2,3})\s*$/s) {
                    $lang = $1;
                    print "Language is $lang\n" if $debug;
                }
            }
        };
    }

    my $filter = get_typography_filter($lang, $self->fix_links);

    my $outfile = $self->_outfile;
    open (my $tmpfh, '<:encoding(utf-8)', $infile)
      or die "Can't open $infile $!";
    open (my $auxfh, '>:encoding(utf-8)', $outfile)
      or die "Can't open $outfile $!";

    my $line;
    while (<$tmpfh>) {
        $line = $_;
        # some bad things we want to filter anyway
        $line =~ s/ﬁ/fi/g ;
        $line =~ s/ﬂ/fl/g ;
        $line =~ s/ﬃ/ffi/g ;
        $line =~ s/ﬄ/ffl/g ;
        $line =~ s/ﬀ/ff/g ;

        $line =~ s/\r//;
        $line =~ s/\t/    /;
        if ($filter) {
            $line = $filter->($line);
        }
        print $auxfh $line;
    }
    # last line
    if ($line !~ /\n$/s) {
        print $auxfh "\n";
    }
    close $auxfh or die $!;
    close $tmpfh or die $!;

    my $output = $self->output;
    if (my $ref = ref($output)) {
        if ($ref eq 'SCALAR') {
            $$output = $self->_read_file($outfile);
        }
    }
    else {
        File::Copy::move($outfile, $output)
            or die "Cannot move $outfile to $output, $!";
    }
    return $output;
}

sub _process_html {
    my $self = shift;
    # read the infile, process, overwrite. Doc states that it's just lame.
    my $body = $self->_read_file($self->_infile);
    my $html = Text::Amuse::Preprocessor::HTML::html_to_muse($body);
    $self->_write_file($self->_infile, $html);
}

sub _write_file {
    my ($self, $file, $body) = @_;
    die unless $file && $body;
    open (my $fh, '>:encoding(UTF-8)', $file) or die "opening $file $!";
    print $fh $body;
    close $fh or die "closing $file: $!";

}

sub _read_file {
    my ($self, $file) = @_;
    die unless $file;
    open (my $fh, '<:encoding(UTF-8)', $file) or die $!;
    local $/ = undef;
    my $body = <$fh>;
    close $fh;
    return $body;
}



sub _set_infile {
    my $self = shift;
    my $input = $self->input;
    if (my $ref = ref($input)) {
        if ($ref eq 'SCALAR') {
            my $infile = File::Spec->catfile($self->tmpdir, 'input.txt');
            open (my $fh, '>:encoding(UTF-8)', $infile) or die "$infile: $!";
            print $fh $$input;
            close $fh or die "closing $infile $!";
            $self->_infile($infile);
        }
        else {
            die "not a scalar ref!";
        }
    }
    else {
        $self->_infile($input);
    }
}


=head2 html_to_muse

Can be called on the class and will invoke the
L<Text::Amuse::Preprocessor::HTML>'s C<html_to_muse> function on the
argument returning the converted chunk.

=cut

sub html_to_muse {
    my ($self, $text) = @_;
    return unless defined $text;
    return Text::Amuse::Preprocessor::HTML::html_to_muse($text);
}

=head2 error

Return a string with the errors caught, an empty string otherwise.

=cut

sub error {
    return shift->{_error};
}

sub _set_error {
    my $self = shift;
    $self->{_error} = shift;
}

=head2 tmpdir

Return the directory name used internally to hold the temporary files.

=cut

sub tmpdir {
    my $self = shift;
    unless ($self->{_tmpdir}) {
        $self->{_tmpdir} = File::Temp->newdir(CLEANUP => !$self->debug);
    }
    return $self->{_tmpdir}->dirname;
}


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author's email. If
you find a bug, please provide a minimal muse file which reproduces
the problem (so I can add it to the test suite).

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Amuse::Preprocessor

Repository available at Gitorious:
L<https://gitorious.org/text-amuse-preprocessor>

=head1 SEE ALSO

The original documentation for the Emacs Muse markup can be found at:
L<http://mwolson.org/static/doc/muse/Markup-Rules.html>

The parser itself is L<Text::Amuse>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Text::Amuse::Preprocessor
