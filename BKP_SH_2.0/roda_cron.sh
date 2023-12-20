#!/bin/bash

CAMINHO="/home/$HOME/BKP_SH/"
CAMINHO_SAVE="/home/$HOME/BKP_SH/LOG_BKP"
CAMINHO_LOG="/home/$HOME/erros_crontab"
ARQUIVO_LOG="log_ERRO-DOCKER_BKP.txt"

cd $CAMINHO
$CAMINHO/venv/bin/python ignicao.py > log_atividade.txt 2> $CAMINHO_LOG/$ARQUIVO_LOG && mv log_atividade.txt $CAMINHO_SAVE/$(date +%^B)-$(date +%Y)/$(date +%d.%m.%Y)/log_atividade.txt
