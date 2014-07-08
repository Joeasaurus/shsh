shsh -- Shadow Shell
====

Bash eval IRC bot written in Bash

## Why?
There was a need in our local corner of the internet to have some quick bash eval from an IRC client. I thought "Hey, I wonder if I can do it inception style?" -- here we are.

## How?
It uses the [ircsh](https://github.com/drakedevel/ircsh) library, extended to deal with modules for message hooks and a small eval environment using 'coproc'.
Nothing fancy in here, in fact most of it could probably be done more efficiently.

Released under the [MIT license](http://opensource.org/licenses/MIT)
