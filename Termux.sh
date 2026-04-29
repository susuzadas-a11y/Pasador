#!/bin/bash

echo "Passador de Replay Fusion Cheaters"
echo "Escolha uma opção:"
echo "1 - Copiar replay de Free Fire Max para Free Fire normal"
echo "2 - Enviar replay para outro celular via USB"

read -p "Digite o número da opção: " opcao

if [ "$opcao" -eq 1 ]; then
    SRC_DIR="/sdcard/Android/data/com.dts.freefiremax/files/MReplays"
    DST_DIR="/sdcard/Android/data/com.dts.freefireth/files/MReplays"

    MARKER="$DST_DIR/.transfer_interna"

    [ -d "$SRC_DIR" ] || exit 1
    mkdir -p "$DST_DIR"
    touch "$MARKER"

    RECENT_BIN=$(ls -t "$SRC_DIR"/*.bin 2>/dev/null | head -1)
    RECENT_JSON=$(ls -t "$SRC_DIR"/*.json 2>/dev/null | head -1)

    [ -n "$RECENT_BIN" ] && cp -f "$RECENT_BIN" "$DST_DIR"/ > /dev/null 2>&1
    [ -n "$RECENT_JSON" ] && cp -f "$RECENT_JSON" "$DST_DIR"/ > /dev/null 2>&1

    [ -n "$RECENT_BIN" ] && chmod 666 "$DST_DIR/$(basename "$RECENT_BIN")" > /dev/null 2>&1
    [ -n "$RECENT_JSON" ] && chmod 666 "$DST_DIR/$(basename "$RECENT_JSON")" > /dev/null 2>&1

    if [ -n "$RECENT_JSON" ]; then
        JSON_FILE="$DST_DIR/$(basename "$RECENT_JSON")"
        sed -i 's/"[Vv]ersion":"[^"]*"/"Version":"1.123.1"/' "$JSON_FILE" > /dev/null 2>&1
    fi

    if [ -n "$RECENT_BIN" ]; then
        touch -r "$RECENT_BIN" "$DST_DIR/$(basename "$RECENT_BIN")" > /dev/null 2>&1
    fi
    if [ -n "$RECENT_JSON" ]; then
        touch -r "$RECENT_JSON" "$DST_DIR/$(basename "$RECENT_JSON")" > /dev/null 2>&1
    fi

    rm -f "$MARKER" > /dev/null 2>&1

elif [ "$opcao" -eq 2 ]; then
    RECENT_BIN=$(ls -t "/sdcard/Android/data/com.dts.freefiremax/files/MReplays"/*.bin 2>/dev/null | head -1)
    RECENT_JSON=$(ls -t "/sdcard/Android/data/com.dts.freefiremax/files/MReplays"/*.json 2>/dev/null | head -1)

    if [ -n "$RECENT_BIN" ]; then
        adb push "$RECENT_BIN" "/sdcard/Android/data/com.dts.freefireth/files/MReplays/" > /dev/null 2>&1
    fi
    if [ -n "$RECENT_JSON" ]; then
        adb push "$RECENT_JSON" "/sdcard/Android/data/com.dts.freefireth/files/MReplays/" > /dev/null 2>&1
    fi
fi