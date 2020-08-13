#!/usr/bin/expect -f


set timeout 180



set host "HOST01"

set ip "127.0.0.2"

set usuario "LOGIN"

set partida [open "/home/user/Documentos/VALDEMIR/partida.txt"]

set senha [read $partida]

# set senha [lrange $argv 0 0]



# set data [clock format [clock seconds] -format %d%m%Y]

# set dataBkp $host

# append dataBkp "_"

# append dataBkp $data

# append dataBkp ".txt"



log_user 0



# Habilita log copiando a saída padrão para o arquivo 

log_file -a /home/user/Documentos/SCRIPTS/REDUNDANCIA/tmp/$host ;



# Mágica acontecendo ;p

spawn /usr/bin/ssh $ip -l $usuario


expect {
 "sword:" {
 }
 timeout {
    puts "ERRO. NÃO FOI POSSÍVEL LOGAR NESTE EQUIPAMENTO. LIMITE DE TEMPO EXCEDIDO."	
    exit 1 # para sair dessa parte do script
 }
}


#expect "sword:"

send  "$senha\r"

expect "$host"

send "configure no pagination\r"

expect "$host"

log_user 3


send  "show linecard status\r"

expect "$host"

send  "show running-config | include 102 in\r"

expect "$host"

send "exit\r"

expect eof

close $partida

log_file ; #para o log desse arquivo


