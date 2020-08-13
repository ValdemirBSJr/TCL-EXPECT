#!/usr/bin/expect -f


set timeout 180

set partida [open "polvora.txt"]

set senha [read $partida]

puts $senha

set out "oi"

if {$out != ""} {
send_user $out
}