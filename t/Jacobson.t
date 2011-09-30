#!/usr/bin/env perl6
use v6;
use Test;
use Text::Wrap;

my @input = (
    "mmmm,n,ooo,ppp.qqqq.rrrrr,sssssssssssss,ttttttttt,uu,vvv wwwwwwwww####\n",
    "mmmm,n,ooo,ppp.qqqq.rrrrr.adsljasdf\nlasjdflajsdflajsdfljasdfl\nlasjdflasjdflasf,sssssssssssss,ttttttttt,uu,vvv wwwwwwwww####\n"
);

plan +@input;

my $break = rx{<?after <[,.]>>};

for @input.kv -> $num, $str {
    # fails in rakudo; "after" NYI
    lives_ok {
        wrap('', '', $str, :huge<overflow>, :columns(9), :$break)
    }, "Test {1+$num} ran"
}
