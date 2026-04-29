#!/data/data/com.termux/files/usr/bin/bash

# ===== CONFIG =====
OWNER_PIN="7865"
BLOCK_FILE="$HOME/.fusion_block"
USED_PINS="$HOME/.fusion_used_pins"

VALID_PINS=(
"01" "2002" "9321" "3469" "9397" "2773" "83872"
"02773" "2937" "15838" "205273" "2862" "7262" "62835"
)

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
    clear
    echo "==== PASSADOR DE REPLAY FUSION ===="
    echo ""

    read -p "Digite o código: " pin

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
  clear
  echo "===== PASSADOR DE REPLAY FUSION ====="
  echo ""
  echo "1 - Passar replay para FF normal"
  echo "2 - Passador para outro dispositivo"
  echo "3 - Conectar depuração wi-fi"
  echo "0 - Sair"
  echo ""
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
  esac
done
