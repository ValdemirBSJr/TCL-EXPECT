# Author: Valdemir Bezerra

import pandas as pd
from datetime import datetime
import os.path

#CONSTANTES DE DATA
MES_ATUAL = datetime.now().strftime('%B')
ANO_ATUAL = datetime.now().strftime('%Y')
DATA_ATUAL = datetime.now().strftime('%d.%m.%Y')
DATA_NOME_ARQUIVO = datetime.now().strftime('%d%m%Y')

#funcao para verificar se a pasta existe e vamos abrir os arquivos
def pega_pasta_arquivo(DATA_ATUAL:str, MES_ATUAL:str, ANO_ATUAL:str, caminho_testado:str) -> str:

    caminho_construtor = r'/home/SUA_HOME/BKP_SRV/' + caminho_testado.strip() + r'/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/'

    if os.path.isdir(caminho_construtor):
        retorno = caminho_construtor
    else:
        retorno = ''

    return retorno




if __name__ == '__main__':

    #verifica se o caminho existe se existir tem que tentar ler os arquivos
    retorno_pasta_rule = pega_pasta_arquivo(DATA_ATUAL, MES_ATUAL, ANO_ATUAL, r'bkp_rule')

    '''
    verifica se uma pasta atual existe, caso sim então começamos os trabalhos
    '''
    if len(retorno_pasta_rule) != 0:

        print(retorno_pasta_rule)
        try:
            with open(r'/home/SUA_HOME/BKP_SRV/servidores.txt') as arquivo:
                contador =0

                for linha in arquivo:
                    # se a linha começar com um # é comantario entao ignora
                    # populando os dataframes que vamos trabalhar
                    if not linha.strip().startswith('#'):
                        routing = pd.read_csv(r'/home/SUA_HOME/BKP_SRV/bkp_routing/' + MES_ATUAL + '-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'routing-' + linha.strip() + r'-' + DATA_NOME_ARQUIVO + r'.csv', skiprows=35, sep=',')
                        routing = routing.iloc[:-2, :]
                        rules = pd.read_csv(r'/home/SUA_HOME/BKP_SRV/bkp_rule/' + MES_ATUAL + '-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'rule-' + linha.strip() + r'-' + DATA_NOME_ARQUIVO + r'.csv', skiprows=35, sep=',')
                        #retira as 3 ultimas linhas
                        rules = rules.iloc[:-2, :]
                        relate = pd.read_csv(r'/home/SUA_HOME/BKP_SRV/bkp_relate_rule/' + MES_ATUAL + '-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'relate-' + linha.strip() + r'-' + DATA_NOME_ARQUIVO + r'.csv', skiprows=35, sep=',')
                        relate = relate.iloc[:-2, :]
                        template = pd.read_csv(r'/home/SUA_HOME/BKP_SRV/bkp_template/' + MES_ATUAL + '-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'template-' + linha.strip() + r'-' + DATA_NOME_ARQUIVO + r'.csv', skiprows=35, sep=',')
                        template = template.iloc[:-2, :]
                        prefix6 = pd.read_csv(r'/home/SUA_HOME/BKP_SRV/bkp_v6/' + MES_ATUAL + '-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'prefix6-' + linha.strip() + r'-' + DATA_NOME_ARQUIVO + r'.csv', skiprows=35, sep=',')
                        prefix6 = prefix6.iloc[:-2, :]
                        rule6 = pd.read_csv(r'/home/SUA_HOME/BKP_SRV/bkp_v6/' + MES_ATUAL + '-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'rule6-' + linha.strip() + r'-' + DATA_NOME_ARQUIVO + r'.csv', skiprows=35, sep=',')
                        rule6 = rule6.iloc[:-2, :]

                        #string que receberá o resultado dos construtores
                        comando_ipcli = ''

                        # Primeiramente construímos a arvore principal das classes
                        rules_arvore_primaria = rules[rules['NAME'].str.contains('Group')]
                        for superclasse in rules_arvore_primaria.itertuples():
                            #se a criteria for vazia, nao acrescenta
                            comando_ipcli += f'add RULE "{superclasse.NAME}" ipfrom {superclasse.IPFROM} ipto {superclasse.IPTO} DISABLE {str(superclasse.DISABLED).upper()} SUBNETMASK "{superclasse.SUBNETMASK}" DEFAULTGW "{superclasse.DEFAULTGW}" LEASETIME {int(superclasse.LEASETIME)}'

                            if type(superclasse.CRITERIA) == str:
                                comando_ipcli += f' CRITERIA {superclasse.CRITERIA}\n'
                            else:
                                comando_ipcli += f'\n'


                        comando_ipcli += f'\n'

                        #agora vamos pegar o nome dos CMTS que estão no csv routing e iterar sobre eles trazendo as classes
                        for cmts in routing.itertuples():
                            # filtro todos os valores que tem o nome do CMTS que estamos iterando
                            rules_CMTS_todas = rules[rules['NAME'].str.contains(cmts.NAME)]
                            # abaixo, ordeno o retorno pelo indice parentlookpkey para que as superclasses sejam geradas primeiro e nao de erro de RULE inexistente
                            rules_CMTS_todas = rules_CMTS_todas.sort_values(by=['PARENTLOOKUPKEY'])

                            #percorre todas as rules levantadas pelo nome do CMTS e cria cada linha de comando de criacao da classe
                            for rules_CMTS in rules_CMTS_todas.itertuples():
                                comando_ipcli += f'add RULE "{rules_CMTS.NAME}" ipfrom {rules_CMTS.IPFROM} ipto {rules_CMTS.IPTO} DISABLED {str(rules_CMTS.DISABLED).upper()} SUBNETMASK "{rules_CMTS.SUBNETMASK}" DEFAULTGW "{rules_CMTS.DEFAULTGW}" LEASETIME {int(rules_CMTS.LEASETIME)}'

                                #se a criteria nao for vazia acrescenta
                                if type(rules_CMTS.CRITERIA) == str:
                                    comando_ipcli += f' CRITERIA {rules_CMTS.CRITERIA}\n'
                                else:
                                    comando_ipcli += f'\n'

                                # pega a relate rule associadas, constroe e poe na string
                                # Converte de float para int e depois string e consulta pelo parentlookey, depois
                                # pega o valor ao lado na linha que é o que queremos
                                relate_rule_index_CMTS = relate.loc[relate['LOOKUPKEY'] == str(int(rules_CMTS.PARENTLOOKUPKEY))]
                                relate_rule_CMTS = relate_rule_index_CMTS['NAME'].iloc[0]
                                comando_ipcli += f'RELATE RULE "{relate_rule_CMTS}" RULE "{rules_CMTS.NAME}"\n'

                                #adiciono os templates, caso tenham
                                if rules_CMTS.TEMPLATELOOKUPKEY != 0:
                                    relate_template_rule_index = template.loc[template['LOOKUPKEY'] == str(int(rules_CMTS.TEMPLATELOOKUPKEY))]
                                    relate_template_rule = relate_template_rule_index['NAME'].iloc[0]
                                    comando_ipcli += f'RELATE RULE "{rules_CMTS.NAME}" TEMPLATE "{relate_template_rule}"\n'

                                # agora crio um construtor especial para as classes CPE 4k
                                # se ela tiver as palavras 4K e CPE sem HDTV e com a criteria tipo float(vazio) acrescente os valores especiais
                                classe_cpe_4k = str(rules_CMTS.NAME)
                                if classe_cpe_4k.find('4K') != -1 and classe_cpe_4k.find('CPE') != -1 and classe_cpe_4k.find('HDTV') == -1 and type(rules_CMTS.CRITERIA) == float:
                                    comando_ipcli += f'MODIFY RULE "{classe_cpe_4k}"\n'

                                    nome_classe_lista = classe_cpe_4k.split(' ')
                                    barra_ip = nome_classe_lista[3]
                                    ip_4k = barra_ip.split('.')
                                    lista_ip_4k = [ip_4k[0], ip_4k[1], ip_4k[2], '1']
                                    ip_4k = '.'.join(lista_ip_4k)

                                    rede_op = linha.strip().split('.')

                                    # se a operacao tiver o segundo octeto igual a 123(NTL e TSA) será /25 da operacao
                                    if rede_op[1] == '123':
                                        barra_da_classe_op = '0/25'
                                    else:
                                        barra_da_classe_op = '0/24'

                                    lista_rede_op = [rede_op[0], rede_op[1], rede_op[2], barra_da_classe_op]
                                    rede_op = '.'.join(lista_rede_op)

                                    comando_ipcli += f'add DHCPV4OPTION 121 DATA {ip_4k}:10.0.0.0/8,{ip_4k}:201.6.0.0/24,{ip_4k}:{rede_op}\n'
                                    comando_ipcli += f'save\n'
                                    comando_ipcli += f'exit\n'

                                comando_ipcli += f'\n'

                            #construindo as routingelements dos CMTS
                            #aqui o ipcli torna a leitura com pandas praticamente impossível. Iremos tratar linha a linha
                            try:
                                with open(r'/home/SUA_HOME/BKP_SRV/bkp_routing/' + MES_ATUAL + '-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'routing-' + linha.strip() + r'-' + cmts.NAME + r'-' + DATA_NOME_ARQUIVO + r'.csv') as arquivo_routing:
                                    contador_routing = 0
                                    description = ''

                                    for linha_routing in arquivo_routing:
                                        #se a linha nao for espaço e se começar com gtw, network ou description, atende nossos criterios
                                        if not linha_routing.isspace() and (linha_routing.strip().startswith('GATEWAY:') or linha_routing.strip().startswith('NETWORK:') or linha_routing.strip().startswith('DESCRIPTION:')):
                                            #se a linha comecar com description pega o nome cmts pra construir a partir dela, se houver description se nao tiver nao bota
                                            if linha_routing.strip().startswith('DESCRIPTION:'):
                                                description = linha_routing.split(' ')
                                                description = description[1]
                                                if len(description.strip()) > 0:
                                                    comando_ipcli += f'add ROUTINGELEMENT {cmts.NAME} DESCRIPTION "{description.strip()}" DOCSISMAJORVERSION 3 DOCSISMINORVERSION 1 AUTHKEY {cmts.NAME}!@#B@nd@L4rg4#$ CONFIRMAUTHKEY {cmts.NAME}!@#B@nd@L4rg4#$ MANAGEMENTIP {cmts.MANAGEMENTIP}\n'
                                                    comando_ipcli += f'modify ROUTINGELEMENT {cmts.NAME}\n'
                                                else:
                                                    comando_ipcli += f'add ROUTINGELEMENT {cmts.NAME}  DOCSISMAJORVERSION 3 DOCSISMINORVERSION 1 AUTHKEY {cmts.NAME}!@#B@nd@L4rg4#$ CONFIRMAUTHKEY {cmts.NAME}!@#B@nd@L4rg4#$ MANAGEMENTIP {cmts.MANAGEMENTIP}\n'
                                                    comando_ipcli += f'modify ROUTINGELEMENT {cmts.NAME}\n'

                                            #ser a linha nao for description, eh classe se for impar o contador eh gtw senao eh redes
                                            #caso a rede seja vazia, continua com o proximo gtw na linha abaixo
                                            if not linha_routing.strip().startswith('DESCRIPTION:'):
                                                rede_routing = linha_routing.split(' ')
                                                rede_routing = rede_routing[2]
                                                if len(rede_routing.strip()) > 0 and not contador_routing % 2 ==0:
                                                    comando_ipcli += f'add GATEWAYLIST {rede_routing.strip()}'
                                                if len(rede_routing.strip()) > 0 and contador_routing % 2 ==0:
                                                    network = rede_routing.strip()
                                                    network = network.replace(':FALSE', '')
                                                    comando_ipcli += f' NETWORK {network}\n'
                                                if len(rede_routing.strip()) == 0 and contador_routing % 2 == 0:
                                                    comando_ipcli += f'\n'

                                            contador_routing += 1

                                    comando_ipcli += f'save\nexit\n\n'

                            except FileNotFoundError:
                                print(f'O arquivo de routing do CONCENTRADOR: {cmts.NAME} não existe ou não está disponível.')


                        #classes V4 Construidas! Agora vamos para as V6...

                        for rule_v6 in rule6.itertuples():
                            comando_ipcli += f'add RULEv6 "{rule_v6.NAME}" DESCRIPTION "{rule_v6.DESCRIPTION}" DISABLED {str(rule_v6.DISABLED).upper()} NONSEQUENTIAL {str(rule_v6.NONSEQUENTIAL).upper()} PREFERREDLIFETIME {int(rule_v6.PREFERREDLIFETIME)} VALIDLIFETIME {int(rule_v6.VALIDLIFETIME)} RAPIDCOMMIT {str(rule_v6.RAPIDCOMMIT).upper()} STARTIPADDRESS "{rule_v6.STARTIPADDRESS}" ENDIPADDRESS "{rule_v6.ENDIPADDRESS}" CRITERIA "{rule_v6.CRITERIA}"\n'

                        for prefix_v6 in prefix6.itertuples():
                            comando_ipcli += f'add PREFIXDELEGATIONRULEV6 "{prefix_v6.NAME}" DISABLED {str(prefix_v6.DISABLED).upper()} RAPIDCOMMIT TRUE PREFERREDLIFETIME {int(prefix_v6.PREFERREDLIFETIME)} VALIDLIFETIME {int(prefix_v6.VALIDLIFETIME)} DESCRIPTION "{prefix_v6.DESCRIPTION}" PREFIX "{prefix_v6.PREFIX}" PREFIXLENGTH "{int(prefix_v6.PREFIXLENGTH)}" DEFAULTPREFIXLENGTH {int(prefix_v6.DEFAULTPREFIXLENGTH)} CRITERIA "{prefix_v6.CRITERIA}"\n'



                        #saida de tudo
                        print(comando_ipcli)

                        '''verifica se existe uma pasta Mes-ANO para salvar dentro,
                           Caso não exista, cria uma. caso exista, salva dentro 
                        '''
                        try:
                            if not os.path.exists(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL):
                                os.makedirs(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL)
                                os.makedirs(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL)
                                with open(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'script-' + linha.strip() + r'.txt', 'w') as script:
                                    script.write(comando_ipcli)

                            if not os.path.exists(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL):
                                os.makedirs(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL)
                                with open(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'script-' + linha.strip() + r'.txt', 'w') as script:
                                    script.write(comando_ipcli)
                            if os.path.exists(r'/SUA_HOME/valdemir/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL):
                                with open(r'/home/SUA_HOME/BKP_SRV/bkp_scripts/' + MES_ATUAL + r'-' + ANO_ATUAL + r'/' + DATA_ATUAL + r'/' + r'script-' + linha.strip() + r'.txt', 'w') as script:
                                    script.write(comando_ipcli)

                        except FileExistsError as error:
                            print(f'Não foi possível criar a pasta. Erro: {error}')




                        contador += 1




        except FileNotFoundError as error:
            print(f'Arquivo servidores.txt não encontrado. Erro: {error}')

    else:
        print(f'pasta {retorno_pasta_rule} inexistente. Não temos uma pasta {DATA_ATUAL} para trabalhar.')
