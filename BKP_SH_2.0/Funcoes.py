
import os.path
import shutil
from datetime import datetime

#Pasta de salvamento dos logs do PGP
PASTA_LOG = 'LOG_BKP/'

def pasta_destino(caminho:str) -> str:
    '''

    :param caminho: caminho da pasta que sera verificada e criada
    :return: o caminho completo para OK e ERRO para erro na criacao do diretorio
    '''
    MES_ATUAL = datetime.now().strftime('%B').upper()
    ANO_ATUAL = datetime.now().strftime('%Y')
    DATA_ATUAL = datetime.now().strftime('%d.%m.%Y')


    try:
        if not os.path.exists(f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}'):
            os.makedirs(f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}')
            os.makedirs(f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}/{DATA_ATUAL}')

        if os.path.exists(f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}'):
            if not os.path.exists(f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}/{DATA_ATUAL}'):
                os.makedirs(f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}/{DATA_ATUAL}')

        if os.path.exists(f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}/{DATA_ATUAL}'):
            return f'{caminho}{PASTA_LOG}{MES_ATUAL}-{ANO_ATUAL}/{DATA_ATUAL}/'


    except FileExistsError as error:
        print(f'Nao foi possivel criar a pasta. Erro: {error}')
        return 'ERRO'




def renomeia(**kwargs:str)-> str:
    '''

    :param kwargs:
    pasta_origem -> caminho do arquivo de log bruto corrente
    log_bruto -> arquivo corrente de log bruto
    equipamento -> tipo de equipamento.Ex: CMTS, RTD, etc
    data_log -> data corrente para renomear no padrao
    hostname -> nome do equipamento

    :return: NOME_NOVO se deu tudo certo, ERRO se deu erro
    '''

    # agora vamos verificar que tipo de equipamento e vamos trata-lo
    if kwargs["equipamento"] == 'CMTS':
        # vamos tentar renomear o arquivo e move-lo para a pasta correta
        nome_novo_arquivo = f'{kwargs["pasta_origem"]}{kwargs["modelo"]}_{kwargs["hostname"]}_{kwargs["data_log"]}'
        try:
            os.rename(f'{kwargs["pasta_origem"]}{kwargs["log_bruto"]}',
                      nome_novo_arquivo)

            return nome_novo_arquivo

        except Exception as e:
            print(f'Nao foi possivel renomear o arquivo de log {kwargs["log_bruto"]}. Erro: {e}')
            return 'ERRO'
        finally:
            # mesmo dando erro, quero que continue pra ver se os outros rolam
            pass

    else:
        #se for rtd,swt e etc o nome eh mais simples
        nome_novo_arquivo = f'{kwargs["pasta_origem"]}{kwargs["hostname"]}_{kwargs["data_log"]}'
        try:
            os.rename(f'{kwargs["pasta_origem"]}{kwargs["log_bruto"]}',
                      nome_novo_arquivo)

            return nome_novo_arquivo

        except Exception as e:
            print(f'Nao foi possivel renomear o arquivo de log {kwargs["log_bruto"]}. Erro: {e}')
            return 'ERRO'
        finally:
            # mesmo dando erro, quero que continue pra ver se os outros rolam
            pass
            

def move_arquivo(caminho:str, nome:str, pasta_dia:str) -> bool:
    '''
    
    :param caminho: o caminho base pra mover o arquivo pra pasta de log
    :param nome: nome do arquivo que sera movido
    :return: True pra deu certo e False pra erro ao mover
    '''
    
    pasta_dia = pasta_dia.split('/')
    
    try:
        shutil.move(f'{nome}', f'{caminho}{PASTA_LOG}{pasta_dia[-3]}/{pasta_dia[-2]}')
        return True
    except Exception as e:
        print(f'Nao foi possivel mover o aquivo {nome} para a pasta de destino. Erro: {e}')
        return False
    finally:
        #mesmo dando erro, quero que continue pra ver se os outros rolam
        pass
        

def busca_comando_arquivo(nome_arquivo: str, comandos_procurados: list):
    '''
    ESSA FUNCAO RODA DENTRO DA FUNCAO POSTERIOR PARA VERIFICAR O ARQUIVO EM BUSCA DOS COMANDOS
    :param nome_arquivo: caminho do arquivo a ser verificado
    :param comandos_procurados: lista com os comandos procurados no arquivo do PGP
    :param qtde_comandos_procurados: quantidade dos parametros que sao esperados
    :return: retorna a quantidade de comandos encontrados e quantos sao esperados
    '''
    comandos_contador = 0
    try:
        with open(nome_arquivo, 'r') as log:
            for linha in log:
                if any(comando in linha for comando in comandos_procurados):
                    print(f'comando achado na linha: {linha.strip()}')
                    #valor abaixo eh quantos comandos efetivamente ele achou aplicados
                    comandos_contador += 1

            # valor abaixo eh quantos comandos ele deve verificar de acordo com modelo e PGP
            qtde_criterios_pgp = len(comandos_procurados)
            return comandos_contador, qtde_criterios_pgp

    except OSError:
        print(f'ERRO ao ler arquivo: {nome_arquivo}. O arquivo nao existe ou nao temos permissao de leitura')
        # valor abaixo eh quantos comandos ele deve verificar de acordo com modelo e PGP
        qtde_criterios_pgp = 0
        return comandos_contador, qtde_criterios_pgp
    finally:
        #mesmo dando erro, quero que continue pra ver se os outros rolam
        pass



def valida_PGP(nome_arquivo:str, equipamento:str, modelo:str):
    '''
    NESSA FUNCAO IREI VERIFICAR SE OS COMANDOS PROCURADOS NO PGP ESTAO PRESENTES NOS ARQUIVOS ANALIZADOS
    :param nome_arquivo: caminho do arquivo que sera examinado
    :param equipamento: se CMTS ou RTD e ETC
    :param modelo: VENDOR
    :return: quantidades de comandos verificados
    '''
    if equipamento == 'CMTS':
        if modelo == 'CISCO' or modelo == 'CASA':
            comandos_procurados = ['show running-config']
            #Aqui chamo a funcao anterior para ler o arquivo em busca dos comandos
            comandos_contador, qtde_criteriospgp = busca_comando_arquivo(nome_arquivo, comandos_procurados)
            return comandos_contador, qtde_criteriospgp

        elif modelo == 'ARRIS':
            comandos_procurados = ['show running-config verbose']
            # Aqui chamo a funcao anterior para ler o arquivo em busca dos comandos
            comandos_contador, qtde_criteriospgp = busca_comando_arquivo(nome_arquivo, comandos_procurados)
            return comandos_contador, qtde_criteriospgp


    elif equipamento == 'RTD':
        if modelo == 'CISCO':
            comandos_procurados = ['show running-config',
                                   'show running-config interface bvi 2',
                                   'show access-lists  ACL_NAME',
                                   'show bgp ipv4 unicast summary | include ISP_NUMBER',
                                   'show bgp',
                                   'show running-config interface']

            # Aqui chamo a funcao anterior para ler o arquivo em busca dos comandos
            comandos_contador, qtde_criteriospgp = busca_comando_arquivo(nome_arquivo, comandos_procurados)
            return comandos_contador, qtde_criteriospgp

        elif modelo == 'HUAWEI':
            comandos_procurados = ['display current-configuration',
                                   'display acl name',
                                   'display nat bandwidth',
                                   'display nat statistics payload',
                                   'display nat address-usage instance CGNAT-POL_NAME address-group 1',
                                   'display curre | in nat instance CGNAT',
                                   'display bgp peer | include ISP_NUMBER',
                                   'display bgp routing-table',
                                   'display current-configuration interface']

            # Aqui chamo a funcao anterior para ler o arquivo em busca dos comandos
            comandos_contador, qtde_criteriospgp = busca_comando_arquivo(nome_arquivo, comandos_procurados)
            return comandos_contador, qtde_criteriospgp

        elif modelo == 'ZTE':
            comandos_procurados = ['show running-config',
                                   'show running-config ipv4-acl all | begin TRAFFIC-SECURITY-LINKs-IPv4',
                                   'show bgp ipv4 unicast summary | include ISP_NUMBER',
                                   'show bgp ipv4 unicast neighbor out',
                                   'show running-config-interface']

            # Aqui chamo a funcao anterior para ler o arquivo em busca dos comandos
            comandos_contador, qtde_criteriospgp = busca_comando_arquivo(nome_arquivo, comandos_procurados)
            return comandos_contador, qtde_criteriospgp

        elif modelo == 'ALCATEL':
            comandos_procurados = ['environment no more',
                                   'admin display-config']

            # Aqui chamo a funcao anterior para ler o arquivo em busca dos comandos
            comandos_contador, qtde_criteriospgp = busca_comando_arquivo(nome_arquivo, comandos_procurados)
            return comandos_contador, qtde_criteriospgp
            
    elif equipamento == 'STW':
        if modelo == 'CISCO':
            comandos_procurados = ['show running-config']
            # Aqui chamo a funcao anterior para ler o arquivo em busca dos comandos
            comandos_contador, qtde_criteriospgp = busca_comando_arquivo(nome_arquivo, comandos_procurados)
            return comandos_contador, qtde_criteriospgp
            
            