#!/usr/bin/env perl6
use v6;
use Test;
use Test::Corpus;
use Text::Tabs;

run-tests(simple-test(&unexpand));
