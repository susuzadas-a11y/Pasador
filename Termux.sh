#!/data/data/com.termux/files/usr/bin/bash

# ===== CONFIG LOGIN =====
PIN_CORRETO="7865"
BLOCK_FILE="$HOME/.fusion_block"

get_id() {
  ID=$(getprop ro.serialno 2>/dev/null)
  [ -z "$ID" ] && ID=$(settings get secure android_id 2>/dev/null)
  [ -z "$ID" ] && ID=$(uname -n)
  echo "$ID"
}

login() {
  clear
  echo "======== LOGIN ========"

  DEVICE_ID=$(get_id)

  if [ -f "$BLOCK_FILE" ]; then
    BLOCK_ID=$(cat "$BLOCK_FILE")
    if [ "$BLOCK_ID" = "$DEVICE_ID" ]; then
      echo "DISPOSITIVO BLOQUEADO!"
      exit 1
    fi
  fi

  tentativas=3

  while [ $tentativas -gt 0 ]; do
    read -s -p "Digite o código: " pin
    echo ""

    if [ "$pin" = "$PIN_CORRETO" ]; then
      echo "✔ Acesso liberado!"
      sleep 1
      return
    else
      tentativas=$((tentativas - 1))
      echo "✖ Código errado! Restam: $tentativas"
    fi
  done

  echo "$DEVICE_ID" > "$BLOCK_FILE"
  echo "DISPOSITIVO BLOQUEADO!"
  sleep 2
  exit 1
}

# ===== CORES =====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# ===== VISUAL =====
loading() {
  echo -ne "${CYAN}Processando"
  for i in {1..5}; do
    echo -ne "."
    sleep 0.3
  done
  echo -e "${NC}"
}

bar() {
  echo -ne "${CYAN}["
  for i in {1..20}; do
    echo -ne "#"
    sleep 0.05
  done
  echo -e "]${NC}"
}

# ===== VERIFICAÇÕES =====
check_adb() {
  command -v adb >/dev/null 2>&1 || return 1
}

check_device() {
  adb devices | sed -n '2p' | grep -q "device"
}

# ===== CAMINHOS =====
SRC_DIR="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
DST_DIR="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

# ===== FUNÇÕES =====
copy_local() {
  clear
  echo -e "${YELLOW}Copiando replay local...${NC}"
  loading

  [ ! -d "$SRC_DIR" ] && echo "Erro origem!" && sleep 2 && return

  mkdir -p "$DST_DIR"

  BIN=$(ls -t "$SRC_DIR"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC_DIR"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && cp -f "$BIN" "$DST_DIR"/
  [ -n "$JSON" ] && cp -f "$JSON" "$DST_DIR"/

  [ -n "$JSON" ] && sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"1.123.1"/' "$DST_DIR/$(basename "$JSON")"

  bar
  echo -e "${GREEN}✔ Sucesso!${NC}"
  read -p "ENTER para voltar..."
}

send_usb() {
  clear
  echo -e "${YELLOW}Enviando via USB...${NC}"
  loading

  if ! check_adb; then
    echo -e "${RED}ADB não instalado!${NC}"
    sleep 2
    return
  fi

  if ! check_device; then
    echo -e "${RED}Sem dispositivo!${NC}"
    sleep 2
    return
  fi

  BIN=$(ls -t "$SRC_DIR"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC_DIR"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && adb push "$BIN" "$DST_DIR"/
  [ -n "$JSON" ] && adb push "$JSON" "$DST_DIR"/

  bar
  echo -e "${GREEN}✔ Enviado!${NC}"
  read -p "ENTER para voltar..."
}

connect_wifi() {
  clear
  echo -e "${YELLOW}Conectar Wi-Fi${NC}"

  read -p "IP: " ip
  read -p "PORTA: " port

  loading
  adb connect $ip:$port

  [ $? -eq 0 ] && echo -e "${GREEN}✔ Conectado!${NC}" || echo -e "${RED}Erro!${NC}"

  read -p "ENTER para voltar..."
}

# ===== MENU =====
menu() {
  clear
  echo -e "${CYAN}"
  echo "================================"
  echo "   PASSADOR DE REPLAY FUSION"
  echo "================================"
  echo -e "${NC}"
  echo "1 - Copiar replay"
  echo "2 - Enviar USB"
  echo "3 - Conectar Wi-Fi"
  echo "0 - Sair"
  echo ""
  read -p "Escolha: " op
}

# ===== EXECUÇÃO =====
login

while true; do
  menu
  case $op in
    1) copy_local ;;
    2) send_usb ;;
    3) connect_wifi ;;
    0) exit ;;
    *) echo "Opção inválida"; sleep 1 ;;
  esac
done
