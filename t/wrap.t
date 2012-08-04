#!/usr/bin/env perl6
use v6;
use Test;
use Test::Corpus;
use Text::Wrap;

Test::Corpus::run-tests(
    sub ($in, $out, $filename) {
        my @in = $in.lines;
        my @out = $out.lines;

        is  wrap('   ', ' ', @in.join("\n"), word-break => '\s'),
            @out.join("\n"),
            "$filename - wrap.t";
    }
);
