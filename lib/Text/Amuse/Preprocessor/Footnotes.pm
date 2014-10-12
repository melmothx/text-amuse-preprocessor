package Text::Amuse::Preprocessor::Footnotes;

use strict;
use warnings;
use File::Spec;
use File::Temp;
use File::Copy;
use Data::Dumper;

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

    while (my $r = <$in>) {
        # a footnote
        if ($r =~ s/^\[\d+\](?=\s)/'[' . ++$fn_counter . ']'/e) {
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
        $r =~ s/\[\d{1,4}\]/"[" . ++$body_fn_counter . "]"/ge;
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
        $self->_set_error({
                           references => $body_fn_counter,
                           footnotes  => $fn_counter,
                          });
        return;
    }
}

1;
