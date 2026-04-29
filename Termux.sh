#!/data/data/com.termux/files/usr/bin/bash

# ===== CONFIG =====
OWNER_PIN="7865"
ADB_CFG="$HOME/.adb_wifi"

VALID_PINS=(
"01" "2002" "9321" "3469" "9397" "2773" "83872"
"02773" "2937" "15838" "205273" "2862" "7262" "62835"
)

# ===== CORES =====
P='\033[1;35m'
L='\033[0;35m'
W='\033[1;37m'
R='\033[1;31m'
G='\033[1;32m'
N='\033[0m'

# ===== BANNER =====
banner(){
clear
echo -e "${P}"
echo "╔══════════════════════════════════════╗"
echo "║     PASSADOR DE REPLAY FUSION        ║"
echo "╠══════════════════════════════════════╣"
echo "║        SISTEMA PREMIUM TERMUX        ║"
echo "╚══════════════════════════════════════╝"
echo -e "${N}"
}

# ===== LOGIN =====
login(){
t=3
while [ $t -gt 0 ]; do
  banner
  echo -e "${W}Digite o código:${N}"
  read -r pin

  [ "$pin" = "$OWNER_PIN" ] && return

  for p in "${VALID_PINS[@]}"; do
    [ "$pin" = "$p" ] && return
  done

  t=$((t-1))
  echo -e "${R}PIN inválido ($t)${N}"
  sleep 1
done
exit
}

# ===== WIFI AUTO =====
connect_saved(){
[ ! -f "$ADB_CFG" ] && return 1
CFG=$(cat "$ADB_CFG")

adb connect "$CFG" >/dev/null 2>&1
adb devices | grep -q "$CFG"
}

wifi_auto(){
if connect_saved; then
  return
fi

banner
echo "Conectar Wi-Fi"

read -p "IP: " ip
read -p "PORTA: " port

TARGET="$ip:$port"
adb connect "$TARGET" >/dev/null 2>&1

if adb devices | grep -q "$TARGET"; then
  echo "$TARGET" > "$ADB_CFG"
  echo -e "${G}✔ Conectado${N}"
else
  echo -e "${R}✖ Falha${N}"
  sleep 1
fi
}

wifi_menu(){
while true; do
banner
echo "1 - Conectar manual"
echo "2 - Testar conexão"
echo "3 - Limpar conexão"
echo "0 - Voltar"
echo ""

read -r op
op=$(echo "$op" | tr -d ' ')

case "$op" in
1) wifi_auto ;;
2)
  if connect_saved; then
    echo -e "${G}✔ Conectado${N}"
  else
    echo -e "${R}✖ Não conectado${N}"
  fi
  sleep 1
;;
3)
  rm -f "$ADB_CFG"
  echo "Removido"
  sleep 1
;;
0) break ;;
esac
done
}

# ===== ADB =====
check_adb(){ command -v adb >/dev/null 2>&1; }

check_device(){
adb devices | grep -w "device" | grep -v "List" >/dev/null 2>&1
}

# ===== PATH =====
SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
DST="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

# ===== FUNÇÕES =====
copy_local(){

  mkdir -p "$DST"

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  if [ -z "$BIN" ] && [ -z "$JSON" ]; then
    echo "Nenhum replay encontrado"
    sleep 1
    return
  fi

  [ -n "$BIN" ] && cp -f "$BIN" "$DST"/ >/dev/null 2>&1
  [ -n "$JSON" ] && cp -f "$JSON" "$DST"/ >/dev/null 2>&1

  [ -n "$JSON" ] && sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"1.123.1"/' "$DST/$(basename "$JSON")" >/dev/null 2>&1

  echo "✔ Replay copiado"
  sleep 1
}

send_usb(){

  banner
  echo "Enviando..."

  if ! check_adb; then
    echo "ADB não instalado"
    sleep 1
    return
  fi

  if ! check_device; then
    echo "Nenhum dispositivo conectado"
    sleep 1
    return
  fi

  BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
  JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

  if [ -z "$BIN" ] && [ -z "$JSON" ]; then
    echo "Nenhum replay encontrado"
    sleep 1
    return
  fi

  [ -n "$BIN" ] && adb push "$BIN" "$DST"/ >/dev/null 2>&1
  [ -n "$JSON" ] && adb push "$JSON" "$DST"/ >/dev/null 2>&1

  echo "✔ Enviado com sucesso"
  sleep 1
}

# ===== MENU =====
menu(){
while true; do
banner

echo -e "${W}STATUS:${N}"
if connect_saved; then
echo -e "${G}ADB CONECTADO${N}"
else
echo -e "${R}SEM CONEXÃO${N}"
fi

echo ""
echo "1 - Passar replay local"
echo "2 - Enviar para dispositivo"
echo "3 - Wi-Fi / Conexão"
echo "0 - Sair"
echo ""

read -r op
op=$(echo "$op" | tr -d ' ')

case "$op" in
1) copy_local ;;
2) send_usb ;;
3) wifi_menu ;;
0) exit ;;
*) echo "Inválido"; sleep 1 ;;
esac

done
}

# ===== EXEC =====
login
wifi_auto
menu
