#!/usr/bin/env perl6
use v6;
use Test;
use lib '.';
use Test::Corpus;
use Text::Wrap;

run-tests(
    sub ($in, $out, $filename) {
        my Str $in-str = $in.slurp;
        my Str $out-str = $out.slurp;
        my &wrapper = &wrap.assuming(q{ } x 3, q{ }, :separator('='));

        is  &wrapper($in-str),
            $out-str,
            "$filename - sep.t (as one string)";

        # append "\n" to all lines but the last
        my @in = $in-str.split(/\n/);
        @in[^@in.end] »~=» "\n";

        is  &wrapper(@in),
            $out-str,
            "$filename - sep.t (array of lines)";
    },
    :tests-per-block(2)
);
