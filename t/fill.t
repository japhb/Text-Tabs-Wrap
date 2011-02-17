#!/usr/bin/env perl6
use v6;
use Test;
use Text::Wrap;

BEGIN {
    @*INC.push('lib');
}

plan 1;

my $input =
"Cyberdog Information

Cyberdog & Netscape in the news
Important Press Release regarding Cyberdog and Netscape. Check it out! 

Cyberdog Plug-in Support!
Cyberdog support for Netscape Plug-ins is now available to download! Go
to the Cyberdog Beta Download page and download it now! 

Cyberdog Book
Check out Jesse Feiler's way-cool book about Cyberdog. You can find
details out about the book as well as ordering information at Philmont
Software Mill site. 

Java!
Looking to view Java applets in Cyberdog 1.1 Beta 3? Download and install
the Mac OS Runtime for Java and try it out! 

Cyberdog 1.1 Beta 3
We hope that Cyberdog and OpenDoc 1.1 will be available within the next
two weeks. In the meantime, we have released another version of
Cyberdog, Cyberdog 1.1 Beta 3. This version fixes several bugs that were
reported to us during out public beta period. You can check out our release
notes to see what we fixed! ";

my $output =
"    Cyberdog Information
    Cyberdog & Netscape in the news Important Press Release regarding
 Cyberdog and Netscape. Check it out! 
    Cyberdog Plug-in Support! Cyberdog support for Netscape Plug-ins is now
 available to download! Go to the Cyberdog Beta Download page and download
 it now! 
    Cyberdog Book Check out Jesse Feiler's way-cool book about Cyberdog.
 You can find details out about the book as well as ordering information at
 Philmont Software Mill site. 
    Java! Looking to view Java applets in Cyberdog 1.1 Beta 3? Download and
 install the Mac OS Runtime for Java and try it out! 
    Cyberdog 1.1 Beta 3 We hope that Cyberdog and OpenDoc 1.1 will be
 available within the next two weeks. In the meantime, we have released
 another version of Cyberdog, Cyberdog 1.1 Beta 3. This version fixes
 several bugs that were reported to us during out public beta period. You
 can check out our release notes to see what we fixed! ";

is  fill('    ', ' ', $input),
    $output;
