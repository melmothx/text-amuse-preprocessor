package Text::Amuse::Preprocessor;

use 5.010001;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Text::Amuse::Preprocessor - Helpers for Text::Amuse document formatting.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This module by itself doesn't do anything, but the bundled modules do.

  use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
  my $html = '<p>Your text here... &amp; &quot; &ograve;</p>'
  my $muse = html_to_muse($html);

  use Text::Amuse::Preprocessor::Typography qw/typography_filter
                                               linkify_filter/;
  $muse = typography_filter(en => $muse);
  $muse = linkify_filter($muse);

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author's email. If
you find a bug, please provide a minimal muse file which reproduces
the problem (so I can add it to the test suite).

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Amuse::Preprocessor

Repository available at Gitorious:
L<https://gitorious.org/text-amuse-preprocessor>

=head1 SEE ALSO

The original documentation for the Emacs Muse markup can be found at:
L<http://mwolson.org/static/doc/muse/Markup-Rules.html>

The parser itself is L<Text::Amuse>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Text::Amuse::Preprocessor
