module Text::Wrap:auth<github:flussence>;
use Text::Tabs;

subset Nat of Int where * >= 0;
subset LineWrap of Str where any(<break keep error>);

sub wrap(Str $lead-indent,
         Str $body-indent,
         Nat :$tabstop      = 8,
         Nat :$columns      = 76,
         Str :$separator    = "\n",
         Str :$separator2   = Str,
         Bool :$unexpand    = True,
         LineWrap :$long-lines  = 'break',
         Regex    :$word-break  = rx{\s},
         *@texts) is export {

    my Str $text = expand(:$tabstop, trailing-space-join(@texts));

    my (Nat $intrinsic-width, Nat $lead-width, Nat $body-width) =
        compute-sizes($lead-indent, $body-indent, $tabstop, $columns);

    my Int $section-state       = 0; # Flag to control first-line/rest-of-text var swap
    my Nat $current-width       = $lead-width; # Target width of current line (minus indent)
    my Str $current-indent      = $lead-indent; # String to prefix current line with
    my Str $current-eol         = '';   # Usually \n

    my Str $out                 = '';   # Output buffer
    my Str $remainder           = '';   # Buffer to catch trailing text
    my Numeric $pos             = 0;    # Input regex cursor

    sub unexpand-if { $unexpand ?? unexpand(:$tabstop, $^a) !! $^a };

    while $pos <= $text.chars and $text !~~ m:p($pos)/\s*$/ {
        # XXX "NEXT" isn't implemented in Niecza, and "START" was changed to "once" recently in the
        # spec and that's now NYI in both R and N.
        if $section-state == 1 {
            $current-width = $body-width;
            $current-indent = $body-indent;
            $current-eol =
                $separator2 ?? $remainder eq "\n" ?? $remainder
                                                  !! $separator2
                            !! $separator;
        }
        if $section-state < 2 {
            $section-state++;
        }

        # Grab as many whole words as possible that'll fit in current line width
        if $text ~~ m:p($pos)/(\N*) <?{ $0.chars ~~ 0..$current-width }> (<$word-break>|\n+|$)/ {

            $pos = $0.to + 1;
            $remainder = $1.Str;
            $out ~= unexpand-if($current-eol ~ $current-indent ~ $0);

            next;
        }

        # If that fails, the behaviour depends on the setting of $long-lines:
        given $long-lines {
            # Hard-wrap at the specified width
            when 'break' {
                if $text ~~ m:p($pos)/(\N*) <?{ $0.chars ~~ 0..$current-width }>/ {
                    $pos = $/.to;
                    $remainder = ($separator2 or $separator);
                    $out ~= unexpand-if($current-eol ~ $current-indent ~ $0);

                    next;
                }
            }

            # Grab up to the next word-break, line-break or end of text regardless of length
            when 'keep' {
                if $text ~~ m:p($pos)/(\N*?) (<$word-break>|\n+|$)/ {
                    $pos = $0.to;
                    $remainder = $1.Str;
                    $out ~= unexpand-if($current-eol ~ $current-indent ~ $0);

                    next;
                }
            }

            # Throw an exception if asked to do so
            when 'error' {
                die "Couldn't wrap text to requested text width '$intrinsic-width'";
            }
        }

        if $intrinsic-width < 2 {
            # attempt to recover by expanding it
            warn "Could not wrap text to text width '$intrinsic-width', retrying with 2";
            return wrap($lead-indent, $body-indent, :columns(2), @texts);
        }
        else {
            # If we get here, something went wrong
            die "Could not wrap text to text width '$intrinsic-width' and unable to recover";
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

sub compute-sizes(Str $lead-indent, Str $body-indent, Nat $tabstop, Nat $columns) is pure {
    # The first line is allowed to have zero characters if the indent consumes all available space,
    # in which case text starts on the next line instead.
    my Nat %min-widths = ( lead => 0, body => 1 );
    my Nat %margins = (
        lead => expand(:$tabstop, $lead-indent).chars,
        body => expand(:$tabstop, $body-indent).chars,
    );

    # If either margin is larger than $columns, emit a warning and use the largest number
    my Nat $intrinsic-width = [max] $columns, %margins.values.max;
    if $columns < $intrinsic-width {
        warn "Increasing columns from $columns to $intrinsic-width to contain requested indent";
    }

    # Compute available space left for text content
    my Nat %widths =
        ($_ => ([max] %min-widths{$_}, $intrinsic-width - %margins{$_})
            for <lead body>);

    # 1 char is reserved for "\n", but remove it if the constraints imposed would already cause
    # every line to overflow.
    # NOTE "all(" causes an error in both R and N here, and ()s are necessary for precedence.
    %widths»-- if all (%widths{$_} > %min-widths{$_} for <lead body>);

    return $intrinsic-width, %widths<lead body>;
}

# vim: set ft=perl6 :
