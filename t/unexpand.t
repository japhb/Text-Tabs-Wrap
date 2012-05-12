#!/usr/bin/env perl6
use v6;
use Test;
use lib '.';
use TestFiles;
use Text::Tabs;

TestFiles::run-tests(sub ($in, $out, $filename) {
    is unexpand($in.slurp), $out.slurp, $filename;
});
