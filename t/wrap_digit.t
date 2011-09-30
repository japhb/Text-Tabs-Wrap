#!/usr/bin/env perl6
use v6;
use Test;
use TestFiles;
use Text::Wrap;

TestFiles::run-tests(
    sub ($in, $out, $filename) {
        my @in = $in.lines;
        my @out = $out.lines;

        is  wrap('   ', ' ', @in.join("\n"), break => rx{\d}),
            @out.join("\n"),
            "$filename - wrap_digit.t";
    }
);
