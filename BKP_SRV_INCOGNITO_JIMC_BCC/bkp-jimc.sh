#!/usr/bin/expect -f

#Desenvolvido por valdemir Bezerra de S. Junior - N5669203 para realizar bkp das classes ip no jimc
#Rodando apenas BCC7 - HFC
#Datacenter NET João Pessoa
#Versão 1.0

#alterar linhas : 16, 19, 33
    
############ VARIAVEIS ##############################################################

set prompt "(%|#|\\$) $"          ;# aguarda retorno de prompt padrao
    catch {set prompt $env(EXPECT_PROMPT)}

#Coloque o seu N na variável abaixo para realizar o login
set loginUsuario "ID" 

#Arquivo com senha do N
set senha [exec openssl enc -d -aes-256-cbc -in /home/Documents/partida_encrypted.txt -pass pass:81b95d53d1f1f749b2e7bc561dc19830fb224f04 -md md5]


#Endereco Cyber
set cyberIP "jumper.ours.com.br"
set cyberIP1 "192.168.0.1"
set cyberIP2 "192.168.0.2"

#Vai retornar o servidor com falha
set servidorFalho ""

#Lista dos ips dos servidores a serem verificados
set servidores {

192.168.0.96
192.168.0.91
192.168.1.30
192.168.1.32
192.168.2.124
192.168.2.30
192.168.2.78
192.168.3.35
192.168.4.33
192.168.4.30
192.168.5.30
192.168.6.76
192.168.6.88
192.168.6.93
192.168.7.34
192.168.7.26

}

#Lista de servidores a serem verificados novamente
set repescagemServidores {}

set leituraCorpoMensagem "Executamos o BKP dos servidores do cluster .&#10;Segue o resumo:&#10;"

set jimcOKtabela "Servidores com BKP - Executado&#10;"

set jimcNOKtabela "Servidores com BKP - NÃO EXECUTADO&#10;"




################# FIM DAS VARIAVEIS ############################################################

######################### CRIA PASTA DATA ############################################################

proc criaPastaData {caminho} {

set dirNome [clock format [clock seconds] -format %B-%Y]
set dirDia [clock format [clock seconds] -format %d.%m.%Y]
#cria uma pasta para o dia de execução
set pastaArquivo "$caminho/$dirNome/$dirDia/"

if {[file isdirectory $caminho]} {

file mkdir $caminho/$dirNome/$dirDia

if {! [file isdirectory $caminho]} {

exit

} else {

file mkdir $caminho/$dirNome/$dirDia
set pastaArquivo "$caminho/$dirNome/$dirDia/"

}


}

return $pastaArquivo


}
#fim do proc

################# FIM PASTA DATA #####################################################################
################# FUNÇÃO PARA CRIAR E ADICIONAR LINHAS NO ARQUIVO servidores.txt #####################

proc escreve_servidor {servidor} {

set escrita [open /home/Documents/BKP_SRV/servidores.txt a]
puts $escrita "$servidor"
close $escrita

}

#####################################################################################################
##################VERIFICA SE TEM CONTAGEM DE LINHAS ################################################

proc pegaContagemLinhas {prompt caminhoArquivo} {

#a caralha do tcl nao escapa as [] tem que botar o unicode
#comando: grep Scope bkp_rule/October-2023/06.10.2023/rule-192.168.6.76-06102023.csv | sed 's/[^0-9]*//g'
#spawn /usr/bin/grep 'Count:' $caminhoArquivo \u007c /usr/bin/sed 's/\u005b^0-9\u005d*//g'

#spawn grep "Count:" $caminhoArquivo
#expect -re $prompt

#set retornoGrep $expect_out(buffer)

#nessacaraia do expect ele interpreta o retorno padrão como erro 1 entao se voltar zero é true
#para emular o processo no linux, usar o parametro -c para trazer 0 ou 1(true)
#caso queira pegar a saida do comando, tire -c e print $resultado mas caso o grep nao ache nada, o 
#expect retorna a mensagem "child process exited abnormally"  entao vc deve dar um if no retorno O_o
set retornoGrep [catch {exec /usr/bin/grep -c Count: $caminhoArquivo} resultado]
#pega so o valor booleano da consulta. 1(true) 0 (false)
#set retornoGrepRegex [regexp {[0-9]} $resultado valor]
if {$resultado == 1} {

return $resultado


} else {

set resultado 0
return $resultado

}


}

##################FIM DA CONTAGEM DE LINHAS #########################################################

################# CONEXAO SSH ##################################################################
proc conexaoSSH {loginUsuario senha servidor cyberIP prompt } {

puts ""
puts "Logando no servidor $servidor..."

log_user 0



spawn /usr/bin/ssh -o StrictHostKeyChecking=no $loginUsuario@root@$servidor@$cyberIP



expect {
   
timeout {puts "Tempo excedido para o servidor: $servidor."; set servidorFalho "$servidor Inacessível. TIMEOUT"}

".*to host" {puts "Sem rota pro cyberark de ip: $cyberIP durante a consulta do servidor: $servidor."; set servidorFalho "$servidor Inacessível. S/ROTA"}
   
"*refused*" {puts "Conexão recusada pelo servidor $servidor"; set servidorFalho "$servidor Inacessível. REFUSED"}

".*key.*failed.*" {puts "Conexão ao servidor $servidor falhou."; set servidorFalho "$servidor Inacessível. KEYFAIL"}
   
".*assword:" {

send "$senha\r" 
expect -re $prompt
#comando abaixo aguarda ele finalizar o comando anterior, no caso logar
expect eof
set servidorFalho ""
log_user 3
#comando abaixo faz ele seguir para o proximo passo
exp_continue
                
}



"*#*" {

#log_user 0
puts ""
puts "Logado com sucesso!"

puts ""
puts "Coletando as related rules...\r"

set comandoRelateRule "/usr/local/bin/ipcli -S $servidor -N Administrator -P 'AH1mqMdJ3Z6Rw4lPooZBcr' list RULE LOOKUPKEY NAME output csv\r"
set caminhoArquivoRRule [criaPastaData "/home/Documents/BKP_SRV/bkp_relate_rule"]
append caminhoArquivoRRule "relate-$servidor"

set data [clock format [clock seconds] -format %d%m%Y]

append caminhoArquivoRRule "-$data"
append caminhoArquivoRRule ".csv"

log_file -noappend $caminhoArquivoRRule ;
send $comandoRelateRule
expect -re $prompt
#o expect abaixo espera o comando terminar e fecha o log
expect eof
log_file ;


set comandoTemplate "/usr/local/bin/ipcli -S $servidor -N Administrator -P 'AH1mqMdJ3Z6Rw4lPooZBcr' list TEMPLATE LOOKUPKEY  NAME  output csv\r"
set caminhoArquivoTemplate [criaPastaData "/home/Documents/BKP_SRV/bkp_template"]
append caminhoArquivoTemplate "template-$servidor"

append caminhoArquivoTemplate "-$data"
append caminhoArquivoTemplate ".csv"

log_file -noappend $caminhoArquivoTemplate ;
send $comandoTemplate
expect -re $prompt
#o expect abaixo espera o comando terminar e fecha o log
expect eof
log_file ;


set comandoRule "/usr/local/bin/ipcli -S $servidor -N Administrator -P 'AH1mqMdJ3Z6Rw4lPooZBcr' list SCOPE NAME IPFROM IPTO SUBNETMASK CRITERIA TEMPLATELOOKUPKEY DEFAULTGW LEASETIME DISABLED PARENTLOOKUPKEY output csv\r"
set caminhoRule [criaPastaData "/home/Documents/BKP_SRV/bkp_rule"]
append caminhoRule "rule-$servidor"

append caminhoRule "-$data"
append caminhoRule ".csv"

log_file -noappend $caminhoRule ;
send $comandoRule
expect -re $prompt
#o expect abaixo espera o comando terminar e fecha o log
expect eof
log_file ;


set comandoPrefix6 "/usr/local/bin/ipcli -S $servidor -N Administrator -P 'AH1mqMdJ3Z6Rw4lPooZBcr' list PREFIXDELEGATIONRULEV6 NAME DESCRIPTION PREFIX PREFIXLENGTH DEFAULTPREFIXLENGTH PREFERREDLIFETIME VALIDLIFETIME CRITERIA RAPIDCOMMIT DISABLED output csv\r"
set caminhoPrefix6 [criaPastaData "/home/Documents/BKP_SRV/bkp_v6"]
append caminhoPrefix6 "prefix6-$servidor"

append caminhoPrefix6 "-$data"
append caminhoPrefix6 ".csv"

log_file -noappend $caminhoPrefix6 ;
send $comandoPrefix6
expect -re $prompt
#o expect abaixo espera o comando terminar e fecha o log
expect eof
log_file ;


set comandoRule6 "/usr/local/bin/ipcli -S $servidor -N Administrator -P 'AH1mqMdJ3Z6Rw4lPooZBcr' list RULEV6 NAME DESCRIPTION STARTIPADDRESS ENDIPADDRESS NONSEQUENTIAL PREFERREDLIFETIME VALIDLIFETIME CRITERIA RAPIDCOMMIT DISABLED output csv\r"
set caminhoRule6 [criaPastaData "/home/Documents/BKP_SRV/bkp_v6"]
append caminhoRule6 "rule6-$servidor"

append caminhoRule6 "-$data"
append caminhoRule6 ".csv"

log_file -noappend $caminhoRule6 ;
send $comandoRule6
expect -re $prompt
#o expect abaixo espera o comando terminar e fecha o log
expect eof
log_file ;


set comandoRouting "/usr/local/bin/ipcli -S $servidor -N Administrator -P 'AH1mqMdJ3Z6Rw4lPooZBcr' list ROUTINGELEMENT NAME MANAGEMENTIP output csv\r"
set caminhoRouting [criaPastaData "/home/Documents/BKP_SRV/bkp_routing"]
append caminhoRouting "routing-$servidor"

append caminhoRouting "-$data"
append caminhoRouting ".csv"

log_file -noappend $caminhoRouting ;
send $comandoRouting
expect -re $prompt
#o expect abaixo espera o comando terminar e fecha o log
expect eof
log_file ;

#agora vou ler o arquivo de routing gerado para fazer a consulta de cada routing gerado ignorando as linhas em branco
#nas linhas com letras filtrar com regex apenas as linhas que começam com "
#depois filtrar o nome do CMTS(apenas caracteres alfanumericos
set cmts [open "$caminhoRouting" r]
while {[gets $cmts linha] != -1} {

set comandoRCMTS ""
set caminhoRCMTS ""

if {[string trim $linha] != ""} {

#puts "$linha"
set linhaComecaAspas [regexp {\".*?\"} $linha a]

if {$linhaComecaAspas == 1} {
set cmtsRValido [regexp {[a-zA-Z0-9].*[a-zA-Z0-9]} $a [string trim cmtsValido]]


if {$cmtsValido != "NAME"} {

puts "Coletando as routings de cada CMTS desse servidor...\r"
puts "Coletando do CMTS $cmtsValido...\r"

append comandoRCMTS "/usr/local/bin/ipcli -S $servidor -N Administrator -P 'AH1mqMdJ3Z6Rw4lPooZBcr' show ROUTINGELEMENT $cmtsValido\r"
append caminhoRCMTS [criaPastaData "/home/Documents/BKP_SRV/bkp_routing"]
append caminhoRCMTS "routing-$servidor-$cmtsValido"

append caminhoRCMTS "-$data"
append caminhoRCMTS ".csv"

log_file -noappend $caminhoRCMTS ;
send $comandoRCMTS
expect -re $prompt
#o expect abaixo espera o comando terminar e fecha o log
expect eof
log_file ;


}



}



}


}
#fim do while
close $cmts




send "exit\r"
expect -re $prompt


set retornoComandoRelateR [pegaContagemLinhas $prompt $caminhoArquivoRRule]
#puts $retornoComandoRelateR

set retornoComandoTemplate [pegaContagemLinhas $prompt $caminhoArquivoTemplate]
#puts $retornoComandoTemplate

set retornoComandoPrefix6 [pegaContagemLinhas $prompt $caminhoPrefix6]

set retornoComandoRule6 [pegaContagemLinhas $prompt $caminhoRule6]

set retornocomandoRouting [pegaContagemLinhas $prompt $caminhoRouting]

set servidorFalho ""

set retornoComandoRules [pegaContagemLinhas $prompt $caminhoRule]
after 5000

#se tiver 0 tem problema
if {$retornoComandoRelateR != 1 || $retornoComandoTemplate != 1 || $retornoComandoRules != 1 || $retornoComandoPrefix6 != 1 || $retornoComandoRule6 != 1 || $retornocomandoRouting != 1} {

puts "Ocorreu erro para o server $servidor. REL: $retornoComandoRelateR | TEM: $retornoComandoTemplate | RUL: $retornoComandoRules | PRE6: $retornoComandoPrefix6 | RUL6: $retornoComandoRule6 | ROU: $retornocomandoRouting\r"
set servidorFalho "$servidor. REL: $retornoComandoRelateR | TEM: $retornoComandoTemplate | RUL: $retornoComandoRules | PRE6: $retornoComandoPrefix6 | RUL6: $retornoComandoRule6 | ROU: $retornocomandoRouting"
} else {

puts "$servidor OK!\r"

}

puts ""
puts "FINALIZANDO!\r"


}



#fim do expect
}


#puts "falha do teste de acesso: $servidorFalho"
return $servidorFalho

#fim da conexaoSsh
}
#####################################  FIM DO SSH ########################################################################

##################################### MAIN ###############################################################################

#verifica se o arquivo servidores.txt existe. Caso exista, apaga ele
if {[file exists /home/Documents/BKP_SRV/servidores.txt]} {

file delete -force /home/Documents/BKP_SRV/servidores.txt

}

#Loop para tentar logar em cada servidor

foreach servidor $servidores {

set coletaServidor [conexaoSSH $loginUsuario $senha $servidor $cyberIP $prompt]
 
if {$coletaServidor == ""} {

puts "\r"
puts "BKP servidor coletado com sucesso! Servidor: $servidor\r"

#vai pra mensagem de servidores OK e adicionamos o ip na lista de servidores que foram executados
append jimcOKtabela "$servidor&#10;"
set servidor_adicionado [escreve_servidor $servidor]


} else {

puts "Servidor $servidor NOK!\r"
lappend repescagemServidores $servidor

}



}
#fim do foreach

if {[llength $repescagemServidores] > 0 } {

puts "Há servidores na lista de repescagem. Será tentado novamente!\r"

foreach servidor $repescagemServidores {

set coletaServidorRepescagem [conexaoSSH $loginUsuario $senha $servidor $cyberIP $prompt]

if {$coletaServidorRepescagem ==""} {

puts "\r"
puts "BKP servidor coletado com sucesso na repescagem! Servidor: $servidor\r"

#vai pra mensagem de servidores OK e adicionamos o ip na lista de servidores que foram executados
append jimcOKtabela "$servidor&#10;"
set servidor_adicionado [escreve_servidor $servidor]

} else {


#faco um regex pra ver se tem a palavra inacessível presente nos servidores nao logados, se tiver acrescenta no corpo do email
#set retornoIndiceRegex [regexp {.*Inacess.*} $coletaServidorRepescagem retornoRegex]
append jimcNOKtabela $coletaServidorRepescagem


}


}
#fim do foreach


}
#fim do if llengyh

append leituraCorpoMensagem $jimcOKtabela 
append leituraCorpoMensagem $jimcNOKtabela

puts "\r"
puts "\r"

puts "$leituraCorpoMensagem\r"

puts "FIM DO SCRIPT"

