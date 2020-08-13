#!/usr/bin/expect -f



    
set caminhoIPEntrada [open "/home/user/Documentos/SCRIPTS/tracertEMLOTE/entrada.txt" "r"]

set dataTCR [clock format [clock seconds] -format %d-%m-%Y_%H:%M:%S]

set logy "saidaTCR-"

append logy $dataTCR

append logy ".txt"

set user "rviews"

set endereco "rviews.kanren.net"


# Habilita log copiando a saída padrão para o arquivo 

log_file /home/user/Documentos/SCRIPTS/tracertEMLOTE/saida/$logy ;



log_user 0

spawn /usr/bin/ssh $user@$endereco

expect "password:"

send "$user\r"

expect "vm>"


log_user 3


while {[gets $caminhoIPEntrada line] != -1} {

send "#=======================================================================\r"
send "#=========IP CONSULTADO...: $line\r"

send "traceroute $line\r"

after 30000

expect "vm>"



}



log_user 0

send "exit\r"

log_user 3



expect eof
close $caminhoIPEntrada
log_file ; #para o log desse arquivo 

puts ""
puts ""
puts "#=======================================================================\r"
puts "FIM DA CONSULTA EM LOTES!!!"
