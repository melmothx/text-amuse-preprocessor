#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 18;
use Text::Amuse::Preprocessor;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";


my $input = <<'INPUT';
U+FB00	ﬀ	ef ac 80	LATIN SMALL LIGATURE FF       ﬀ
U+FB01	ﬁ	ef ac 81	LATIN SMALL LIGATURE FI       ﬁ
U+FB02	ﬂ	ef ac 82	LATIN SMALL LIGATURE FL       ﬂ
U+FB03	ﬃ	ef ac 83	LATIN SMALL LIGATURE FFI      ﬃ
U+FB04	ﬄ	ef ac 84	LATIN SMALL LIGATURE FFL      ﬄ
INPUT

my $expected = <<'OUT';
U+FB00    ff    ef ac 80    LATIN SMALL LIGATURE FF       ff
U+FB01    fi    ef ac 81    LATIN SMALL LIGATURE FI       fi
U+FB02    fl    ef ac 82    LATIN SMALL LIGATURE FL       fl
U+FB03    ffi    ef ac 83    LATIN SMALL LIGATURE FFI      ffi
U+FB04    ffl    ef ac 84    LATIN SMALL LIGATURE FFL      ffl
OUT

test_strings(ligatures => $input, $expected);

test_strings(missing_nl => "hello\nthere", "hello\nthere\n");

test_strings('garbage',
             "hello ─ there hello ─ there\r\n\t",
             "hello — there hello — there\n    \n");
             

$input =<<'INPUT';
https://anarhisticka-biblioteka.net/library/

<br>http://j12.org/spunk/ http://j12.org/spunk/<br>http://j12.org/spunk/

<br>https://anarhisticka-biblioteka.net/library/erik-satie-depesa<br>https://anarhisticka-biblioteka.net/library/erik-satie-depesa

[[http://j12.org/spunk/][j12.org]]<br>[[http://j12.org/spunk/][j12.org]]

[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]

http://en.wiktionary.org/wiki/%EF%AC%85

http://en.wikipedia.org/wiki/Pi_%28disambiguation%29

http://en.wikipedia.org/wiki/Pi_%28instrument%29

(http://en.wikipedia.org/wiki/Pi_%28instrument%29)

as seen in http://en.wikipedia.org/wiki/Pi_%28instrument%29.

as seen in http://en.wikipedia.org/wiki/Pi_%28instrument%29 and (http://en.wikipedia.org/wiki/Pi_%28instrument%29).
INPUT

$expected =<<'OUTPUT';
[[https://anarhisticka-biblioteka.net/library/][anarhisticka-biblioteka.net]]

<br>[[http://j12.org/spunk/][j12.org]] [[http://j12.org/spunk/][j12.org]]<br>[[http://j12.org/spunk/][j12.org]]

<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]

[[http://j12.org/spunk/][j12.org]]<br>[[http://j12.org/spunk/][j12.org]]

[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]

[[http://en.wiktionary.org/wiki/%EF%AC%85][en.wiktionary.org]]

[[http://en.wikipedia.org/wiki/Pi_%28disambiguation%29][en.wikipedia.org]]

[[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]]

([[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]])

as seen in [[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]].

as seen in [[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]] and ([[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]]).
OUTPUT

my $original_input = $input;
my $original_expected = $expected;

test_strings(links => $input, $expected, 0, 1, 0);

$input =<<'IN';
#lang en

common: ﬁ ﬂ ﬃ ﬄ ﬀ ﬁ ﬂ ﬃ ﬄ ﬀ

This is "my quotation" and 'this' and that's all This is "my
quotation" and 'this' and that's all

10-15 and 100000-150000,10-15
 - a list

12th 13th 1st 2nd 3rd (1st and 2nd and 19th)

In the '80 and '90

- not a list - not really - no

'this' and 'this.'

"this" and "this."

''this'' and ''this''

``this`` and ``this``

`this` and `this`

''my'' ``quote"

4-5,56-18 4-5-6

http://www.sociology.ox.ac.uk/papers/dunn73-93.doc

http://www.omnipresence.mahost.org/wd-v2-1-6.htm

and -here we are- the - ósecondÓ - example

hello." hell'o"

"?hello?" "?hello?" "l'amour" 'amour'

This is "ómy quotationÓ" and 'Óthisó' and that's all

"This is a 'quotation'".

"This is a 'quotation'."

sólo Sólo sólobla blasólo sólobla blasólo blasólobla

l'"amore" l'"amore" l'ardore
IN

$expected =<<'OUT';
#lang en

common: fi fl ffi ffl ff fi fl ffi ffl ff

This is “my quotation” and ‘this’ and that’s all This is “my
quotation” and ‘this’ and that’s all

10–15 and 100000–150000,10–15
 - a list

12<sup>th</sup> 13<sup>th</sup> 1<sup>st</sup> 2<sup>nd</sup> 3<sup>rd</sup> (1<sup>st</sup> and 2<sup>nd</sup> and 19<sup>th</sup>)

In the ’80 and ’90

— not a list — not really — no

‘this’ and ‘this.’

“this” and “this.”

“this” and “this”

“this“ and “this“

‘this‘ and ‘this‘

“my” “quote”

4–5,56–18 4-5-6

[[http://www.sociology.ox.ac.uk/papers/dunn73-93.doc][www.sociology.ox.ac.uk]]

[[http://www.omnipresence.mahost.org/wd-v2-1-6.htm][www.omnipresence.mahost.org]]

and — here we are — the — ósecondÓ — example

hello.” hell’o”

“?hello?” “?hello?” “l’amour” ‘amour’

This is “ómy quotationÓ” and ‘Óthisó’ and that’s all

“This is a ‘quotation’”.

“This is a ‘quotation’.”

sólo Sólo sólobla blasólo sólobla blasólo blasólobla

l’“amore” l’“amore” l’ardore
OUT

test_strings(english => $input, $expected, 1, 1, 0);

$input =~ s/^(\#lang).*$/$1 fi/m;

$expected =<<'OUT';
#lang fi

common: fi fl ffi ffl ff fi fl ffi ffl ff

This is ”my quotation” and ’this’ and that’s all This is ”my
quotation” and ’this’ and that’s all

10-15 and 100000-150000,10-15
 - a list

12th 13th 1st 2nd 3rd (1st and 2nd and 19th)

In the ’80 and ’90

– not a list – not really – no

’this’ and ’this.’

”this” and ”this.”

”this” and ”this”

”this” and ”this”

’this’ and ’this’

”my” ”quote”

4-5,56-18 4-5-6

[[http://www.sociology.ox.ac.uk/papers/dunn73-93.doc][www.sociology.ox.ac.uk]]

[[http://www.omnipresence.mahost.org/wd-v2-1-6.htm][www.omnipresence.mahost.org]]

and – here we are – the – ósecondÓ – example

hello.” hell’o”

”?hello?” ”?hello?” ”l’amour” ’amour’

This is ”ómy quotationÓ” and ’Óthisó’ and that’s all

”This is a ’quotation’”.

”This is a ’quotation’.”

sólo Sólo sólobla blasólo sólobla blasólo blasólobla

l’”amore” l’”amore” l’ardore
OUT

test_strings(finnish => $input, $expected, 1, 1, 0);

$input =~ s/^(\#lang).*$/$1 es/m;

$expected =<<'OUT';
#lang es

common: fi fl ffi ffl ff fi fl ffi ffl ff

This is «my quotation» and ‘this’ and that’s all This is «my
quotation» and ‘this’ and that’s all

10-15 and 100000-150000,10-15
 - a list

12th 13th 1st 2nd 3rd (1st and 2nd and 19th)

In the ’80 and ’90

— not a list — not really — no

‘this’ and ‘this.’

«this» and «this.»

«this» and «this»

«this« and «this«

‘this‘ and ‘this‘

«my» «quote»

4-5,56-18 4-5-6

[[http://www.sociology.ox.ac.uk/papers/dunn73-93.doc][www.sociology.ox.ac.uk]]

[[http://www.omnipresence.mahost.org/wd-v2-1-6.htm][www.omnipresence.mahost.org]]

and — here we are — the — ósecondÓ — example

hello.» hell’o»

«?hello?» «?hello?» «l’amour» ‘amour’

This is «ómy quotationÓ» and ‘Óthisó’ and that’s all

«This is a ‘quotation’».

«This is a ‘quotation’.»

sólo Sólo sólobla blasólo sólobla blasólo blasólobla

l’«amore» l’«amore» l’ardore
OUT

test_strings(spanish => $input, $expected, 1, 1, 0);

$input =~ s/^(\#lang).*$/$1 sr/m;

$expected = <<'OUT';
#lang sr

common: fi fl ffi ffl ff fi fl ffi ffl ff

This is „my quotation“ and ‚this‘ and that’s all This is „my
quotation“ and ‚this‘ and that’s all

10-15 and 100000-150000,10-15
 - a list

12th 13th 1st 2nd 3rd (1st and 2nd and 19th)

In the ’80 and ’90

– not a list – not really – no

‚this‘ and ‚this.‘

„this“ and „this.“

„this“ and „this“

„this„ and „this„

‚this‚ and ‚this‚

„my“ „quote“

4-5,56-18 4-5-6

[[http://www.sociology.ox.ac.uk/papers/dunn73-93.doc][www.sociology.ox.ac.uk]]

[[http://www.omnipresence.mahost.org/wd-v2-1-6.htm][www.omnipresence.mahost.org]]

and – here we are – the – ósecondÓ – example

hello.“ hell’o“

„?hello?“ „?hello?“ „l’amour“ ‚amour‘

This is „ómy quotationÓ“ and ‚Óthisó‘ and that’s all

„This is a ‚quotation‘“.

„This is a ‚quotation‘.“

sólo Sólo sólobla blasólo sólobla blasólo blasólobla

l’„amore“ l’„amore“ l’ardore
OUT

test_strings(serbian => $input, $expected, 1, 1, 0);

$input =~ s/^(\#lang).*$/$1 hr/m;

$expected = <<'OUT';
#lang hr

common: fi fl ffi ffl ff fi fl ffi ffl ff

This is »my quotation« and ‚this’ and that’s all This is »my
quotation« and ‚this’ and that’s all

10-15 and 100000-150000,10-15
 - a list

12th 13th 1st 2nd 3rd (1st and 2nd and 19th)

In the ’80 and ’90

— not a list — not really — no

‚this’ and ‚this.’

»this« and »this.«

»this« and »this«

»this» and »this»

‚this‚ and ‚this‚

»my« »quote«

4-5,56-18 4-5-6

[[http://www.sociology.ox.ac.uk/papers/dunn73-93.doc][www.sociology.ox.ac.uk]]

[[http://www.omnipresence.mahost.org/wd-v2-1-6.htm][www.omnipresence.mahost.org]]

and — here we are — the — ósecondÓ — example

hello.« hell’o«

»?hello?« »?hello?« »l’amour« ‚amour’

This is »ómy quotationÓ« and ‚Óthisó’ and that’s all

»This is a ‚quotation’«.

»This is a ‚quotation’.«

sólo Sólo sólobla blasólo sólobla blasólo blasólobla

l’»amore« l’»amore« l’ardore
OUT

test_strings(croatian => $input, $expected, 1, 1, 0);

sub test_strings {
    my ($name, $input, $expected, $typo, $links, $fn) = @_;

    my $input_string = $input;
    my $output_string = '';

    my $pp = Text::Amuse::Preprocessor->new(input => \$input_string,
                                            output => \$output_string,
                                            fix_links => $links,
                                            fix_typography => $typo,
                                            fix_footnotes => $fn,
                                           );
    $pp->process;
    is_deeply([ split /\n/, $output_string ],
              [ split /\n/, $expected ],
              "$name with reference works");
    
    # and the file variant
    my $dir = File::Temp->newdir(CLEANUP => 0);
    my $wd = $dir->dirname;
    my $infile = catfile($wd, 'in.muse');
    my $outfile = catfile($wd, 'out.muse');
    diag "Using $wd for $name";
    write_file($infile, $input);

    my $pp_file = Text::Amuse::Preprocessor->new(input => $infile,
                                                 output => $outfile,
                                                 fix_links => $links,
                                                 fix_typography => $typo,
                                                 fix_footnotes => $fn,
                                                );
    $pp_file->process;
    is_deeply([ split /\n/, read_file($outfile) ],
              [ split /\n/, $expected ],
              "$name with files works");
}

sub read_file {
    return Text::Amuse::Preprocessor->_read_file(@_);
}

sub write_file {
    return Text::Amuse::Preprocessor->_write_file(@_);
}
