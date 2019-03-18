#!perl
use utf8;
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 4;
use Text::Amuse::Preprocessor;
use Text::Amuse::Preprocessor::Parser;

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";


for (1,2) {
    my $input = <<'MUSE';
#title The Text::Amuse markup manual
#lang en

If you need <verbatim>[10]</verbatim> to start a line with an hash, wrap it in =<verbatim>= E.g.

{{{
#hashtag verbatim.
=#hashtag= verbatim as code.
}}}

"Yielding": [4]

<verbatim>#hashtag 'hash'</verbatim> verbatim.

<example>
"x" '[3]'

[1] 'test' "test" l'albero
</example>

[4] Real "footnote" {5}

{6} "Hellow"
MUSE

    my $expected = <<'MUSE';
#title The Text::Amuse markup manual
#lang en

If you need <verbatim>[10]</verbatim> to start a line with an hash, wrap it in =<verbatim>= E.g.

{{{
#hashtag verbatim.
=#hashtag= verbatim as code.
}}}

“Yielding”: [1]

<verbatim>#hashtag 'hash'</verbatim> verbatim.

<example>
"x" '[3]'

[1] 'test' "test" l'albero
</example>

[1] Real “footnote” {1}

{1} “Hellow”
MUSE
    my $output = '';
    my @parsed = Text::Amuse::Preprocessor::Parser::parse_text($input);
    # diag Dumper(\@parsed);
    my $pp = Text::Amuse::Preprocessor->new(
                                            input => \$input,
                                            output => \$output,
                                            debug => 0,
                                            fix_links => 1,
                                            fix_typography => 1,
                                            fix_nbsp => 1,
                                            fix_footnotes  => 1,
                                           )->process;
    ok $output;
    eq_or_diff($output, $expected);
}

{
    my @parsed = Text::Amuse::Preprocessor::Parser::parse_text(Text::Amuse::Preprocessor->_read_file('t/footnotes/verbatim-in.muse'));
}
