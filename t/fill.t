#!/usr/bin/env perl6
use v6;
use Test;
use Test::Corpus;
use Text::Wrap;

Test::Corpus::run-tests(
    Test::Corpus::default-test(
        &fill.assuming(q{ } x 4, q{ })
    )
);
