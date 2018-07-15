use strict;
use warnings;
use utf8;

use File::Temp;
use Data::Dumper;
use Test::More tests => 1;

BEGIN {
    if (!eval q{ use Test::Differences; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";
use Text::Amuse::Preprocessor::HTML qw/html_to_muse html_file_to_muse/;

{
    my $in = <<'HTML';

The drama off stage.<p />
<p style="padding-left: 30px;">"The French revolution was a series."</p><p />
<p style="padding-left: 30px;">"This is not to equalize "</p><p />
Many in the audience were horrified.<p />
HTML
    my $out = <<'MUSE';
The drama off stage.

<quote>
"The French revolution was a series."
</quote>

<quote>
"This is not to equalize "
</quote>

Many in the audience were horrified.

MUSE
    eq_or_diff(html_to_muse($in), $out);
}
