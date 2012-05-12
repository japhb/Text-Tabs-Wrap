#!/usr/bin/env perl6
use v6;
use Test;
use lib '.';
use TestFiles;
use Text::Wrap;

TestFiles::run-tests(sub ($in, $out, $filename) {
    is fill(' ' x 4, ' ', $in.slurp), $out.slurp, $filename;
});
