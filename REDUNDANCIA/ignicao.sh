#!/usr/bin/expect -f

set timeout 180

set prompt "(%|#|\\$) $"          ; # aguarda retorno de prompt padrao
    catch {set prompt $env(EXPECT_PROMPT)}



set dataHora [clock format [clock seconds] -format %H]

if {$dataHora > 17 && $dataHora < 24} {

set leituraCorpoEmailResumo "<p>Boa noite, "

}

if {$dataHora > 00 && $dataHora < 13} {

set leituraCorpoEmailResumo "<p>Bom dia, "

}

if {$dataHora > 12 && $dataHora < 18} {

set leituraCorpoEmailResumo "<p>Boa tarde, "

}



append leituraCorpoEmailResumo "prezados. Segue abaixo verifica&ccedil;&atilde;o de redund&acirc;ncia e config de access-group dos equipamentos de JPA e CGE.</p><br><br><br>Segue planilha com o resumo: <br><br>"

append leituraCorpoEmailResumo "<table class=MsoNormalTable border=0 cellspacing=0 cellpadding=0 width=339
style='width:253.95pt;margin-left:-.75pt;border-collapse:collapse;mso-yfti-tbllook:
1184;mso-padding-alt:0cm 0cm 0cm 0cm'><tr style='mso-yfti-irow:0;mso-yfti-firstrow:yes;height:15.75pt'><td width=114 nowrap valign=bottom style='width:85.3pt;padding:0cm 3.5pt 0cm 3.5pt;
  height:15.75pt'></td><td width=225 nowrap colspan=3 style='width:168.65pt;border:solid white 1.0pt;
  border-right:none;background:#DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><b><span
  style='font-size:10.0pt;line-height:115%'>COMUTA&Ccedil;&Atilde;O PLACA<o:p></o:p></span></b></p></td></tr><tr style='mso-yfti-irow:1;height:15.75pt'>
  <td width=114 nowrap valign=bottom style='width:85.3pt;padding:0cm 3.5pt 0cm 3.5pt;
  height:15.75pt'></td><td width=137 nowrap style='width:102.5pt;border:solid white 1.0pt;
  border-top:none;background:#DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><b><span
  style='font-size:10.0pt;line-height:115%'>PROCESSADORA<o:p></o:p></span></b></p>
  </td><td width=60 nowrap style='width:44.75pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><b><span
  style='font-size:10.0pt;line-height:115%'>DOWN<o:p></o:p></span></b></p>
  </td><td width=29 nowrap style='width:21.4pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><b><span
  style='font-size:10.0pt;line-height:115%'>UP<o:p></o:p></span></b></p></td></tr>"

set leituraCorpoEmail "<h1>HOSTS</h1>"




#------- VERIFICAÇÃO INDIVIDUAL HOST01 ------

source HOST01.sh

after 2000

set host "HOST01"



### Abre modelo ideal de redundãncia

set modeloSlots [open "/home/user/Documentos/SCRIPTS/REDUNDANCIA/modelo/$host" "r"]

set contador 0
set validado ""
set retornoStatus ""

        while {[gets $modeloSlots line] != -1} {

           # puts $line

		spawn grep -i "$line" tmp/$host

		expect -re $prompt

		set retornoTmp $expect_out(buffer)


		if {$retornoTmp == ""} 	{
		

                 incr contador 

		 #set caractereComutada [open "/home/user/Área de trabalho/BKP/REDUNDANCIA/comutadas/$host" "r"]

                 #set lidoCaractere [read $caractereComutada]

		 #spawn grep "$lidoCaractere" tmp/$host

                 #expect -re $prompt

                 append retornoStatus "<p>$line</p>"

		break

                } else {
		
		 append validado "<p>$retornoTmp</p>"	
	
		}
		
           
           }

           close $modeloSlots

	   puts "$contador"

if {$contador == 0} {

append leituraCorpoEmailResumo "<tr style='mso-yfti-irow:2;height:15.75pt'>
  <td width=114 nowrap style='width:85.3pt;border:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><b><span
  style='font-size:10.0pt;line-height:115%'>$host<o:p></o:p></span></b></p>
  </td><td width=137 nowrap style='width:102.5pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><span
  style='font-size:10.0pt;line-height:115%'>OK<o:p></o:p></span></p>
  </td><td width=60 nowrap style='width:44.75pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><span
  style='font-size:10.0pt;line-height:115%'>OK<o:p></o:p></span></p>
  </td><td width=29 nowrap style='width:21.4pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><span
  style='font-size:10.0pt;line-height:115%'>OK<o:p></o:p></span></p>
  </td>
</tr>"

append leituraCorpoEmail "<table style='width: 500px;' border='1'><tbody><tr style='height: 34px;'><td style='width: 499px; height: 34px;background-color: #b3ffb3'>&nbsp;$host - OK!</td></tr><tr style='height: 82px;'><td style='width: 499px; height: 82px;'>$validado<p>&nbsp;</p></td></tr></tbody></table><br><br>"

} else {

append leituraCorpoEmailResumo "<tr style='mso-yfti-irow:2;height:15.75pt'>
  <td width=114 nowrap style='width:85.3pt;border:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><b><span
  style='font-size:10.0pt;line-height:115%'>$host<o:p></o:p></span></b></p>
  </td><td width=137 nowrap style='width:102.5pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><span
  style='font-size:10.0pt;color:red;line-height:115%'>NOK<o:p></o:p></span></p>
  </td><td width=60 nowrap style='width:44.75pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><span
  style='font-size:10.0pt;line-height:115%'>-<o:p></o:p></span></p>
  </td><td width=29 nowrap style='width:21.4pt;border-top:none;border-left:none;
  border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:
  #DCE6F1;padding:0cm 3.5pt 0cm 3.5pt;height:15.75pt'>
  <p class=MsoNormal align=center style='text-align:center'><span
  style='font-size:10.0pt;line-height:115%'>-<o:p></o:p></span></p>
  </td>
</tr>"

append leituraCorpoEmail "<table style='width: 500px;' border='1'><tbody><tr style='height: 34px;' border='1'><td style='width: 499px; height: 34px;background-color: #ff8566'>&nbsp;$host - COM PLACA COMUTADA!</td></tr><tr style='height: 82px;'><td style='width: 499px; height: 82px;'><p style='color:red'><b>Interfaces comutadas:</b></p><p>$retornoStatus</p><p>&nbsp;</p></td></tr></tbody></table><br><br>"

}

# apagando arquivo

file delete tmp/$host



#------------ FIM DA VERIFICAÇÃO -----------------------



#--------------------------- MANDA O EMAIL!


append leituraCorpoEmailResumo "</table><br><br>"


#Aqui concateno as strings
set corpoEmailConsolidado [concat $leituraCorpoEmailResumo$leituraCorpoEmail]




puts "MANDANDO EMAIL..."


 set corpoAssunto "Check comutacao de processadora/linecard e access-group - JPA/CGE realizada em "

set dataAssunto [clock format [clock seconds] -format %d/%m/%Y]

append corpoAssunto $dataAssunto

#append leituraCorpoEmail "<p><i style='color:#999999'>Powered by VALDEMIR</i></p>" 

append corpoEmailConsolidado "<br><br><p>At,</p><br><p>Valdemir Bezerra de Souza J&uacute;nior</p><p>Analista Datacenter</p><p>Net Jo&atilde;o Pessoa</p><a href='mailto:email@gmail.com'>email@gmail.com.br</a><p>Canal de Voz.: 88888888</p><p>(83) 88888888</p>"

 spawn sendEmail -o tls=yes -o message-content-type=html -f email-envio@gmail.com -t email-destino2@gmail.com.br -s smtp.gmail.com:587 -xu email-envio@gmail.com -xp senhaemailenvioautomatico  -u $corpoAssunto -m $corpoEmailConsolidado

 expect -re $prompt




puts "THAT'S ALL FOLKS!"

exit



expect eof
