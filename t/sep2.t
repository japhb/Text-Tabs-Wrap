#!/usr/bin/env perl6
use v6;
use Test;
use Test::Corpus;
use Text::Wrap;

Test::Corpus::run-tests(
    sub ($in, $out, $filename) {
        my Str $in-str = $in.slurp;
        my Str $out-str = $out.slurp;
        my &wrapper = &wrap.assuming('   ', ' ', :separator2('='));

        is  &wrapper($in-str),
            $out-str,
            "$filename - sep.t (as one string)";

        # append "\n" to all lines but the last
        my @in = $in-str.split(/\n/);
        @in[0 ..^ @in-1] >>~=>> "\n";

        is  &wrapper(@in),
            $out-str,
            "$filename - sep.t (array of lines)";
    },
    :tests-per-block(2)
);
