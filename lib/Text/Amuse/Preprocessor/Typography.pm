# -*- mode: cperl -*-
package Text::Amuse::Preprocessor::Typography;

use 5.010001;
use strict;
use warnings;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw/typography_filter linkify_filter/;

our $VERSION = '0.01';

sub linkify_filter {
  my $l = shift;
  $l =~ s{
	   (?<!\[) # be sure not to redo the same thing, looking behind
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


sub _typography_filter_common {
  my $l = shift;
  $l =~ s/ﬁ/fi/g ;
  $l =~ s/ﬂ/fl/g ;
  $l =~ s/ﬃ/ffi/g ;
  $l =~ s/ﬄ/ffl/g ;
  $l =~ s/ﬀ/ff/g ;

  return $l;
}


sub _typography_filter_en {
  my $l = shift;
  # then the quotes
  # ascii style
  $l =~ s/``/“/g ;
  $l =~ s/(''|")\b/“/g ;
  $l =~ s/(?<=\s)(''|")/“/gs;
  $l =~ s/^(''|")/“/gm;
  $l =~ s/(''|")/”/g ;

  # single
  $l =~ s/'(?=[0-9])/’/g;
  $l =~ s/`/‘/g;
  $l =~ s/\b'/’/g;
  $l =~ s/'\b/‘/g;
  $l =~ s/^'/‘/gm;
  $l =~ s/'/’/g;

  # the dashes
  # this is the en-dash –
  $l =~ s/(?<![\-\/])\b(\d+)-(\d+)\b(?![\-\/])/$1–$2/g ;

  # em-dash —
  $l =~ s/(?<=\S) +-{1,3} +(?=\S)/ — /gs;

  # and the common case ^th
  $l =~ s!\b(\d+)(th|rd|st|nd)\b!$1<sup>$2</sup>!g;
  $l =~ s/(\. ){2,3}\./.../g;
  return $l;
}

sub _typography_filter_es {
  my $l = shift;

  # em-dash —
  # look behind and check it's not a \n
  # not a spece, space, one-three hypens, space, not a space => space — space
  $l =~ s/(?<=\S) +-{1,3} +(?=\S)/ — /gs;
  # - at beginning of the line (with no space), it's a dialog (em dash)
  $l =~ s/^- */— /gm;


  # I believe the following rules are dangerous. What if someone says:
  # "the bit- and byte-wise" => "the bit — and byte-wise" !!!!
  # I believe they should be removed.

#   # fix "example- "
#   $l =~ s/ +-(?=\S)/ — /;
#   # and " -example"
#   $l =~ s/(?<=\S)- +/ — /;

  # better idea: check for matching on the same line
  $l =~ s/ +-(\w.+?\w)- +/ — $1 — /gm;

  # if it touches a word on the right, and on the left there is not a
  # word, it's an opening quote
  $l =~ s/(?<=\W)"(?=\w)/«/gs;
  $l =~ s/(?<=\W)'(?=\w)/‘/g;

  # if there is a space at the left, it's opening
  $l =~ s/(?<=\s)"/«/gs; 
  $l =~ s/(?<=\s)'/‘/gs;

  # beginning of line, opening
  $l =~ s/^"/«/gm; 
  $l =~ s/^'/‘/gm;

  # word at the left, closing
  $l =~ s/(?<=\w)'/’/g;
  $l =~ s/(?<=\w)"/»/g;

  # the others are right quotes, hopefully
  $l =~ s/"/»/gs;
  $l =~ s/'/’/g;

  # now the dots at the end of the quotations, but look behind not to
  # have another dot
  #  $l =~ s/(?<!\.)\.»(?=\s)/»./gs;
  
  return $l;
}


sub _typography_filter_fi {
  my $l = shift;
  $l =~ s/"/\x{201d}/g;
  $l =~ s/'/\x{2019}/g;
  $l =~ s/(?<=\S) +--? +(?=\S)/ \x{2013} /gs;
  return $l;
}

sub _typography_filter_sr {
  my $l = shift;
  $l =~ s/(''|")\b/\x{201e}/g ;
  $l =~ s/(?<=\s)(''|")/\x{201e}/gs;
  $l =~ s/(''|")/\x{201c}/g ;
  $l =~ s/(?<=\W)'(.*?)'(?=\W)/\x{201a}$1\x{2018}/gs;
  $l =~ s/'/\x{2019}/g; # remaining apostrophes
  $l =~ s/(?<=\S) +--? +(?=\S)/ \x{2013} /gs;
  return $l;
}

sub _typography_filter_hr {
  my $l = shift;
  $l =~ s/(''|")\b/\x{201e}/g ;
  $l =~ s/(?<=\s)(''|")/\x{201e}/gs;
  $l =~ s/(''|")/\x{201d}/g ; # ”
  $l =~ s/(?<=\W)'(.*?)'(?=\W)/\x{201a}$1\x{2019}/gs; # ‚ ’
  $l =~ s/'/\x{2019}/g;  # remaining apostrophes
  $l =~ s/(?<=\S) +--? +(?=\S)/ \x{2014} /gs; # —
  return $l;
}


sub _typography_filter_ru {
  my $l = shift;
  $l =~ s/(?<=\s)(''|")/«/gs;
  $l =~ s/^(''|")/«/gm;
  $l =~ s/(''|")\b/«/gs;
  $l =~ s/(''|")/»/g ;
  $l =~ s/'(?=[0-9])/’/g;
  $l =~ s/`/‘/g;
  $l =~ s/\b'/’/g;
  $l =~ s/'\b/‘/g;
  $l =~ s/'/’/g;
  # em-dash —
  $l =~ s/(?<=\S) +-{1,3} +(?=\S)/ — /gs;
  $l =~ s/(\. ){2,3}\./.../g;
  return $l;
}


my $lang_filters = {
		    en => \&_typography_filter_en,
		    fi => \&_typography_filter_fi,
		    hr => \&_typography_filter_hr,
		    sr => \&_typography_filter_sr,
		    ru => \&_typography_filter_ru,
		    es => \&_typography_filter_es,
		   };

sub typography_filter {
  my $lang = $_[0];
  my $text = " " . $_[1] . " ";
  $text = _typography_filter_common($text);
  if ($lang and exists $lang_filters->{$lang}) {
    $text = $lang_filters->{$lang}->($text);
  }
  my $llength = length($text) - 2; 
  return substr($text, 1, $llength);
}


1;
__END__

=encoding utf8

=head1 NAME

Text::Amuse::Preprocessor::Typography - Perl extension for pre-processing of Text::Amuse files

=head1 SYNOPSIS

  use Text::Amuse::Preprocessor::Typography qw/typography_filter/;
  my $cleanedtext = typography_filter($lang, $text)
  

=head1 DESCRIPTION

Common routines to filter the input files, fixing typography and
language-specific rules. All the text is assumed to be already decoded.

=head1 FUNCTIONS

=head2 linkify_filter($string)

Detect and replace the bare links with the proper markup, as
[[http://domain.org/my/url/and_params?a=1&b=c][domain.org]]

It's a bit opinionated to hide the full url and show only the domain.
Anyway, it's a preprocessing filter and the most important thing is
not to loose pieces. And we don't, because the full url is still
there. Anyway, long urls are a pain to display and to typeset, so the
domain is a sensible choise. The user can anyway change this. It's
just an helper to avoid boring tasks, nothing more.

Returns the adjusted string.

=head2 typography_filter($lang, $string)

Perform the smart replacement of single quotes, double quotes, dashes
and, in some cases, the superscript for things like 2nd, 13th, etc.

The languages supported are C<en>, C<fi>, C<hr>, C<sr>, C<ru>, C<es>.

Returns the adjusted string.


=head1 SEE ALSO

Text::Muse
Text::Muse::Formats
Text::Muse::EPUB

The Muse homepage: http://mwolson.org/projects/EmacsMuse.html

The Anarchist Library project: http://theanarchistlibrary.org

=head1 AUTHOR

Marco Pessotto, marco@theanarchistlibrary.org

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
