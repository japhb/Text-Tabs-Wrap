module Text::Wrap;
use Text::Tabs;

subset LineWrap of Str where any(<break keep error>);

sub wrap(Str $lead-indent,
         Str $body-indent,
         Int :$tabstop      = 8,
         Int :$columns      = 76,
         Str :$separator    = "\n",
         Str :$separator2   = Str,
         Bool :$unexpand    = True,
         LineWrap :$long-lines  = 'break',
         Regex    :$word-break  = rx{\s},
         *@texts) is export {

    my Str $text = expand(:$tabstop, trailing-space-join(@texts));

    my %sizes = compute-sizes(:$lead-indent, :$body-indent, :$tabstop, :$columns);

    my Int $lines-done          = 0;    # Flag to control first-line/rest-of-text stuff
    my Int $text-width          = %sizes<lead>; # Target width of current line (minus indent)
    my Str $indent              = $lead-indent; # String to prefix current line with
    my Str $out                 = '';   # Output buffer
    my Str $output-delimiter    = '';   # Usually \n
    my Str $remainder           = '';   # Buffer to catch trailing text
    my Numeric $pos             = 0;    # Input regex cursor

    sub unexpand-if { $unexpand ?? unexpand(:$tabstop, $^a) !! $^a };

    while $pos <= $text.chars and $text !~~ m:p($pos)/\s*$/ {
        if $lines-done == 1 {
            $text-width = %sizes<body>;
            $indent = $body-indent;
            $output-delimiter =
                $separator2 ?? $remainder eq "\n" ?? $remainder
                                                  !! $separator2
                            !! $separator;
        }

        $lines-done++;

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
            when 'break' {
                if $text ~~ m:p($pos)/(\N ** {0..$text-width})/ {
                    $pos = $/.to;
                    $remainder = ($separator2 or $separator);
                    $out ~= unexpand-if($output-delimiter ~ $indent ~ $0);

                    next;
                }
            }

            # Grab up to the next word-break, line-break or end of text regardless of length
            when 'keep' {
                if $text ~~ m:p($pos)/(\N*?) (<$word-break>|\n+|$)/ {
                    $pos = $0.to;
                    $remainder = $1.Str;
                    $out ~= unexpand-if($output-delimiter ~ $indent ~ $0);

                    next;
                }
            }

            # Throw an exception if asked to do so
            when 'error' {
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

# Joins an array of strings with space between, preferring to use existing trailing spaces.
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

# vim: set ft=perl6 :
