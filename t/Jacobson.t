#!/usr/bin/env perl6
use v6;
use Test;
use Text::Wrap;

BEGIN {
    @*INC.push('lib');
}

my @input = (
    "mmmm,n,ooo,ppp.qqqq.rrrrr,sssssssssssss,ttttttttt,uu,vvv wwwwwwwww####\n",
    "mmmm,n,ooo,ppp.qqqq.rrrrr.adsljasdf\nlasjdflajsdflajsdfljasdfl\nlasjdflasjdflasf,sssssssssssss,ttttttttt,uu,vvv wwwwwwwww####\n"
);

plan +@input;

$Text::Wrap::huge = 'overflow';
$Text::Wrap::columns = 9;
$Text::Wrap::break = rx{<?after <[,.]>>};

for @input.kv -> $num, $str {
    todo (1+$num) => '<?after> NYI in Rakudo';
    lives_ok { wrap('', '', $str) }
}
