#!/data/data/com.termux/files/usr/bin/bash

# ===== CONFIG =====
OWNER_PIN="7865"
BLOCK_FILE="$HOME/.fusion_block"
USED_PINS="$HOME/.fusion_used_pins"

VALID_PINS=(
"01" "2002" "9321" "3469" "9397" "2773" "83872"
"02773" "2937" "15838" "205273" "2862" "7262" "62835"
)

# ===== CORES =====
PURPLE='\033[1;35m'
LIGHT='\033[0;35m'
WHITE='\033[1;37m'
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

# ===== LOADING ULTRA =====
loading_ultra() {
  for ((i=0;i<=100;i++)); do
    done=$((i/2))
    left=$((50-done))

    bar_done=$(printf "%0.s#" $(seq 1 $done))
    bar_left=$(printf "%0.s " $(seq 1 $left))

    if (( i % 2 == 0 )); then
      color="\033[1;35m"
    else
      color="\033[0;35m"
    fi

    if [ $i -lt 30 ]; then
      msg="Iniciando sistema..."
    elif [ $i -lt 60 ]; then
      msg="Carregando módulos..."
    elif [ $i -lt 90 ]; then
      msg="Processando dados..."
    else
      msg="Finalizando..."
    fi

    printf "\r${color}[%s%s] %d%% | %s\033[0m" "$bar_done" "$bar_left" "$i" "$msg"
    sleep 0.02
  done
  echo ""
}

# ===== ID =====
get_id() {
  ID=$(getprop ro.serialno 2>/dev/null)
  [ -z "$ID" ] && ID=$(settings get secure android_id 2>/dev/null)
  [ -z "$ID" ] && ID=$(uname -n)
  echo "$ID"
}

DEVICE_ID=$(get_id)

# ===== BLOQUEIO =====
if [ -f "$BLOCK_FILE" ]; then
  [ "$(cat "$BLOCK_FILE")" = "$DEVICE_ID" ] && exit 1
fi

# ===== LOGIN =====
login() {
  tentativas=3

  while [ $tentativas -gt 0 ]; do
    banner
    echo -e "${WHITE}Digite o código:${NC}"
    read pin

    # DONO
    if [ "$pin" = "$OWNER_PIN" ]; then
      return
    fi

    # PINS 15 DIAS
    for p in "${VALID_PINS[@]}"; do
      if [ "$pin" = "$p" ]; then

        if [ -f "$USED_PINS" ] && grep -q "^$pin:" "$USED_PINS"; then
          exit 1
        fi

        NOW=$(date +%s)
        echo "$pin:$DEVICE_ID:$NOW" >> "$USED_PINS"
        return
      fi
    done

    tentativas=$((tentativas - 1))
  done

  echo "$DEVICE_ID" > "$BLOCK_FILE"
  exit 1
}

# ===== EXPIRAÇÃO =====
check_expiration() {
  [ ! -f "$USED_PINS" ] && return
  NOW=$(date +%s)

  while IFS=: read -r pin id data; do
    if [ "$id" = "$DEVICE_ID" ]; then
      DIAS=$(( (NOW - data) / 86400 ))
      [ "$DIAS" -ge 15 ] && exit 1
    fi
  done < "$USED_PINS"
}

# ===== ADB =====
check_adb() { command -v adb >/dev/null 2>&1; }
check_device() { adb devices | sed -n '2p' | grep -q "device"; }

# ===== PATHS =====
SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
DST="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

# ===== FUNÇÕES =====
copy_local() {
(
  mkdir -p "$DST"

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && cp -f "$BIN" "$DST"/
  [ -n "$JSON" ] && cp -f "$JSON" "$DST"/

  [ -n "$JSON" ] && sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"1.123.1"/' "$DST/$(basename "$JSON")"

) > /dev/null 2>&1

loading_ultra
}

send_usb() {
(
  check_adb || exit 1
  check_device || exit 1

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  [ -n "$BIN" ] && adb push "$BIN" "$DST"/
  [ -n "$JSON" ] && adb push "$JSON" "$DST"/

) > /dev/null 2>&1

loading_ultra
}

wifi() {
(
  read -p "IP: " ip
  read -p "PORTA: " port
  adb connect $ip:$port
) > /dev/null 2>&1
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
check_expiration

while true; do
  menu
  case $op in
    1) copy_local ;;
    2) send_usb ;;
    3) wifi ;;
    0) exit ;;
  esac
done
