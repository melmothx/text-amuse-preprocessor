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


=head2 characters

Return an hashref where keys are the language codes, and the values an
hashref with the definition of punctuation characters. Each of them
has the following keys: C<ldouble>, C<rdouble>, C<lsingle>,
C<rsingle>, C<apos>, C<emdash>, C<endash>.

=cut

# EM-DASH: 2014
# EN-DASH: 2013

sub characters {
    return {
            en => {
                   ldouble => "\x{201c}",
                   rdouble => "\x{201d}",
                   lsingle => "\x{2018}",
                   rsingle => "\x{2019}",
                   apos => "\x{2019}",
                   emdash => "\x{2014}",
                   endash => "\x{2013}",
                  },
            es => {
                   ldouble => "\x{ab}",
                   rdouble => "\x{bb}",
                   lsingle => "\x{2018}",
                   rsingle => "\x{2019}",
                   apos => "\x{2019}",
                   emdash => "\x{2014}",
                   endash => "-",
                  },
            fi => {
                   ldouble => "\x{201d}",
                   rdouble => "\x{201d}",
                   lsingle => "\x{2019}",
                   rsingle => "\x{2019}",
                   apos => "\x{2019}",
                   # finnish uses short dash
                   emdash => "\x{2013}",
                   endash => "-",
                  },
            sr => {
                   ldouble => "\x{201e}", # german style
                   rdouble => "\x{201c}",
                   lsingle => "\x{201a}",
                   rsingle => "\x{2018}",
                   apos => "\x{2019}",
                   # serbian uses short dash. not sure
                   emdash => "\x{2013}",
                   endash => '-',
                  },
            hr => {
                   ldouble => "\x{bb}",
                   rdouble => "\x{ab}",
                   lsingle => "\x{201a}",
                   rsingle => "\x{2019}",
                   apos => "\x{2019}",
                   emdash => "\x{2014}",
                   endash => "-",
                  },
            ru => {
                   ldouble => "\x{ab}",
                   rdouble => "\x{bb}",
                   lsingle => "\x{2018}",
                   rsingle => "\x{2019}",
                   apos => "\x{2019}",
                   emdash => "\x{2014}",
                   endash => "-",
                  },
            it => {
                   ldouble => "\x{ab}",
                   rdouble => "\x{bb}",
                   lsingle => "\x{2018}",
                   rsingle => "\x{2019}",
                   apos => "\x{2019}",
                   emdash => "\x{2014}",
                   endash => "-",
                  },
#             mk => {
#                    ldouble => "\x{201c}",
#                    rdouble => "\x{201d}",
#                    lsingle => "\x{2018}",
#                    rsingle => "\x{2019}",
#                    apos => "\x{2019}",
#                    emdash => "\x{2013}",
#                    endash => "-"
#                   },
           };
}


=head2 specific_filters

Return an hashref where the key is the language codes and the value a
subroutine to filter the line.

Here we put the routines which can't be abstracted away in a
language-indipendent fashion.

=cut

sub specific_filters {
    return {
            en => sub {
                my $l = shift;
                $l =~ s!\b(\d+)(th|rd|st|nd)\b!$1<sup>$2</sup>!g;
                return $l;
            },
           };
}

=head2 specific_filter($lang)

Return the specific filter for lang, if present.

=cut

sub specific_filter {
    my ($lang) = @_;
    return unless $lang;
    return specific_filters->{$lang};
}

=head2 filter($lang)

Return a sub for the typographical fixes for the language $lang.

=cut


sub filter {
    my ($lang) = @_;
    return unless $lang;
    my $all = characters();
    my $chars = $all->{$lang};
    return unless $chars;

    # copy to avoid typos
    my $ldouble = $chars->{ldouble};
    my $rdouble = $chars->{rdouble};
    my $lsingle = $chars->{lsingle};
    my $rsingle = $chars->{rsingle};
    my $apos =    $chars->{apos};
    my $emdash =  $chars->{emdash};
    my $endash =  $chars->{endash};

    my $filter = sub {
        my $l = shift;

        # first, consider `` and '' opening and closing doubles
        $l =~ s/``/$ldouble/g;

        $l =~ s/`/$lsingle/g;

        # but set it as ", we'll replace that later
        $l =~ s/''/"/g;

        # beginning of the line, emdahs
        $l =~ s/^-(?=\s)/$emdash/;

        # between spaces, just replace
        $l =~ s/(?<=\S)(\s+)-{1,3}(\s+)(?=\S)/$1$emdash$2/g;

        # -word and word-, in the middle of a line
        $l =~ s/(?<=\S)(\s+)-(\w.+?\w)-(?=\s)/$1$emdash $2 $emdash/g;

        # an opening before two digits *probably* is an apostrophe.
        # Very common case.
        $l =~ s/'(?=\d\d\b)/$apos/g;

        # if it touches a word on the right, and on the left there is not a
        # word, it's an opening quote
        $l =~ s/(?<=\W)"(?=\w)/$ldouble/g;
        $l =~ s/(?<=\W)'(?=\w)/$lsingle/g;

        # if there is a space at the left, it's opening
        $l =~ s/(?<=\s)"/$ldouble/g;
        $l =~ s/(?<=\s)'/$lsingle/g;

        # beginning of line, opening
        $l =~ s/^"/$ldouble/;
        $l =~ s/^'/$lsingle/;

        # print encode('UTF-8', "**** $l");

        # apostrophes, between non-white material, probably
        $l =~ s/(?<=\w)'(?=\w)/$apos/g;

        # print encode('UTF-8', "**** $l");

        # or before a left quote
        $l =~ s/(?<=\w)'(\Q$lsingle\E)/$apos$1/g;
        $l =~ s/(?<=\w)'(\Q$ldouble\E)/$apos$1/g;

        # print encode('UTF-8', "**** $l");

        # word at the left, closing
        $l =~ s/(?<=\w)"(?=\W)/$rdouble/g;
        $l =~ s/(?<=\w)'(?=\W)/$rsingle/g;


        # the others are right quotes, hopefully
        $l =~ s/"/$rdouble/gs;
        $l =~ s/'/$rsingle/g;

        # replace with an endash, but only if between digits and not
        # in the middle of something
        $l =~ s/(?<![\-\/])\b(\d+)-(\d+)\b(?![\-\/])/$1$endash$2/g;

        return $l;
    };
    return $filter;
}

1;
