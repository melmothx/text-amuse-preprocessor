use 5.010001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::Amuse::Preprocessor',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Text/Amuse/Preprocessor.pm',
    ABSTRACT_FROM    => 'lib/Text/Amuse/Preprocessor.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTML::PullParser' => 0,
        'LWP::UserAgent' => 0,
    },
    EXE_FILES => [
        'bin/muse-rearrange-footnotes.pl',
        'bin/html-to-muse.pl',
       ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Amuse-Preprocessor-*' },
    META_MERGE => {
        resources => {
            repository => 'https://gitorious.org/text-amuse-preprocessor'
           },
    },
);

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
