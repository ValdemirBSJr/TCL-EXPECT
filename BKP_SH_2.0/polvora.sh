#!/usr/bin/expect -f

#Script recebe o ip e comandos e tenta logar e rodar os comandos
#Versão 1.0

############ VARIAVEIS ##############################################################


set prompt "(%|>|#|\\\$) $"          ;# aguarda retorno de prompt padrao
    catch {set prompt $env(EXPECT_PROMPT)}
    
#Coloque o seu N na variável abaixo
set loginUsuario "ID" 

#set senhaREAD [open "/home/Documents/partida.txt"]
set senha [exec openssl enc -d -aes-256-cbc -in /home/Documents/partida_encrypted.txt -pass pass:81b95d53d1f1f749b2e7bc561dc19830fb224f04 -md sha256 2>/dev/null]
    
#Enderecos Cyber
set cyberIP "jumper_domain.com"
set cyberIP1 "192.168.0.1"
set cyberIP2 "192.168.0.2"


#CAMINHO PARA SALVAR O LOG
set caminho_log "/home/Documents/BKP_SH/"



set ip [lindex $argv 0]

set comando_arg [lindex $argv 1]

set lista_comandos [split $comando_arg ","]


#uso regex pra validar o ip e comandos. Se o ip for invalido ou se os comandos forem vazios ou sem virgulas separadoras pontua
if {[regexp {^(?:(\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))(?:\.((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))){3}$} $ip] && [regexp {.+,.+} $comando_arg]} {


puts "Ip passado: $ip\r"
puts ""

puts ""
puts "Logando no equipamento $ip...\r"

log_user 3

set data [clock format [clock seconds] -format %d%m%Y]
set nomeLog $ip
append nomeLog "_"
append nomeLog $data
append nomeLog ".txt"
log_file -noappend $caminho_log$nomeLog ;


spawn /usr/bin/ssh $loginUsuario@$ip

expect {



#cada status recebe um numero. se for 0 foi OK senão o python vai informar na mensagem
timeout {puts "Tempo excedido para o equipamento: $ip."; set equipamentoFalho "1"}

".*to host" {puts "Sem rota para o equipamento: $ip."; set equipamentoFalho "2"}
   
"*refused*" {puts "Conexão recusada pelo servidor $ip"; set equipamentoFalho "3"}

".*key.*failed.*" {puts "Conexão ao servidor $ip falhou."; set equipamentoFalho "4"}

"*yes/no*" {

send "yes\r"
exp_continue 

}

"?sword:" {
send "$senha\r"
exp_continue 

}

-re "#|>" {


foreach comando $lista_comandos {

send "$comando\r"
expect -re $prompt

} 

set equipamentoFalho "0"



}



}
#fim do expect

log_file ;
file rename -force $caminho_log$nomeLog $caminho_log$equipamentoFalho-$nomeLog






} else {

puts "\rIP inválido ou comandos vazios/passados de forma incorreta. Favor verificar parâmetros passados e o ip."

}
#fim do if que valida o ip