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
         Regex    :$word-break  = rx/\s/,
         *@texts) is export {

    my %sizes = compute-sizes(:$lead-indent, :$body-indent, :$tabstop, :$columns);
    my Str $text = expand(:$tabstop, trailing-space-join(@texts));

    my Int $lines-done          = 0;    # Flag to control first-line/rest-of-text stuff
    my Int $text-width          = %sizes<lead>; # Target width of current line (minus indent)
    my Str $indent              = $lead-indent; # String to prefix current line with
    my Str $out                 = '';   # Output buffer
    my Str $output-delimiter    = '';   # Usually \n
    my Str $remainder           = '';   # Buffer to catch trailing text
    my Numeric $pos             = 0;    # Input regex cursor

    my Regex $line-break = rx/ <$word-break>|\n|$ /;
    my Regex $line-regex = do given $long-lines {
        # TODO: Rakudo is broken on all of these, doesn't support /x ** {y}/ (2011-10-20)
        when 'break' { rx/ (\N ** {0..$text-width - 1}) (<$line-break>)
                         | (\N ** {$text-width}) (<$line-break>)? / }
        when 'keep'  { rx/ (\N*?) (<$line-break>) / }
        when 'error' { rx/ (\N ** {0..$text-width - 1}) (<$line-break>) / }
    };

    sub unexpand-if { $unexpand ?? unexpand(:$tabstop, $^a) !! $^a };

    while $pos <= $text.chars and $text !~~ m:p($pos)/\s*$/ {
        # Reminder to self: .match only returns a match, it doesn't implicitly set $/
        my $line = $text.match($line-regex, :$pos);
        if $line {
            $out ~= unexpand-if($output-delimiter ~ $indent ~ $line[0]);
            $pos = $line.to + 1;
            $remainder = $line[1] ?? $line[1].Str !! $separator2 // $separator;
        }
        elsif $long-lines eq 'error' {
            die "Couldn't wrap text to requested text width '%sizes<wrap-to>'";
        }
        elsif %sizes<wrap-to> < 2 {
            warn "Could not wrap text to text width '%sizes<wrap-to>', retrying with 2";
            return wrap($lead-indent, $body-indent, :columns(2), @texts);
        }
        else {
            # If we get here, something went wrong
            die "Could not wrap text to text width '%sizes<wrap-to>' and unable to recover";
        }

        if $lines-done == 1 {
            $text-width = %sizes<body>;
            $indent = $body-indent;
            $output-delimiter =
                $separator2 ?? $remainder eq "\n" ?? $remainder
                                                  !! $separator2
                            !! $separator;
        }

        $lines-done++;
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
