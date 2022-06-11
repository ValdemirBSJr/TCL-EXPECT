#!/usr/bin/expect -f

set name "david"

switch -glob $name \
david { puts "david" } \
sam { puts "sam" } \
default { puts "não conheço esse nome" } \


switch $name {

david {puts "david"}
default {puts "sem nome aqui irmão"}

}


puts -nonewline "Throw a die. What value did you get? "
flush stdout

set top [gets stdin]

switch $top {
1 {set end "st"}
2 {set end "nd"}
3 {set end "rd"}
default {set end "th"}
}

puts "you selected the $top$end face"

puts "Digite um ip:"
flush stdout
set IP [gets stdin]

proc validarIP {IP} {
if {[regexp {^(?:(\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))(?:\.((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))){3}$} $IP]} {
        puts "$IP é um IP válido"
        return true
        
    } else {
        puts "IP INVALIDO"
        return false
    }
}

set running [validarIP "$IP"]

puts "$running"



exit
expect eof
