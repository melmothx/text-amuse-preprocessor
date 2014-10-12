package Text::Amuse::Preprocessor::Footnotes;

use strict;
use warnings;
use File::Spec;
use File::Temp;
use File::Copy;
use Data::Dumper;

=encoding utf8

=head1 NAME

Text::Amuse::Preprocessor::Footnotes - Rearrange footnote numbering in muse docs

=head1 DESCRIPTION

Given an input file, scan its footnotes and rearrange them. This means
that such document:

  #title test
  
  Hello [1] There [1] Test [1]
  
  [1] first
  
  Hello hello

  [1] second
  
  [1] third

will become

  #title test
  
  Hello [1] There [2] Test [3]
  
  Hello hello

  [1] first
  
  [2] second
  
  [3] third

Given that the effects of the rearranging could be very destructive
and mess up your documents, the module try to play on the safe side
and will refuse to write out a file if there is a count mismatch
between the footnotes and the number of references in the body.

The core concept is that the module doesn't care about the number.
Only order matters.

This could be tricky if the document uses the number between square
brackets for other than footnotes.

Also used internally by L<Text::Amuse::Preprocessor>.

=head1 METHODS

=head2 new(input => $infile, output => $outfile, debug => 0);

Constructor with the following options:

=head3 input

The input file. It must exists.

=head3 output

The output file. It will be written by the module if the parsing
succeedes.

=head3 debug

Print some additional info.

=head2 process

Do the job, write out C<output> and return C<output>. On failure, set
an arror and return false.

=head2 error

Accesso to the error. If there is a error, an hashref with the
following keys will be returned:

=over 4

=item reference

The total number of footnote references in the body.

=item footnotes

The total number of footnotes.

=item references_found

The reference's numbers found in the body as a long string.

=item footnotes_found

The footnote' numbers found in the body as a long string.

=back

=cut


sub new {
    my ($class, %options) = @_;
    my $self = {
                input => undef,
                output => undef,
                debug => 0,
               };
    foreach my $k (keys %$self) {
        if (exists $options{$k}) {
            $self->{$k} = delete $options{$k};
        }
    }
    $self->{_error} = '';

    die "Unrecognized option: " . join(keys %options) . "\n" if %options;
    die "Missing input" unless defined $self->{input};
    die "Missing output" unless defined $self->{output};
    bless $self, $class;
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

=head2 error

Return a string with the errors caught, an empty string otherwise.

=cut

sub error {
    return shift->{_error};
}

sub _set_error {
    my ($self, $error) = @_;
    $self->{_error} = $error if $error;
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

sub _fn_re {
    return qr/^\[[0-9]{1,4}\](?=\s)/;
}

sub _ref_re {
    return qr/\[[0-9]{1,4}\]/;
}

sub process {
    my $self = shift;
    print Dumper($self) if $self->debug;
    # auxiliary files
    my $tmpdir = $self->tmpdir;
    print "Using $tmpdir\n" if $self->debug;
    my $body_file  = File::Spec->catfile($tmpdir, 'body.muse');
    my $fn_file    = File::Spec->catfile($tmpdir, 'fn.muse');
    # open the auxiliary files
    open (my $body_fh, '>:encoding(UTF-8)', $body_file) or die ("$body_file $!");
    open (my $fn_fh, '>:encoding(UTF-8)', $fn_file) or die ("$fn_file $!");

    # open the input
    my $in_file = $self->input;
    open (my $in, '<:encoding(UTF-8)', $in_file) or die ("$in_file $!");
    
    # read the file.
    my $fn_counter = 0; 
    my $body_fn_counter = 0;
    my $last_was_fn = undef;

    my $fn_re = $self->_fn_re;
    my $ref_re = $self->_ref_re;
    while (my $r = <$in>) {
        # a footnote
        if ($r =~ s/$fn_re/'[' . ++$fn_counter . ']'/e) {
            # the footnotes at the end go in a separate array
            print $fn_fh $r;
            $last_was_fn = $r;
            next;
        }

        # check if we have a broken footnote and skip the first empty line
        # after that.
        if (defined $last_was_fn) {

            # if an empty linke, flip the switch
            if ($r =~ m/^\s*$/) {
                $last_was_fn = undef;
                $r = "\n";
            }
            print $fn_fh $r;
            next;
        }

        # then process the page
        $r =~ s/$ref_re/'[' . ++$body_fn_counter . ']'/ge;
        print $body_fh $r;
    }

    close $in      or die $!;
    close $body_fh or die $!;
    close $fn_fh   or die $!;

    if ($body_fn_counter == $fn_counter) {
        # all good.
        open ($body_fh, '<', $body_file)
          or die ("$body_file $!");
        open ($fn_fh, '<', $fn_file)
          or die ("$fn_file $!");
        open (my $out, '>', $self->output)
          or die $self->output . ": $!";
        while (<$body_fh>) {
            print $out $_;
        }
        while (<$fn_fh>) {
            print $out $_;
        }
        close $body_fh or die $!;
        close $fn_fh   or die $!;
        close $out     or die $!;
        print "Output in " . $self->output . "\n" if $self->debug;
        return $self->output;
    }
    else {
        $self->_report_error($body_fn_counter, $fn_counter);
        return;
    }
}

sub _report_error {
    my ($self, $body_fn_counter, $fn_counter) = @_;
    my $fn_re = $self->_fn_re;
    my $ref_re = $self->_ref_re;
    # reopen and rescan
    my $in_file = $self->input;
    open (my $in, '<:encoding(UTF-8)', $in_file) or die ("$in_file $!");
    my @footnotes;
    my @references;
    while (my $line = <$in>) {
        if ($line =~ m/$fn_re/) {
            push @footnotes, $&;
            next;
        }
        while ($line =~ m/$ref_re/g) {
            push @references, $&;
        }
    }
    close $in;
    $self->_set_error({
                       reference => $body_fn_counter,
                       footnotes => $fn_counter,
                       references_found => join(" ", @references),
                       footnotes_found  => join(" ", @footnotes),
                      });

}


1;
