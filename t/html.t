# -*- mode: cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Muse-HTML-Importer.t'

use strict;
use warnings;
use utf8;
binmode STDOUT, ":encoding(utf-8)";

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('Text::Amuse::Preprocessor::HTML') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;

my $html = '<p>
	Your text here... &amp; &quot; &ograve;</p>
<p>
Hello
</p>';

is(html_to_muse($html),
   "\n\nYour text here... & \" ò\n\nHello\n\n", "Testing a basic html");

$html = "
<p>
	&nbsp;</p>
<h1>
	This is a test</h1>
<p>
	&nbsp;</p>
<p>
	Hello &laquo;there&raquo;, with &agrave;&aelig;&aelig;\x{142}&euro;&para;&frac14;&frac12;&szlig;&eth;\x{111} some unicode</p>
<p>
	&nbsp;</p>
<blockquote>
	<p>
		A blockquote</p>
</blockquote>
<ol>
	<li>
		A list</li>
	<li>
		with another item</li>
	<li>
		another</li>
</ol>
<p>
	and</p>
<ul>
	<li>
		and a bullte list</li>
	<li>
		another item</li>
	<li>
		another</li>
</ul>
<p>
	A sub <sub>subscript&nbsp; </sub>and a <sup>superscript&nbsp; </sup>a <strike>strikeover </strike>an <em>emphasis&nbsp; </em>a <strong>double one&nbsp; </strong>and the <em><strong>bold italic</strong></em>.</p>
<p>
	&nbsp;</p>
<h2>
	Then the</h2>
<p>
	&nbsp;</p>
<h3>
	third</h3>
<h4>
	hello</h4>
<h5>
	fifth</h5>
<p>
	&nbsp;</p>
<h6>
	sixst</h6>
<p>
	&nbsp;</p>
<p>
	finally finished</p>
";

my $expected = '

 

* This is a test

 

Hello «there», with àææł€¶¼½ßðđ some unicode

 

<quote>

A blockquote

</quote>

 1. A list

 1. with another item

 1. another

and

 - and a bullte list

 - another item

 - another

A sub <sub>subscript </sub> and a <sup>superscript </sup> a <del>strikeover</del> an <em>emphasis </em> a <strong>double one </strong> and the <em><strong>bold italic</strong></em>.

 

* Then the

 

** third

*** hello

**** fifth

 

***** sixst

 

finally finished

';

compare_two_long_strings($html, $expected, "General overview");

$html = '<code class="inline"><a class="l_k" href="http://perldoc.perl.org/functions/print.html">print</a></code> function in Perl';

is(html_to_muse($html),
   '<code>[[http://perldoc.perl.org/functions/print.html][print]]</code>' . 
   ' function in Perl', "testing <a>");

# some things from libcom:

$html = '<p>I&#039;d been in town for about 24 hours when I got to the anarchist bookfair, and one of the first people I saw there was a man who sexually assaulted a friend of mine. At this point I realised that  discussions about safer spaces, sexual violence, and our response to these issues as a community aren&#039;t something I am going to be able to avoid any time soon. The shitty reality is that sexual assault, as well as sexist, racist, homophobic, transphobic, queerphobic and other socially conditioned, oppressive bullshit (intentional or not) is not unusual. As communists, we can all agree that this kind of behaviour is A Bad Thing, <a class="see-footnote" id="footnoteref1_n85wy2g" title="although some people may wish to defend their right to make racist, sexist, homophobic etc jokes, because we all know they&#039;re a communist and don&#039;t really mean it. Luckily, Polite Ire has taken the trouble to explain exactly why that&#039;s bullshit." href="#footnote1_n85wy2g">1</a> but the disagreement comes when we&#039;re talking about what we do about it.</p>';

$expected = "\n\nI'd been in town for about 24 hours when I got to the anarchist bookfair, and one of the first people I saw there was a man who sexually assaulted a friend of mine. At this point I realised that discussions about safer spaces, sexual violence, and our response to these issues as a community aren't something I am going to be able to avoid any time soon. The shitty reality is that sexual assault, as well as sexist, racist, homophobic, transphobic, queerphobic and other socially conditioned, oppressive bullshit (intentional or not) is not unusual. As communists, we can all agree that this kind of behaviour is A Bad Thing, [1] but the disagreement comes when we're talking about what we do about it.\n\n";

compare_two_long_strings($html, $expected, "links");

compare_two_long_strings("<html> <head><title>hello</title><body> <em> <strong> Hello </strong></em> </body></html>",
			 "hello <em><strong>Hello</strong></em>",
			 "testing simple random tags");


$html =<< 'EOF';
<blockquote class="bb-quote-body">Hi [REDACTED].<br />
I am writing to you on behalf of the 2012 NYC Anarchist Book fair Safe(r) Space Group to let you know that a request has been made that you not attend this year. The policy at the event, posted at http://www.anarchistbookfair.net/saferspace, is in place to create a supportive, non-threatening environment for all. This means that anyone may be asked to not attend. <span style="font-style:italic"><span style="font-weight:bold">No blame is placed, no decision is made</span></span>, we simply ask that you not attend to prevent anyone from feeling unsafe.<br />
We understand that being asked not to attend is not easy, and we don’t take it lightly. You may not know why you are being asked not to attend or who all is requesting this, or you may feel the situation is totally unfair. Our goal is not to decide right or wrong but to maintain safety at the fair. Some situations are gray and sometimes based on simple misunderstandings, but regardless of the reasons, no matter what your defense, we still ask that you not attend this years book fair. Not attending is not an admission of guilt. In fact, you not attending is a statement that you respect everyone’s safety at the fair and are taking a positive step to uphold that principle.<br />
<span style="font-style:italic"><span style="font-weight:bold">We also understand your need to know why you are being asked not to attend. However, the book fair is not the place to resolve conflict.</span></span> Please, do not approach anyone at the fair who you think is responsible for the request that you not attend, or anyone that you think may have made this request before the fair. This violates our commitment to keeping everyone safe.<br />
We realize that this email is formal. We chose to email you because we want to remain as neutral as possible in this position and situation, as well as to give you the space in which to process this request in whatever way is most comfortable and safe.<br />
<span style="font-style:italic"><span style="font-weight:bold">If you have any questions please don&#039;t hesitate to contact me.</span></span> Again, do not contact anyone without their consent, especially any survivors. <span style="font-style:italic"><span style="font-weight:bold">You can field all questions through me or I can put you in contact with other safer space members</span></span>.<br />
Thanks for helping us keep it safe,<br />
[REDACTED]/ NYC Anarchist Bookfair Safer Space Team</blockquote>
</div>
EOF

$expected =<< 'EOF';

<quote>
Hi [REDACTED].

I am writing to you on behalf of the 2012 NYC Anarchist Book fair Safe(r) Space Group to let you know that a request has been made that you not attend this year. The policy at the event, posted at http://www.anarchistbookfair.net/saferspace, is in place to create a supportive, non-threatening environment for all. This means that anyone may be asked to not attend. <em><strong>No blame is placed, no decision is made</strong></em>, we simply ask that you not attend to prevent anyone from feeling unsafe.

We understand that being asked not to attend is not easy, and we don’t take it lightly. You may not know why you are being asked not to attend or who all is requesting this, or you may feel the situation is totally unfair. Our goal is not to decide right or wrong but to maintain safety at the fair. Some situations are gray and sometimes based on simple misunderstandings, but regardless of the reasons, no matter what your defense, we still ask that you not attend this years book fair. Not attending is not an admission of guilt. In fact, you not attending is a statement that you respect everyone’s safety at the fair and are taking a positive step to uphold that principle.

<em><strong>We also understand your need to know why you are being asked not to attend. However, the book fair is not the place to resolve conflict.</strong></em> Please, do not approach anyone at the fair who you think is responsible for the request that you not attend, or anyone that you think may have made this request before the fair. This violates our commitment to keeping everyone safe.

We realize that this email is formal. We chose to email you because we want to remain as neutral as possible in this position and situation, as well as to give you the space in which to process this request in whatever way is most comfortable and safe.

<em><strong>If you have any questions please don't hesitate to contact me.</strong></em> Again, do not contact anyone without their consent, especially any survivors. <em><strong>You can field all questions through me or I can put you in contact with other safer space members</strong></em>.

Thanks for helping us keep it safe,

[REDACTED]/ NYC Anarchist Bookfair Safer Space Team
</quote>

EOF

compare_two_long_strings($html, $expected, "<span thing>");

compare_two_long_strings("<sup>1</sup>", "<sup>1</sup>", "sup");

compare_two_long_strings(
			 "<i> <b> 1 </b> </i> <i> <b> 1 </b> </i>",
			 "<em><strong>1</strong></em>" . " " .
			 "<em><strong>1</strong></em>",
			"i and b");


$html = <<'HTML';

<ul class="bb-list" style="list-style-type:circle;">
<li>Doesn&#039;t detail allegations and could be confusing for the recipient</li>
<li>Doesn&#039;t give the recipient a right to reply or provide their side of the story</li>
<li>By providing anonymity to the person who requested the recipient be asked not to attend the bookfair, this letter paves the way for abuses of power and a slew of false allegations.</li>
</ul>
<p>I don&#039;t think the letter is without fault, nor do I think that people objecting to it are apologists for sexual assault by default, and I&#039;d like to make that quite clear. I decided to go and chat to the safer spaces team at the bookfair. They weren&#039;t some shadowy clique plotting people&#039;s downfall in a backroom somewhere, I met a few women sat at the very entrance to the main room, with a clear sign indicating who they were, and arm bands making them easily identifiable. They had formed a group called <a href="http://supportny.org/about/" class="bb-url">Support New York</a> who are<br />
<div class="bb-quote">Quote:<br />
<blockquote class="bb-quote-body">dedicated to healing the effects of sexual assault and abuse.  Our aim is to meet the needs of the survivor, to hold accountable those who  have perpetrated harm, and to maintain a larger dialogue within the community about consent, mutual aid, and our society’s narrow views of abuse. We came together in order to create our own safe(r) space and provide support for people of all genders, races, ages and orientations, separate from the police and prison systems that perpetuate these abuses</blockquote></div></p>

HTML

$expected =<< 'MUSE';


 - Doesn't detail allegations and could be confusing for the recipient

 - Doesn't give the recipient a right to reply or provide their side of the story

 - By providing anonymity to the person who requested the recipient be asked not to attend the bookfair, this letter paves the way for abuses of power and a slew of false allegations.

I don't think the letter is without fault, nor do I think that people objecting to it are apologists for sexual assault by default, and I'd like to make that quite clear. I decided to go and chat to the safer spaces team at the bookfair. They weren't some shadowy clique plotting people's downfall in a backroom somewhere, I met a few women sat at the very entrance to the main room, with a clear sign indicating who they were, and arm bands making them easily identifiable. They had formed a group called [[http://supportny.org/about/][Support New York]] who are

Quote:

<quote>
dedicated to healing the effects of sexual assault and abuse. Our aim is to meet the needs of the survivor, to hold accountable those who have perpetrated harm, and to maintain a larger dialogue within the community about consent, mutual aid, and our society’s narrow views of abuse. We came together in order to create our own safe(r) space and provide support for people of all genders, races, ages and orientations, separate from the police and prison systems that perpetuate these abuses
</quote>

MUSE

compare_two_long_strings($html, $expected, "lists and urls");

$html = "Hadsonovim <i>Zelenim dvorima[[#_ftn10][<b>[10]</b>]]</i>";
$expected = "Hadsonovim <em>Zelenim dvorima[10]</em>";

compare_two_long_strings($html, $expected, "Footnote");
			 
$html = "<div>Coperto di insulti e non sapendo che pesci pigliare, da parte sua il curatore ha barbugliato qualcosa sulla differenza fra vecchia dittatura (brutta e cattiva come i suoi generali) e nuova democrazia (bella e buona come i suoi finanziamenti). Oppure sul fatto che tutti i libri sull'Argentina ricevono contributi dallo Stato, e quindi... </div>
<div>Tutto fiato sprecato. Non c'è stato nulla da fare, i toni si sono alzati ed i prodotti culturali esposti per essere venduti sono volati in aria. Nemmeno il tentativo di mettere da parte la merce stampata e proseguire limitandosi a fare una discussione sull'anarchico abruzzese ha funzionato, giacché il buon Prunetti voleva continuare a tenere banco. Zittito nuovamente, si stava consolando firmando autografi.</div>";

$expected =<< 'MUSE';


Coperto di insulti e non sapendo che pesci pigliare, da parte sua il curatore ha barbugliato qualcosa sulla differenza fra vecchia dittatura (brutta e cattiva come i suoi generali) e nuova democrazia (bella e buona come i suoi finanziamenti). Oppure sul fatto che tutti i libri sull'Argentina ricevono contributi dallo Stato, e quindi...

Tutto fiato sprecato. Non c'è stato nulla da fare, i toni si sono alzati ed i prodotti culturali esposti per essere venduti sono volati in aria. Nemmeno il tentativo di mettere da parte la merce stampata e proseguire limitandosi a fare una discussione sull'anarchico abruzzese ha funzionato, giacché il buon Prunetti voleva continuare a tenere banco. Zittito nuovamente, si stava consolando firmando autografi.

MUSE

compare_two_long_strings($html, $expected, "div test");

$html = "<div>Dobbiamo imparare a mordere, e mordere a fondo!</div><div>\x{a0}</div><div style=\"text-align: right; \">[<em>The Alarm</em>, Chicago, Vol. 1, n. 3 del dicembre 1915]</div><div>\x{a0}</div>";

$expected =<< 'MUSE';


Dobbiamo imparare a mordere, e mordere a fondo!

 

<right>
[<em>The Alarm</em>, Chicago, Vol. 1, n. 3 del dicembre 1915]
</right>

 

MUSE

compare_two_long_strings($html, $expected, "right align");

$html = '<div style="text-align: right; "><em>ma poiché per il momento tutte le strade ci sono precluse, </em></div>
<div style="text-align: right; "><em>dipende da noi trovare una via d\'uscita proprio a partire da qui, </em></div>
<div style="text-align: center; "><em>rifiutando in ogni occasione e su tutti i piani di cedere»</em></div>
<div> </div>
<div style="text-align: center; "><em>rifiutando in ogni occasione e su tutti i piani di cedere»</em></div>
<div> </div>';

$expected =<< 'MUSE';


<right>
<em>ma poiché per il momento tutte le strade ci sono precluse,</em>
</right>

<right>
<em>dipende da noi trovare una via d'uscita proprio a partire da qui,</em>
</right>

<center>
<em>rifiutando in ogni occasione e su tutti i piani di cedere»</em>
</center>

<center>
<em>rifiutando in ogni occasione e su tutti i piani di cedere»</em>
</center>

MUSE

compare_two_long_strings($html, $expected, "right and center");

$html = '<P ALIGN="RIGHT">[<em>La Rivolta</em>, Pistoia, anno I, n. 8 del 19 febbraio 1910]</P>';

$expected =<< 'MUSE';


<right>
[<em>La Rivolta</em>, Pistoia, anno I, n. 8 del 19 febbraio 1910]
</right>

MUSE

compare_two_long_strings($html, $expected, "right with align prop");


# print html_to_muse($html);


# showlines(html_to_muse($expected));



sub compare_two_long_strings {
  my ($xhtml, $xexpected, $testname, $debug) = @_;
  my @array_got = split /(\n)/,
    html_to_muse($xhtml, $debug);
  my @array_exp = split /(\n)/, $xexpected;
  is_deeply(\@array_got, \@array_exp, $testname);
}


sub showlines {
  my $expected = shift;
  my $count = 0;
  foreach my $l (split /(\n)/, $expected) {
    print "[$count] " . $l . "\n";
    $count++;
  }
}

