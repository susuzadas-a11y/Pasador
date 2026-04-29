#!/data/data/com.termux/files/usr/bin/bash

exec 2>/dev/null

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

# ===== UI =====
banner(){
clear
echo -e "${P}"
echo "╔══════════════════════════════════════╗"
echo "║         FUSION ULTRA SYSTEM          ║"
echo "╠══════════════════════════════════════╣"
echo "║           AUTO MODE ACTIVE           ║"
echo "╚══════════════════════════════════════╝"
echo -e "${N}"
}

loading(){
for ((i=0;i<=100;i++)); do
printf "\r${P}Loading %d%%%s" "$i" "$N"
sleep 0.008
done
echo ""
}

pause(){
echo ""
read -p "ENTER..." _
}

# ===== LOGIN =====
login(){
t=3
while [ $t -gt 0 ]; do
banner
echo -e "${W}Código:${N}"
read pin

[ "$pin" = "$OWNER_PIN" ] && return

for p in "${VALID_PINS[@]}"; do
[ "$pin" = "$p" ] && return
done

t=$((t-1))
echo -e "${R}Inválido ($t)${N}"
sleep 1
done
exit
}

# ===== WIFI CORE =====
connect_saved(){
[ ! -f "$ADB_CFG" ] && return 1
CFG=$(cat "$ADB_CFG")

adb connect "$CFG" >/dev/null 2>&1
adb devices | grep -q "$CFG"
}

connect_manual(){
banner
echo "1 - Conectar manual"
echo "0 - Voltar"
read -p "Escolha: " op

case "$op" in
1)
  read -p "IP: " ip
  read -p "PORTA: " port

  TARGET="$ip:$port"
  echo "Conectando..."
  adb connect "$TARGET" >/dev/null 2>&1

  if adb devices | grep -q "$TARGET"; then
    echo "$TARGET" > "$ADB_CFG"
    echo -e "${G}✔ Conectado${N}"
  else
    echo -e "${R}✖ Falha${N}"
  fi
  pause
;;
esac
}

wifi_menu(){
while true; do
banner
echo "1 - Conectar manual"
echo "2 - Testar conexão"
echo "3 - Limpar conexão salva"
echo "0 - Voltar"
echo ""

read -p "Escolha: " op

case "$op" in
1) connect_manual ;;
2)
  if connect_saved; then
    echo -e "${G}✔ Conectado${N}"
  else
    echo -e "${R}✖ Não conectado${N}"
  fi
  pause
;;
3)
  rm -f "$ADB_CFG"
  echo "Config apagada"
  pause
;;
0) break ;;
esac

done
}

# ===== ADB =====
check_adb(){ command -v adb >/dev/null 2>&1; }
check_device(){ adb devices | grep -q "device"; }

# ===== PATH =====
SRC="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
DST="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

# ===== CORE =====
copy_local(){
mkdir -p "$DST"

BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

[ -n "$BIN" ] && cp -f "$BIN" "$DST"/ >/dev/null 2>&1
[ -n "$JSON" ] && cp -f "$JSON" "$DST"/ >/dev/null 2>&1

loading
}

send_usb(){
check_adb || return
check_device || return

BIN=$(ls -t "$SRC"/*.bin 2>/dev/null | head -1)
JSON=$(ls -t "$SRC"/*.json 2>/dev/null | head -1)

[ -n "$BIN" ] && adb push "$BIN" "$DST"/ >/dev/null 2>&1
[ -n "$JSON" ] && adb push "$JSON" "$DST"/ >/dev/null 2>&1

loading
}

# ===== AUTO START =====
auto_connect(){
connect_saved && return
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

read -p "Escolha: " op

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
auto_connect
menu
