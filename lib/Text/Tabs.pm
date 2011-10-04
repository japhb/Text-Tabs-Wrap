module Text::Tabs;

sub expand($text, :$tabstop = 8) returns Str is export {
    $text.split("\n").map({
        # Split the line up into non-\t and \t, go through and replace \t with their *visual*
        # space equivalent - the end of the tab should be rounded down to the nearest tabstop
        my $pos = 0;
        $^line.split(/\t/, :all).map({
            my $out = $^in ~~ Match ?? ' ' x $tabstop - ($pos mod $tabstop)
                                    !! $^in;
            $pos += $out.chars;
            $out;
        }).join
    }).join("\n");
}

# Expand all tabs in text, then collapse it
sub unexpand($text, :$tabstop = 8) returns Str is export {
    # .lines will eat a trailing \n, so don't use it here
    $text.split("\n").map({
        # Break the text into tabstop-sized chunks, and collapse trailing whitespace on those
        # into \t chars. We don't do that for the last bit because it might not be a full
        # $tabstop chars long.
        my $expanded = expand($^line);
        my @chunks = (0, $tabstop ...^ * >= $expanded.chars).map({ $expanded.substr($_, $tabstop) });
        my $tail = pop(@chunks) // '';

        @chunks».subst(/\s\s+$/, "\t").join
            ~ ($tail eq ' ' x $tabstop ?? "\t" !! $tail);
    }).join("\n");
}

# vim: set ft=perl6 :
