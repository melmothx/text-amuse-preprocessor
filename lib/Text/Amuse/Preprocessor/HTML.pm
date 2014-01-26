package Text::Amuse::Preprocessor::HTML;

use 5.010001;
use strict;
use warnings;
use utf8;
# use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw( html_to_muse );

our $VERSION = '0.01';

=head1 NAME

Text::Amuse::Preprocessor::HTML - HTML importer

=head1 DESCRIPTION

This module tries its best to convert the HTML into an acceptable
Muse string. It's not perfect, though, and some manual adjustment is
needed if there are tables or complicated structures.

=head1 SYNOPSIS

  use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
  my $html = '<p>Your text here... &amp; &quot; &ograve;</p>'
  my $muse = html_to_muse($html);

=cut

use HTML::PullParser;

my %microshitreplace = (
	'&#130;' => '&#8218;',
	'&#131;' => '&#402;',
	'&#132;' => '&#8222;',
	'&#133;' => '&#8230;',
	'&#134;' => '&#8224;',
	'&#135;' => '&#8225;',
	'&#136;' => '&#710;',
	'&#137;' => '&#8240;',
	'&#138;' => '&#352;',
	'&#139;' => '&#8249;',
	'&#140;' => '&#338;',
	'&#145;' => '&#8216;',
	'&#146;' => '&#8217;',
	'&#147;' => '&#8220;',
	'&#148;' => '&#8221;',
	'&#149;' => '&#8226;',
	'&#150;' => '&#8211;',
	'&#151;' => '&#8212;',
	'&#152;' => '&#732;',
	'&#153;' => '&#8482;',
	'&#154;' => '&#353;',
	'&#155;' => '&#8250;',
	'&#156;' => '&#339;',
	'&#159;' => '&#376;',
);



my %preserved = (
		 "em" => ["<em>", "</em>"],
		 "i"  => ["<em>", "</em>"],
		 "u"  => ["<em>", "</em>"],
		 "strong" => ["<strong>", "</strong>"],
		 "b"      => ["<strong>", "</strong>"],
		 "blockquote" => ["\n<quote>\n", "\n</quote>"],
		 "ol" => ["\n\n", "\n\n"],
		 "ul" => ["\n\n", "\n\n"],
		 "li" => { ol => [ " 1. ", "\n\n"],
			   ul => [ " - ", "\n\n"],
			 },
		 "code" => ["<code>", "</code>"],
		 "a" => ["[[", "]]"],
		 "pre" => [ "\n<example>\n", "\n<example>\n" ],
		 "tr" => ["\n", "\n"],
		 "td" => [" | ", " " ],
		 "th" => [ " || ", " " ],
		 "dd" => ["\n\n", "\n\n"],
		 "dt" => ["\n***** ", "\n\n" ],
		 "h1" => ["\n* ", "\n\n"],
		 "h2" => ["\n* ", "\n\n"],
		 "h3" => ["\n** ", "\n\n"],
		 "h4" => ["\n*** ", "\n\n"],
		 "h5" => ["\n**** ", "\n\n"],
		 "h6" => ["\n***** ", "\n\n"],
		 "sup" => ["<sup>", "</sup>" ],
		 "sub" => ["<sub>", "</sub>" ],
		 "strike" => ["<del>", "</del>"],
		 "del" => ["<del>", "</del>"],
		 "p" => ["\n\n", "\n\n"],
		 "br" => ["\n\n", "\n\n"], # if you're asking why, a
                                           # lot of pages use the br
                                           # as a <p>
		 "div" => ["\n\n", "\n\n"],
		 "center" => ["\n\n<center>\n", "\n</center>\n\n"],
		 "right"  => ["\n\n<right>\n", "\n</right>\n\n"],
		 
);

=head1 FUNCTIONS

=head2 html_to_muse($html_decoded_text)

The first argument must be a decoded string with the HTML text.
Returns the L<Text::Amuse> formatted body.

=cut

sub html_to_muse {
  my ($rawtext, $debug) = @_;
  return unless defined $rawtext;
  # preliminary cleaning
  $rawtext =~ s!\t! !gs; # tabs are evil
  $rawtext =~ s!\r! !gs; # \r is evil
  $rawtext =~ s!\n! !gs;

  # pack the things like hello<em> there</em> with space. Be careful
  # with recursions.
  my $recursion = 0;
  while (($rawtext =~ m!( </|<[^/]+?> )!) && ($recursion < 20)) {
    $rawtext =~ s!( +)(</.*?>)!$2$1!g;
    $rawtext =~ s!(<[^/]*?>)( +)!$2$1!g;
    $recursion++;
  }
  undef $recursion;
  $rawtext =~ s/ +$//gm;
  $rawtext =~ s/^ +//gm;
  $rawtext =~ s!  +! !g;
  # clear text around <br> 
  $rawtext =~ s! *<br ?/?> *!<br />!g;
  return unless $rawtext;
  # first clean up the legacy M$ entities, maybe not needed.
  foreach my $string (keys %microshitreplace) {
    my $tostring = $microshitreplace{$string};
    $rawtext =~ s/\Q$string\E/$tostring/g;
  }
  warn $rawtext if $debug;
  my $p = HTML::PullParser->new(
				start => '"S", tagname, attr',
				end   => '"E", tagname',
				text => '"T", dtext',
				empty_element_tags => 1,
				marked_sections => 1,
				unbroken_text => 1,
				ignore_elements => [qw(script style)],
				doc => \$rawtext,
			       ) or warn "$!\n";
  
  my @textstack;
  my @spanpile;
  my @lists;
  my @parspile;
  while (my $token = $p->get_token) {
    my $type = shift @$token;

    # starttag?
    if ($type eq 'S') {
      my $tag = shift @$token;
      my $attr = shift @$token;
      # see if processing of span or font are needed
      if (($tag eq 'span') or ($tag eq 'font')) {
	$tag = _span_process_attr($attr);
	push @spanpile, $tag;
      }
      elsif (($tag eq "ol") or ($tag eq "ul")) {
	push @lists, $tag;
      }
      elsif (($tag eq 'p') or ($tag eq 'div')) {
	$tag = _pars_process_attr($tag, $attr);
	push @parspile, $tag;
      }
      # see if we want to skip it.
      if ((defined $tag) && (exists $preserved{$tag})) {

	# is it a list?
	if (ref($preserved{$tag}) eq "HASH") {
	  # does it have a parent?
	  if (my $parent = $lists[$#lists]) {
	    push @textstack, "\n",
	      "    " x $#lists,
		$preserved{$tag}{$parent}[0];
	  } else {
	    push @textstack, "\n",
	      $preserved{$tag}{ul}[0];
	  }
	}
	# no? ok
	else {
	  push @textstack, $preserved{$tag}[0];
	}
      }
      if ((defined $tag) &&
	  ($tag eq 'a') &&
	  (my $href =  $attr->{href})) {
	push @textstack, $href, "][";
      }
    }

    # stoptag?
    elsif ($type eq 'E') {
      my $tag = shift @$token;
      if (($tag eq 'span') or ($tag eq 'font')) {
	$tag = pop @spanpile;
      }
      elsif (($tag eq "ol") or ($tag eq "ul")) {
	$tag = pop @lists;
      }
      elsif (($tag eq 'p') or ($tag eq 'div')) {
	if (@parspile) {
	  $tag = pop @parspile
	}
      }

      if ($tag && (exists $preserved{$tag})) {
	if (ref($preserved{$tag}) eq "HASH") {
	  if (my $parent = $lists[$#lists]) {
	    push @textstack, $preserved{$tag}{$parent}[1];
	  } else {
	    push @textstack, $preserved{$tag}{ul}[1];
	  }
	} else {
	  push @textstack, $preserved{$tag}[1];
	}
      }
    }
    # regular text
    elsif ($type eq 'T') {
      my $line = shift @$token;
      unless ($line =~ m/^[ \x{a0}]*$/s) {
	$line =~ s/ / /g; # Word &C. (and CKeditor), love the no-break space.
	# but preserve it it's only whitespace in the line.
      }
      push @textstack, $line;
    } else {
      warn "which type? $type??\n"
    }
  }
  my $parsed = join("", @textstack);
  $parsed =~ s/ +$//gm;
  $parsed =~ s/\n\n\n+/\n\n/gs;
  # clean the footnotes.
  $parsed =~ s!\[
	       \[
	       \#\w+ # the anchor
	       \]
	       \[
	       (<(sup|strong|em)>|\[)? # sup or [ 
	       \[*
	       (\d+) # the number
	       \]*
	       (</(sup|strong|em)>|\])? # sup or ]
	       \] # close 
	       \] # close
	      ![$3]!gx;
  # add a space if missing
  return $parsed;
}

sub _span_process_attr {
  my $attr = shift;
  my $tag;
  my @attrsvalues = values %$attr;
  if (grep(/italic/i, @attrsvalues)) {
    $tag = "em";
  }
  elsif (grep(/bold/i, @attrsvalues)) {
    $tag = "strong";
  }
  else {
    $tag = undef;
  }
  return $tag;
}

sub _pars_process_attr {
  my ($tag, $attr) = @_;
# warn Dumper($attr);
  if (my $style = $attr->{style}) {
    if ($style =~ m/text-align:\s*center/i) {
      $tag = 'center';
    }
    if ($style =~ m/text-align:\s*right/i) {
      $tag = 'right';
    }
  }
  if (my $align = $attr->{align}) {
    if ($align =~ m/center/i) {
      $tag = 'center';
    }
    if ($align =~ m/right/i) {
      $tag = 'right';
    }
  }
  return $tag;
}

1;


=head1 AUTHOR, LICENSE, ETC.,

See L<Text::Amuse::Preprocessor>

=cut

# Local Variables:
# tab-width: 8
# cperl-indent-level: 2
# End:
