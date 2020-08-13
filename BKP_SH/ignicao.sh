#!/usr/bin/expect -f

set timeout 180

log_user 0

set prompt "(%|#|\\$) $"          ;# aguarda retorno de prompt padrao
    catch {set prompt $env(EXPECT_PROMPT)}


#source CGEDTCCMT03.sh

#after 5000

source /home/user/Documentos/SCRIPTS/BKP_SH/HOST01.sh

after 5000

#source/home/user/Documentos/SCRIPTS/BKP_SH/HOST02.sh

#after 5000





set dirname /home/user/Documentos/SCRIPTS/BKP/
set dirnameFinal [clock format [clock seconds] -format %B-%Y]
set dirnameFinalUpper [string toupper $dirnameFinal]
set dataBKP [clock format [clock seconds] -format %d%m%Y]
set pastaDia [clock format [clock seconds] -format %d.%m.%Y]

append dirname "$dirnameFinalUpper"


set dataHora [clock format [clock seconds] -format %d/%m/%Y]

if {$dataHora > 17 && $dataHora < 24} {

set leituraCorpoEmail "Boa noite, "

}

if {$dataHora > 01 && $dataHora < 12} {

set leituraCorpoEmail "Bom dia, "

}

if {$dataHora > 11 && $dataHora < 18} {

set leituraCorpoEmail "Boa tarde, "

}

append leituraCorpoEmail "prezados. Segue anexo BKP dos Equipamentos de JPA e CGE.\r\r\r"

append leituraCorpoEmail "At,\r\r Valdemir Bezerra de Souza J\u00FAnior\r Analista Datacenter\r Net Jo\u00E3o Pessoa\r valdemir.junior2@netservicos.com.br\r Canal de Voz.: 597 907 1 2220\r (83) 3044-2220\r"

set corpoAssunto "Backup dos equipamentos - JPA/CGE - "

set dataAssunto [clock format [clock seconds] -format %d/%m/%Y]

append corpoAssunto $dataAssunto


if {[file exist $dirname]} {
    # checa se o caminho passado é um diretorio
    if {! [file isdirectory $dirname]} {
        puts "$dirname existe, mas é um arquivo"
    }

    if {[file isdirectory $dirname]} {
        puts "$dirname é um diretório válido! movendo BKP's:\r"
	
	file mkdir $dirname/$pastaDia
	
	set equipamentos [open "/home/user/Documentos/SCRIPTS/BKP_SH/polvora.txt" "r"]

        while {[gets $equipamentos line] != -1} {

           #puts "$line$dataBKP"
	   set equipBKP ".txt"
           	
	   file rename /home/datacenter/Documentos/SCRIPTS/BKP/$line$dataBKP$equipBKP /$dirname/$pastaDia/$line$dataBKP$equipBKP

	    #puts "$line$dataBKP$equipBKP"
           
              }

           close $equipamentos

	set zipArquivo $pastaDia.zip

	puts "Empacotando $pastaDia..."
	#log_user 0	
	spawn zip $dirname/$zipArquivo -r $dirname/$pastaDia
	expect -re $prompt
	spawn sendEmail -o tls=yes -f datacenter.jpa@gmail.com -t valdemir.junior2@netservicos.com.br, datacenter.jpa@net.com.br, Luciano.Barroso@net.com.br, Vanderlan.Junior@net.com.br, Tony.Lima@net.com.br, Ricardo.Henriques@net.com.br -s smtp.gmail.com:587 -xu datacenter.jpa@gmail.com -xp emailenvioautomatico -a $dirname/$zipArquivo -u $corpoAssunto -m $leituraCorpoEmail
	expect -re $prompt
	#log_user 3
	puts "$pastaDia empacotada e enviado!"

	#log_user 0
	file delete $dirname/$zipArquivo
	#log_user 3


    }
} else {

    
    file mkdir $dirname
    puts "Criado diretório: $dirname"

	
	file mkdir $dirname/$pastaDia

      set equipamentos [open "/home/user/Documentos/SCRIPTS/BKP_SH//polvora.txt" "r"]

        while {[gets $equipamentos line] != -1} {

           #puts "$line$dataBKP"
	   set equipBKP ".txt"
           	
	  file rename /home/user/Documentos/SCRIPTS/BKP/$line$dataBKP$equipBKP /$dirname/$pastaDia/$line$dataBKP$equipBKP

	    #puts "$line$dataBKP$equipBKP"
           
              }

           close $equipamentos

	set zipArquivo $pastaDia.zip

	puts "Empacotando $pastaDia..."
	#log_user 0	
	spawn zip $dirname/$zipArquivo -r $dirname/$pastaDia
	expect -re $prompt
	spawn sendEmail -o tls=yes -f email-envio@gmail.com -t email-destino1@gmail.com.br, email-destino2@gmail.com.br -s smtp.gmail.com:587 -xu datacenter.jpa@gmail.com -xp emailenvioautomatico -a $dirname/$zipArquivo -u $corpoAssunto -m $leituraCorpoEmail
	expect -re $prompt
	#log_user 3
	puts "$pastaDia empacotada e enviado!"
	
	#log_user 0
	file delete $dirname/$zipArquivo
	#log_user 3

	
}



exit

expect eof


