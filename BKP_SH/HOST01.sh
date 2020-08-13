#!/usr/bin/expect -f


set timeout 180



set host "HOST01"

set ip "127.0.0.1"

set usuario "LOGIN"

set partida [open "/home/user/Documentos/SCRIPTS/BKP_SH/partida.txt"]

set senha [read $partida]

#set senha [lrange $argv 0 0]



set data [clock format [clock seconds] -format %d%m%Y]

set dataBkp "ARRIS_"

append dataBkp $host

append dataBkp "_"

append dataBkp $data

append dataBkp ".txt"



log_user 3



# Habilita log copiando a saída padrão para o arquivo 

log_file /home/datacenter/Documentos/SCRIPTS/BKP/$dataBkp ;



# Mágica acontecendo ;p

spawn /usr/bin/ssh $ip -l $usuario




expect "sword:"

send  "$senha\r"

expect "$host"

send "show clock\r"

expect "$host"

send "configure no pagination\r"

expect "$host"

send  "show linecard status\r"

expect "$host"

send "show running-config verbose\r"

expect "$host"

send "configure pagination\r"

expect "$host"

send "write memory\r"

expect "$host"

send "exit\r"

expect eof

close $partida

log_file ; #para o log desse arquivo


