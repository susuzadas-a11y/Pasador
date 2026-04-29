#!/data/data/com.termux/files/usr/bin/bash

# ===== CONFIG =====
OWNER_PIN="7865"
BLOCK_FILE="$HOME/.fusion_block"
USED_PINS="$HOME/.fusion_used_pins"

VALID_PINS=(
"01" "2002" "9321" "3469" "9397" "2773" "83872"
"02773" "2937" "15838" "205273" "2862" "7262" "62835"
)

# ===== GERAR ID ÚNICO =====
get_id() {
  ID=$(getprop ro.serialno 2>/dev/null)
  [ -z "$ID" ] && ID=$(settings get secure android_id 2>/dev/null)
  [ -z "$ID" ] && ID=$(uname -n)
  echo "$ID"
}

DEVICE_ID=$(get_id)

# ===== VERIFICA BLOQUEIO =====
if [ -f "$BLOCK_FILE" ]; then
  [ "$(cat "$BLOCK_FILE")" = "$DEVICE_ID" ] && echo "DISPOSITIVO BLOQUEADO!" && exit 1
fi

# ===== LOGIN =====
login() {
  tentativas=3

  while [ $tentativas -gt 0 ]; do
    clear
    echo "======== LOGIN ========"

    read -s -p "Digite o código: " pin
    echo ""

    # ===== DONO =====
    if [ "$pin" = "$OWNER_PIN" ]; then
      echo "✔ Acesso dono liberado!"
      sleep 1
      return
    fi

    # ===== PIN 15 DIAS =====
    for p in "${VALID_PINS[@]}"; do
      if [ "$pin" = "$p" ]; then

        # verifica se já foi usado
        if [ -f "$USED_PINS" ]; then
          if grep -q "$pin" "$USED_PINS"; then
            echo "PIN já utilizado!"
            sleep 2
            exit 1
          fi
        fi

        # salva PIN usado com ID e data
        NOW=$(date +%s)
        echo "$pin:$DEVICE_ID:$NOW" >> "$USED_PINS"

        echo "✔ Acesso liberado (15 dias)"
        sleep 1
        return
      fi
    done

    tentativas=$((tentativas - 1))
    echo "✖ Código errado! Restam: $tentativas"
    sleep 1
  done

  echo "$DEVICE_ID" > "$BLOCK_FILE"
  echo "DISPOSITIVO BLOQUEADO!"
  sleep 2
  exit 1
}

# ===== VERIFICA EXPIRAÇÃO =====
check_expiration() {
  [ ! -f "$USED_PINS" ] && return

  NOW=$(date +%s)

  while IFS=: read -r pin id data; do
    if [ "$id" = "$DEVICE_ID" ]; then
      DIAS=$(( (NOW - data) / 86400 ))
      if [ "$DIAS" -ge 15 ]; then
        echo "Licença expirada!"
        exit 1
      fi
    fi
  done < "$USED_PINS"
}

# ===== CORES =====
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# ===== VISUAL =====
loading() {
  echo -ne "${CYAN}Processando"
  for i in {1..5}; do echo -ne "."; sleep 0.3; done
  echo -e "${NC}"
}

bar() {
  echo -ne "${CYAN}["
  for i in {1..20}; do echo -ne "#"; sleep 0.03; done
  echo -e "]${NC}"
}

# ===== VERIFICAÇÕES =====
check_adb() { command -v adb >/dev/null 2>&1; }
check_device() { adb devices | sed -n '2p' | grep -q "device"; }

# ===== CAMINHOS =====
SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
DST="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

# ===== FUNÇÕES =====
copy_local() {
  clear
  echo -e "${YELLOW}Copiando replay...${NC}"
  loading

  mkdir -p "$DST"

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && cp -f "$BIN" "$DST"/
  [ -n "$JSON" ] && cp -f "$JSON" "$DST"/

  [ -n "$JSON" ] && sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"1.123.1"/' "$DST/$(basename "$JSON")"

  bar
  echo -e "${GREEN}✔ Sucesso!${NC}"
  read -p "ENTER..."
}

send_usb() {
  clear
  echo -e "${YELLOW}Enviando USB...${NC}"
  loading

  if ! check_adb; then echo "ADB não instalado"; sleep 2; return; fi
  if ! check_device; then echo "Sem dispositivo"; sleep 2; return; fi

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && adb push "$BIN" "$DST"/
  [ -n "$JSON" ] && adb push "$JSON" "$DST"/

  bar
  echo -e "${GREEN}✔ Enviado!${NC}"
  read -p "ENTER..."
}

wifi() {
  clear
  read -p "IP: " ip
  read -p "PORTA: " port
  adb connect $ip:$port
  read -p "ENTER..."
}

menu() {
  clear
  echo -e "${CYAN}=== FUSION REPLAY ===${NC}"
  echo "1 - Copiar"
  echo "2 - USB"
  echo "3 - Wi-Fi"
  echo "0 - Sair"
  read -p "> " op
}

# ===== EXECUÇÃO =====
login
check_expiration

while true; do
  menu
  case $op in
    1) copy_local ;;
    2) send_usb ;;
    3) wifi ;;
    0) exit ;;
    *) ;;
  esac
done
