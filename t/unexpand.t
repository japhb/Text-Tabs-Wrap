#!/usr/bin/env perl6
use v6;
use Test;
use Test::Corpus;
use Text::Tabs;

Test::Corpus::run-tests(
    Test::Corpus::default-test(&unexpand);
);
