#!/usr/bin/expect -f

set prompt "(%|#|\\$) $"          ;# aguarda retorno de prompt padrao
    catch {set prompt $env(EXPECT_PROMPT)}
    

set data [clock format [clock seconds] -format %d%m%Y]

set logCRC "CRCOutput-"

append logCRC $data

append logCRC ".txt"


# Habilita log copiando a saída padrão para o arquivo 

log_file /home/user/Documentos/SCRIPTS/CRC/CRClogs/$logCRC ;


###### CRT01 ##############################

set timeout 180

set host "HOST01"

set ip "127.0.0.1"

set usuario "LOGIN-REDE"

set partida [open "/home/user/Documentos/SCRIPTS/CRC/partida.txt"]

set senha [read $partida]

set dataAtual [clock format [clock seconds] -format %d.%m.%Y]

set contador 1

# set senha [lrange $argv 0 0]



# set data [clock format [clock seconds] -format %d%m%Y]

# set dataBkp $host

# append dataBkp "_"

# append dataBkp $data

# append dataBkp ".txt"

puts " "

puts "===> HOST01 - CMTS"

puts " "

log_user 0



# Habilita log copiando a saída padrão para o arquivo 

#log_file -a /home/user/Documentos/SCRIPTS/REDUNDANCIA/tmp/$host ;



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

send "screen-length 0 temporary\r"

expect "$host"

log_user 3

send "display interface description | in HOST01\r"

expect "$host"

send  "display interface gigabitEthernet 1/0/12 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 3/1/5 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/0/0 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/0/1 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/0/2 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/0/3 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/0/4 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/0/8 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/1/8 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 6/1/3 | i CRC\r"

expect "$host"





puts " "
puts "===> HOST01 - LINKS"

send "display interface description | in JPA-IP\r"

expect "$host"

send  "display interface gigabitEthernet 1/0/1 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 1/0/2 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 1/0/3 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 1/0/18 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 2/0/11 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 2/1/1 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 2/1/3 | i CRC\r"

expect "$host"

send  "display interface gigabitEthernet 2/1/3.4003 | i drops\r"

expect "$host"

send  "display interface gigabitEthernet 2/1/3.4031 | i drops\r"

expect "$host"

send  "display interface gigabitEthernet 3/0/6 | i CRC\r"

expect "$host"



log_user 0
send "quit\r"




log_user 3

###### CRT02 ##############################

set timeout 180

set host "HOST02"

set ip "127.0.0.2"

set usuario "LOGIN-REDE"

set partida [open "/home/user/Documentos/SCRIPTS/CRC/partida.txt"]

set senha [read $partida]

set dataAtual [clock format [clock seconds] -format %d.%m.%Y]

set contador 1

# set senha [lrange $argv 0 0]



# set data [clock format [clock seconds] -format %d%m%Y]

# set dataBkp $host

# append dataBkp "_"

# append dataBkp $data

# append dataBkp ".txt"

puts " "

puts "===> HOST02 - CMTS"

puts " "

log_user 0






set corpoAssunto "Check CRC/ERROR"

set dataAssunto [clock format [clock seconds] -format %d/%m/%Y]

append corpoAssunto $dataAssunto


set dataHora [clock format [clock seconds] -format %H]

if {$dataHora > 17 && $dataHora < 24} {

set leituraCorpoEmail "Boa noite, "

}

if {$dataHora > 00 && $dataHora < 13} {

set leituraCorpoEmail "Bom dia, "

}

if {$dataHora > 12 && $dataHora < 18} {

set leituraCorpoEmail "Boa tarde, "

}

puts " "
puts "Enviando email para a caixa mensagens, favor editar o remetente antes do envio e mandar para destino!"


log_user 0

set corpoEmail [open /home/user/Documentos/SCRIPTS/CRC/CRClogs/$logCRC]

append leituraCorpoEmail "prezados. Segue check-list de CRC.\r\r"

append leituraCorpoEmail [read $corpoEmail]

append leituraCorpoEmail "At,\r\r Valdemir Bezerra de Souza J\u00FAnior\r Analista Datacenter\r Net Jo\u00E3o Pessoa\r valdemir.junior2@gmail.com.br\r Canal de Voz.: 88888888\r"


spawn sendEmail -o tls=yes -f email-origem@gmail.com -t  email-destino@gmail.com.br -s smtp.gmail.com:587 -xu email-origem@gmail.com -xp emailenvioautomatico  -u $corpoAssunto -m $leituraCorpoEmail

expect -re $prompt




log_user 3

puts " "
puts "Email enviado, favor verificar... "
# final

exit

expect eof

log_file




