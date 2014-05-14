# Text-Tabs-Wrap

Text-Tabs-Wrap is a port of the Perl 5 Text-Tabs+Wrap distribution to Perl 6.
The API is slightly different because we have all the Perl 6 bells and whistles,
but the module should behave the same (i.e. the original testcases are still
used, loosely paraphrased into Perl6ish code, and should pass cleanly).

Text::Tabs provides the `expand` and `unexpand` functions, which perform the
same job that the Unix `expand(1)` and `unexpand(1)` commands do: adding or
removing tabs from a document.

Text::Wrap gives you `wrap` and `fill` functions. `wrap` will break up long
lines; it doesn't join short lines together. `fill` reformats entire blocks of
text, similar to vi's `gq` command.

## Current status (2014-05-13)

Has been tested on a recent Rakudo (`2014.04-242-g1984fdfe6029`) running on
MoarVM, with known test failures (3/3 in `37000.t`, 6/24 in `sep2.t` and 1/2 in
`wrap_separator2.t`).

The code tries hard to be spec-compliant and not coded to any particular
implementation, but there are a few ugly Rakudo workarounds in there.

## Installing

Installing via [Panda][gh-panda] is recommended, the package name is
"Text-Tabs-Wrap".

If you prefer to do things manually instead, run the test suite like so:

    prove -e 'perl6 -I lib'

## Credits

This code was originally derived from Perl 5's [Text-Tabs+Wrap][ttr-perl5],
the initial port to Perl 6 was done by [Takadonet][gh-takadonet], and it's been
maintained by [flussence][gh-flussence] since then.

[gh-flussence]: //github.com/flussence
[gh-panda]:     //github.com/tadzik/panda/
[gh-takadonet]: //github.com/Takadonet
[ttr-perl5]:    //metacpan.org/release/MUIR/Text-Tabs+Wrap-2013.0523

<!-- vim: set tw=80 -->
