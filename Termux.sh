#!/data/data/com.termux/files/usr/bin/bash

# ===== SILENCIAR ERROS =====
exec 2>/dev/null

# ===== CONFIG =====
OWNER_PIN="7865"

VALID_PINS=(
"01" "2002" "9321" "3469" "9397" "2773" "83872"
"02773" "2937" "15838" "205273" "2862" "7262" "62835"
)

# ===== CORES =====
PURPLE='\033[1;35m'
LIGHT='\033[0;35m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m'

# ===== BANNER =====
banner() {
clear
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════╗"
echo "║     PASSADOR DE REPLAY FUSION        ║"
echo "╠══════════════════════════════════════╣"
echo "║        SISTEMA PREMIUM TERMUX        ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"
}

# ===== LOADING =====
loading_ultra() {
for ((i=0;i<=100;i++)); do
  printf "\r${PURPLE}Carregando... %d%%%s" "$i" "${NC}"
  sleep 0.01
done
echo ""
}

# ===== LOGIN =====
login() {
tentativas=3

while [ $tentativas -gt 0 ]; do
  banner
  echo -e "${WHITE}Digite o código:${NC}"
  read pin

  if [ "$pin" = "$OWNER_PIN" ]; then
    return
  fi

  for p in "${VALID_PINS[@]}"; do
    if [ "$pin" = "$p" ]; then
      return
    fi
  done

  tentativas=$((tentativas - 1))
  echo -e "${RED}PIN inválido! Tentativas: $tentativas${NC}"
  sleep 1
done

exit 1
}

# ===== ADB =====
check_adb() { command -v adb >/dev/null 2>&1; }
check_device() { adb devices | sed -n '2p' | grep -q "device"; }

# ===== PATHS =====
SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
DST="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

# ===== FUNÇÕES =====
copy_local() {
  mkdir -p "$DST"

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && cp -f "$BIN" "$DST"/ >/dev/null 2>&1
  [ -n "$JSON" ] && cp -f "$JSON" "$DST"/ >/dev/null 2>&1

  [ -n "$JSON" ] && sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"1.123.1"/' "$DST/$(basename "$JSON")" >/dev/null 2>&1

  loading_ultra
}

send_usb() {
  check_adb || return
  check_device || return

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && adb push "$BIN" "$DST"/ >/dev/null 2>&1
  [ -n "$JSON" ] && adb push "$JSON" "$DST"/ >/dev/null 2>&1

  loading_ultra
}

wifi() {
  echo "Conectar ADB Wi-Fi"
  read -p "IP: " ip
  read -p "PORTA: " port

  adb connect "$ip:$port" >/dev/null 2>&1

  echo "Conectado (ou tentativa feita)"
  sleep 1
}

# ===== MENU =====
menu() {
  banner
  echo -e "${LIGHT}1 - Passar replay para FF normal${NC}"
  echo -e "${LIGHT}2 - Passador para outro dispositivo${NC}"
  echo -e "${LIGHT}3 - Conectar depuração Wi-Fi${NC}"
  echo -e "${LIGHT}0 - Sair${NC}"
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
    3) wifi ;;
    0) exit ;;
    *) echo "Opção inválida"; sleep 1 ;;
  esac
done
