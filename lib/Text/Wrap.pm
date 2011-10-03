module Text::Wrap;
use Text::Tabs;

=begin pod

=head1 NAME

Text::Wrap -- line wrapping to form simple paragraphs

=head1 SYNOPSIS

=begin code
    use Text::Wrap;

    $initial_tab = "\t";    # Tab before first line
    $subsequent_tab = "";   # All other lines flush left

    $lines = wrap($initial_tab, $subsequent_tab, @text);
    @paragraphs = fill($initial_tab, $subsequent_tab, @text);

    $Text::Wrap::huge = 'wrap';
    $Text::Wrap::columns = %*ENV<COLUMNS> // 80;
    print wrap('', '', @text);  # Format text for terminal output
=end code

=head1 DESCRIPTION

Text::Wrap provides two functions for wrapping text:

C<wrap()> is a very simple paragraph formatter. It formats a single paragraph at a time by breaking
lines at word boundaries. Indentation is controlled for the first line and all subsequent lines
independently, via C<$lead-indent> and C<$body-indent>.

C<fill()> is a simple multi-paragraph formatter. It breaks text into paragraphs on blank-line
boundaries, each paragraph is passed to C<wrap()> and the result is joined back together.

Both C<wrap()> and C<fill()> return a single string.

=end pod

enum Overflow <break keep error>;

sub wrap(Str $lead-indent,
         Str $body-indent,
         Int :$tabstop          = 8,
         Int :$columns          = 76,
         Str :$separator        = "\n",
         Str :$separator2       = Str,
         Bool :$unexpand        = True,
         Regex :$word-break     = rx{\s},
         Overflow :$long-lines  = Overflow::break,
         *@texts) is export {

    my Str $text = expand(:$tabstop, trailing-space-join(@texts));

    my %sizes = compute-sizes(:$lead-indent, :$body-indent, :$tabstop, :$columns);

    my Str $out                 = '';   # Output buffer
    my Str $output-delimiter    = '';   # Usually \n
    my Str $remainder           = '';   # Buffer to catch trailing text
    my Bool $first-line         = True; # Flag to say whether we're doing first-line width or not
    my Numeric $pos             = 0;    # Input regex cursor

    sub unexpand-if { $unexpand ?? unexpand(:$tabstop, $^a) !! $^a };

    while $pos <= $text.chars and $text !~~ m:p($pos)/\s*$/ {
        my $text-width  = $first-line ?? %sizes<lead> !! %sizes<body>;
        my $indent      = $first-line ?? $lead-indent !! $body-indent;
        $first-line = False;

        # Grab as many whole words as possible that'll fit in current line width
        if $text ~~ m:p($pos)/(\N ** {0..$text-width}) (<$word-break>|\n+|$)/ {

            $pos = $0.to + 1;
            $remainder = $1.Str;
            $out ~= unexpand-if($output-delimiter ~ $indent ~ $0);

            next;
        }

        # If that fails, the behaviour depends on the setting of $long-lines:
        given $long-lines {
            # Hard-wrap at the specified width
            when 'wrap' {
                if $text ~~ m:p($pos)/(\N ** {0..$text-width})/ {
                    $pos = $/.to;
                    $remainder = ($separator2 or $separator);
                    $out ~= unexpand-if($output-delimiter ~ $indent ~ $0);

                    next;
                }
            }

            # Grab up to the next word-break, line-break or end of text regardless of length
            when 'overflow' {
                if $text ~~ m:p($pos)/(\N*?) (<$word-break>|\n+|$)/ {
                    $pos = $0.to;
                    $remainder = $1.Str;
                    $out ~= unexpand-if($output-delimiter ~ $indent ~ $0);

                    next;
                }
            }

            # Throw an exception if asked to do so
            when 'die' {
                die "Couldn't wrap text to requested text width '%sizes<wrap-to>'";
            }
        }

        if %sizes<wrap-to> < 2 {
            # attempt to recover by expanding it
            warn "Could not wrap text to text width '%sizes<wrap-to>', retrying with 2";
            return wrap($lead-indent, $body-indent, :columns(2), @texts);
        }
        else {
            # If we get here, something went wrong
            die "Could not wrap text to text width '%sizes<wrap-to>' and unable to recover";
        }

        # FIXME: neither niecza nor rakudo support NEXT. Rewrite this to not need it
        NEXT {
            $output-delimiter =
                $separator2 ?? $remainder eq "\n" ?? $remainder
                                                  !! $separator2
                            !! $separator;
        }
    }

    return $out ~ $remainder;
}

sub fill(Str $lead-indent,
         Str $body-indent,
         *@raw,
         *%wrap-opts) is export {

    @raw.join("\n")\
        .split(/\n\s+/)\
        .map({
            wrap($lead-indent, $body-indent, $^paragraph.split(/\s+/).join(' '), %wrap-opts)
        })\
        .join($lead-indent eq $body-indent ?? "\n\n" !! "\n");
}

#= Joins an array of strings with space between, preferring to use existing trailing spaces.
sub trailing-space-join(*@texts) {
    my Str $tail = pop(@texts);
    return @texts.map({ /\s+$/ ?? $_ !! $_ ~ q{ } }).join ~ $tail;
}

sub compute-sizes(:$lead-indent, :$body-indent, :$tabstop, :$columns) {
    # The first line is allowed to have zero characters if the indent consumes all available space,
    # in which case text starts on the next line instead.
    my $lead = {
        margin      => expand(:$tabstop, $lead-indent).chars,
        min-width   => 0
    };
    my $body = {
        margin      => expand(:$tabstop, $body-indent).chars,
        min-width   => 1
    };

    # If either margin is larger than $columns, emit a warning
    # XXX niecza workaround: square brackets get the entire list all at once
    my $content-width = [max] $columns, ([max] $lead<margin>, $body<margin>);
    if $columns < $content-width {
        warn "Increasing column width from $columns to $content-width to contain requested indent";
    }

    for $lead, $body -> $_ {
        $_<content> = [max] $_<min-width>, $content-width - $_<margin>;
    };

    # 1 character is reserved for "\n", except if it would leave no space for text otherwise.
    if $lead<content> > $lead<min-width> and $body<content> > $body<min-width> {
        --$lead<content>;
        --$body<content>;
    }

    return {
        wrap-to => $content-width,
        lead    => $lead<content>,
        body    => $body<content>,
    }
}

=begin pod

=head1 OPTIONS

Text::Wrap has a number of named parameters that can be passed to C<wrap()> or C<fill()>. The
defaults are intended to be reasonably sane, and compatible with the Perl 5 version of this module.

=begin item
C<:$columns> (default: C<76>)

This controls the maximum width of a line, including indent. The actual text width will normally be
1 less than this as C<wrap()> reserves one character for the C<\n> ending each line, except when
C<$columns> is set so small there'd be no room for normal text on a line. If this is set smaller
than a line's indent + 1 character of text, a warning is issued and this value is overridden.
=end item

=begin item
C<:$word-break> (default: C<rx{\s}>)

This defines the logical word separator. Set this to any valid regex, such as e.g. C<rx/\s|':'/> to
break before spaces/colons or C<rx/\s|"'"/> to break before spaces/apostrophes. The default is
simply to split on whitespace. (This means, among other things, that trailing punctuation such as
full stops or commas stay with the word they are "attached" to.) Setting C<$word-break> to a regular
expression that doesn't eat any characters (perhaps just a forward look-ahead assertion) will likely
cause bad things to happen.
=end item

=begin item
C<:$unexpand> (default: C<Bool::True>), C<:$tabstop> (default: C<8>)

C<wrap()> starts its work by expanding all tabs in its input into spaces. The last thing it does is
to turn spaces back into tabs. If you do not want tabs in the output, set C<$unexpand> to a false
value. Likewise if you do not want to use 8-character tabstops, pass a different numeric
C<:$tabstop> value to C<wrap()>.
=end item

=begin item
C<:$separator> (default: C<"\n">), C<:$separator2> (default: not set)

=for comment
N.B. The logic of the separator vars is horribly convoluted. This part of the module may change.

C<$Text::Wrap::separator> defines the logical line delimiter for output. C<$Text::Wrap::separator2>
is similar, but when set it overrides the value of C<$separator> and existing newline characters in
the input are preserved.
=end item

=begin item
C<:$long-lines> (default: C<Overflow::break>)

This defines the behaviour when encountering an oversized "word" (anything that can't be normally
broken before C<$columns> characters on the line). 3 values are accepted:

=defn C<Overflow::break>
C<wrap()> inserts a line break in the word at column C<$columns>.

=defn C<Overflow::keep>
Words longer than C<$columns> are put on a line by themselves, but otherwise left unwrapped.

=defn C<Overflow::error>
C<wrap()> dies upon finding a word it can't fit into the space allocated.
=end item

=head1 EXAMPLES

C<wrap()> goes well with heredocs:

  print wrap("\t","",q:to<END>);
  This is a bit of text that forms
  a normal book-style indented paragraph
  END
  # "   This is a bit of text that forms
  # a normal book-style indented paragraph
  # "

You can easily make a wrap wrapper with your own defaults using C<.assuming>:

  my &wrapper = &wrap.assuming('', '', :columns(20), :separator('|'));
  print &wrapper('This is a bit of text that forms a normal book-style paragraph');
  # "This is a bit of|text that forms a|normal book-style|paragraph"

=head1 AUTHORS

Original Perl 5 code:
David Muir Sharnoff <muir@idiom.org> with help from Tim Pierce and
many many others.  Copyright (C) 1996-2009 David Muir Sharnoff.

Perl 6 rewrite:
Copyright © 2010-2011 Philip Mabon (L<https://github.com/Takadonet>)
Copyright © 2011 Anthony Parsons (L<https://github.com/flussence>)

=head1 LICENSE

This software is provided 'as-is', without any express or implied warranty.  In no event will the
author(s) be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial
applications, and to alter it and redistribute it freely, subject to the following restrictions:

=item 1.
The origin of this software must not be misrepresented; you must not claim that you wrote the
original software. If you use this software in a product, an acknowledgment in the product
documentation would be appreciated but is not required.

=item 2.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the
original software.

=item 3.
This notice may not be removed or altered from any source distribution.

=end pod

# vim: set ft=perl6 :
