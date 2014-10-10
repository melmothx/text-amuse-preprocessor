package Text::Amuse::Preprocessor::TypographyFilters;

use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

Text::Amuse::Preprocessor::TypographyFilters - Text::Amuse::Preprocessor's filters

=head1 DESCRIPTION

Used internally by L<Text::Amuse::Preprocessor>.

=head1 FUNCTIONS

=head2 linkify($string);

Activate links in $string and returns it.

=cut

sub linkify {
    my $l = shift;
    return unless defined $l;
    $l =~ s{(?<!\[) # be sure not to redo the same thing, looking behind
            ((https?:\/\/) # protocol
                (\w[\w\-\.]+\.\w+) # domain
                (\:\d+)? # the port
                (/ # a slash
                    [^\[<>\s]* # everything that is not a space, a < > and a [
                    [\w/] # but end with a letter or a slash
                )?
            )
            (?!\]) # and look around
       }{[[$1][$3]]}gx;
    return $l;
}

1;
