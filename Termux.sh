#!/bin/bash

clear

# cores
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# loading
loading() {
  echo -ne "${CYAN}Processando"
  for i in {1..5}; do
    echo -ne "."
    sleep 0.3
  done
  echo -e "${NC}"
}

# barra
bar() {
  echo -ne "${BLUE}["
  for i in {1..20}; do
    echo -ne "#"
    sleep 0.05
  done
  echo -e "]${NC}"
}

# verificar adb
check_adb() {
  command -v adb >/dev/null 2>&1 || {
    echo -e "${RED}ADB não instalado!${NC}"
    exit 1
  }
}

# verificar conexão
check_device() {
  DEV=$(adb devices | sed -n '2p' | awk '{print $1}')
  [ -z "$DEV" ] && return 1 || return 0
}

menu() {
  clear
  echo -e "${CYAN}"
  echo "======================================="
  echo "   PASSADOR DE REPLAY FUSION CHEATERS"
  echo "======================================="
  echo -e "${NC}"
  echo "1 - Copiar replay (local)"
  echo "2 - Enviar replay (USB)"
  echo "3 - Parear dispositivo (Wi-Fi)"
  echo "0 - Sair"
  echo ""
  read -p "Escolha: " op
}

while true; do
menu

case $op in

1)
(
SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
DST="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

clear
echo -e "${YELLOW}Copiando localmente...${NC}"
loading

[ -d "$SRC" ] || exit 1
mkdir -p "$DST"

BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

[ -n "$BIN" ] && cp -f "$BIN" "$DST"/
[ -n "$JSON" ] && cp -f "$JSON" "$DST"/

[ -n "$JSON" ] && sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"1.123.1"/' "$DST/$(basename "$JSON")"

bar
echo -e "${GREEN}✔ Concluído com sucesso!${NC}"
sleep 2
) > /dev/null 2>&1
;;

2)
(
clear
echo -e "${YELLOW}Enviando via USB...${NC}"
loading

check_adb

if ! check_device; then
  echo -e "${RED}Dispositivo NÃO conectado!${NC}"
  sleep 2
  exit 1
fi

SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"

BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

[ -n "$BIN" ] && adb push "$BIN" "/sdcard/Android/data/com.dts.freefireth/files/MReplays/"
[ -n "$JSON" ] && adb push "$JSON" "/sdcard/Android/data/com.dts.freefireth/files/MReplays/"

bar
echo -e "${GREEN}✔ Enviado com sucesso!${NC}"
sleep 2
) > /dev/null 2>&1
;;

3)
clear
echo -e "${YELLOW}Pareamento via Wi-Fi${NC}"
echo ""
read -p "IP do dispositivo: " ip
read -p "Porta (ex: 5555): " port

loading

adb connect $ip:$port > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✔ Conectado com sucesso!${NC}"
else
  echo -e "${RED}Erro ao conectar!${NC}"
fi

sleep 2
;;

0)
exit 0
;;

*)
echo -e "${RED}Opção inválida!${NC}"
sleep 1
;;

esac
done
