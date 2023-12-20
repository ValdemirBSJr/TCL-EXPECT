# -*- coding: utf-8 -*-

import subprocess
import os
import sys
from datetime import datetime
from Equipamentos import equipamentos
from Funcoes import pasta_destino, renomeia, move_arquivo, valida_PGP

DATA_ATUAL = datetime.now().strftime('%d/%m/%Y')
MES_ATUAL = datetime.now().strftime('%B').upper()
ANO_ATUAL = datetime.now().strftime('%Y')
DATA_ATUAL_CAMINHO = datetime.now().strftime('%d.%m.%Y')

container = 'CONTAINER_ID'
pasta_origem_container = '/home/Documents/BKP_SH/'
pasta_origem_script = '/home/datacenter/BKP_SH/'
pasta_bot_tg = '/home/Documents/'
assunto = f'Certifica&#231;&#227;o BKP CMTS/RTD - CITY - {DATA_ATUAL}'
resumo = ''
equipamentos_OK = ''
equipamentos_NOK = ''
caminho_PGP = f'Arquivos de PGP BKP dispon&#237;veis na pasta do dia:&#10;LOG_BKP/{MES_ATUAL}-{ANO_ATUAL}/{DATA_ATUAL_CAMINHO}/'


#primeiramente tentamos criar a pasta que guardará os logs
criacao_pasta = pasta_destino(pasta_origem_script)
if not criacao_pasta == 'ERRO':
    print('')
    print(f'PASTA {criacao_pasta} existe. Iremos mover os arquivos de PGP pra ela.')
else:
    print('')
    print(f'Erro na criação da pasta de destino dos arquivos. Verifique os parametros passados.')
    sys.exit()


print('')
print('Tentando inicializar o container...')
sub_abre = subprocess.run([f'/usr/bin/docker container start {container}'], shell=True, capture_output=True)
status = sub_abre.returncode
status_erro = sub_abre.stderr

if status == 0:

    print('Container inicializado com sucesso!')
    print('Iremos comecar as coletas...')
    print('')

    for ip, propriedades in equipamentos.items():
        print(f"Iniciando coleta do ip: {ip}")
        for subchave, valor in propriedades.items():
            #print(f'Subchave: {subchave}. Valor: {valor}')
            if subchave == 'HOSTNAME':
                hostname = valor
            if subchave == 'MODELO':
                modelo = valor
            if subchave == 'EQUIPAMENTO':
                equip = valor
            if subchave == 'COMANDOS':
                comandos = valor

        comando_montado = "/usr/bin/docker exec -t " + container + " " + pasta_origem_container + "polvora.sh " + ip + " \"" + comandos + "\""
        comando_aplicado = subprocess.run(comando_montado, shell=True, capture_output=True)
        retorno_comando = comando_aplicado.returncode
        retorno_comando_erro = comando_aplicado.stderr

        if retorno_comando == 0:
            print(f'SCRIPT do equipamento {hostname}-{ip} executado com sucesso!')

            #abaixo irei iterar sobre os arquivos da pasta corrente para verificar se foi criado o log
            for arquivo_log_bruto in os.listdir(pasta_origem_script):
                if ip in arquivo_log_bruto:
                    print(f'Arquivo de log de equipamento encontrado...: {arquivo_log_bruto}')

                    #Agora vamos analizar o arquivo para validar o status final passado no nome dele
                    status_log_inicial = arquivo_log_bruto.split('-')
                    status_log = status_log_inicial[0]
                    data_log = status_log_inicial[1].split('_')
                    data_log = data_log[1]

                    if status_log == '0':
                        print(f'coleta PGP do equipamento {hostname}-{ip} foi executado!')

                        #agora vamos verificar que tipo de equipamento e vamos trata-lo
                        arquivo_renomeado = renomeia(equipamento=equip, log_bruto=arquivo_log_bruto, pasta_origem=pasta_origem_script, modelo=modelo, hostname=hostname, data_log=data_log)
                        
                        #vamos analizar o arquivo
                        comandos_achados, qtde_criteriospgp = valida_PGP(arquivo_renomeado, equip, modelo)
                        if comandos_achados < 1:
                            print(f'PGP de {hostname} não aderente.')
                            equipamentos_NOK += f'{hostname}_{data_log} -> (PGP NOK - ver log) ❌&#10;'
                        if comandos_achados >= qtde_criteriospgp:
                            print(f'PGP OK. Foram encontrados {str(comandos_achados)} comandos aplicados conforme PGP para o {equip} {modelo} {hostname}. Qtde de criterios esperados: {str(qtde_criteriospgp)}')
                            equipamentos_OK += f'{hostname}_{data_log} -> (PGP OK)✅&#10;'
                        if comandos_achados < qtde_criteriospgp:
                            print(f'ATENCAO!!!! Há comandos faltantes. PGP nao aderente! Comandos encontrados {str(comandos_achados)} conforme PGP para o {equip} {modelo} {hostname}. Qtde de criterios esperados: {str(qtde_criteriospgp)}')
                            equipamentos_NOK += f'{hostname}_{data_log} -> (PGP NOK - comandos faltantes) ❌&#10;'
                        
                        
                        #aqui vamos ver se deu erro em renomear o arquivo para depois move-lo
                        if not arquivo_renomeado == 'ERRO':
                            print('sucesso em renomear o arquivo para o padrao!')
                            
                            if move_arquivo(pasta_origem_script, arquivo_renomeado, criacao_pasta):
                                print(f'Arquivo {arquivo_renomeado} movido com sucesso pra pasta final.')
                                print('')
                                
                            

                    elif status_log == '1':
                        print(f'coleta PGP do equipamento {hostname}-{ip} com timeout.')
                        # agora vamos verificar que tipo de equipamento e vamos trata-lo
                        arquivo_renomeado = renomeia(equipamento=equip, log_bruto=arquivo_log_bruto,pasta_origem=pasta_origem_script, modelo=modelo, hostname=hostname, data_log=data_log)
                        if move_arquivo(pasta_origem_script, arquivo_renomeado, criacao_pasta):
                            print(f'Arquivo {arquivo_renomeado} movido com sucesso pra pasta final.')
                            print('')
                            equipamentos_NOK += f'{hostname}_{data_log} -> (PGP NOK - timeout) ❌&#10;'
                    elif status_log == '2':
                        print(f'coleta PGP do equipamento {hostname}-{ip} sem rota.')
                        # agora vamos verificar que tipo de equipamento e vamos trata-lo
                        arquivo_renomeado = renomeia(equipamento=equip, log_bruto=arquivo_log_bruto, pasta_origem=pasta_origem_script, modelo=modelo, hostname=hostname, data_log=data_log)
                        if move_arquivo(pasta_origem_script, arquivo_renomeado, criacao_pasta):
                            print(f'Arquivo {arquivo_renomeado} movido com sucesso pra pasta final.')
                            print('')
                            equipamentos_NOK += f'{hostname}_{data_log} -> (PGP NOK - sem rota) ❌&#10;'
                    elif status_log == '3':
                        print(f'coleta PGP do equipamento {hostname}-{ip} com conexão recusada.')
                        # agora vamos verificar que tipo de equipamento e vamos trata-lo
                        arquivo_renomeado = renomeia(equipamento=equip, log_bruto=arquivo_log_bruto, pasta_origem=pasta_origem_script, modelo=modelo, hostname=hostname, data_log=data_log)
                        if move_arquivo(pasta_origem_script, arquivo_renomeado, criacao_pasta):
                            print(f'Arquivo {arquivo_renomeado} movido com sucesso pra pasta final.')
                            print('')
                            equipamentos_NOK += f'{hostname}_{data_log} -> (PGP NOK - conexao recusada) ❌&#10;'
                    elif status_log == '4':
                        print(f'coleta PGP do equipamento {hostname}-{ip} com falha na chave.')
                        # agora vamos verificar que tipo de equipamento e vamos trata-lo
                        arquivo_renomeado = renomeia(equipamento=equip, log_bruto=arquivo_log_bruto, pasta_origem=pasta_origem_script, modelo=modelo, hostname=hostname, data_log=data_log)
                        if move_arquivo(pasta_origem_script, arquivo_renomeado, criacao_pasta):
                            print(f'Arquivo {arquivo_renomeado} movido com sucesso pra pasta final.')
                            print('')
                            equipamentos_NOK += f'{hostname}_{data_log} -> (PGP NOK - falha na chave) ❌&#10;'


        else:
            print(f'Erro na aplicação do PGP do equipamento {hostname} de ip: {ip}. erro: {retorno_comando_erro}')

    
    #agora vamos mandar a mensagem pelo bot
    resumo += equipamentos_OK
    resumo += equipamentos_NOK
    resumo += caminho_PGP
    comando_bot_tg = f'{pasta_bot_tg}hub_bot_tg.sh {pasta_bot_tg}lista_mailing_tg.txt "{assunto}" "{resumo}" {pasta_bot_tg}erros_crontab/log_ERRO-DOCKER_BKP.txt'
    comando_montado_tg = "/usr/bin/docker exec -t " + container + " " + comando_bot_tg
    comando_aplicado_tg = subprocess.run(comando_montado_tg, shell=True, capture_output=True)
    #print(comando_aplicado_tg)
    retorno_comando_tg = comando_aplicado_tg.returncode

    if retorno_comando_tg == 0:
        print('Mensagem do telegram enviada com SUCESSO!')
    else:
        print('OCORREU UM ERRO AO ENVIAR A MENSAGEM VIA BOT!')
    
    subprocess.run([f'/usr/bin/docker container stop {container}'], shell=True, capture_output=True)
    print('Container finalizado!')
    
    
    
    print('Fim do script.')

else:
    print(f'Erro ao executar o container: {status_erro}')
