package Text::Amuse::Preprocessor::Parser;

use utf8;
use strict;
use warnings;

sub parse_text {
    my $string = shift;
    $string =~ s/[\r\0]//g;
    $string =~ s/\t/    /g;
    if ($string !~ m/\n\z/s) {
        $string .= "\n";
    }
    my @list;
    my $last_position = 0;
    pos($string) = $last_position;
    while ($string =~ m{\G # last match
                        (?<text>.*?) # something not greedy, even nothing
                        (?<markup>
                            (?<example>^\{\{\{     \x{20}*?\n .*? \n\}\}\}\n) |
                            (?<example>^\<example\>\x{20}*?\n .*? \n\</example\>\n) |
                            (?<newparagraph> \n\n+?) |
                            (?<verbatim>      \<verbatim\> .*? \<\/verbatim\>      ) |
                            (?<verbatim_code> \<code\>     .*? \<\/code\>          ) |
                            (?<verbatim_code> (?<![[:alnum:]])\=(?=\S)  .+? (?<=\S)\=(?![[:alnum:]]) )
                        )}gcxms) {
        my %captures = %+;
        if (length($captures{text})) {
            my @lines = split(/(\n)/, $captures{text});
            push @list, map { +{ type => 'text', string => $_ } } grep { length($_) } @lines;
        }
        push @list, {
                     type => 'markup',
                     string => $captures{markup},
                    };
        $last_position = pos($string);
    }
    my $last_chunk = substr $string, $last_position;
    if (length($last_chunk)) {
        my @lines = split(/(\n)/, $last_chunk);
        push @list, map { +{ type => 'text', string => $_  } } grep { length($_) } @lines;
    }
    my $full = join('', map { $_->{string} } @list);
    die "Chunks lost during processing <$string> vs. <$full>" unless $string eq $full;
    return @list;
}

1;
