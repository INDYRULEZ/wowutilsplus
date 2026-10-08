#!/bin/bash
# ---------------------------------------------------------------------------
# NOTFALL-WEG — nicht der normale Weg.
#
# Normal laeuft die Verteilung ueber GitHub-Release + WowUp. Dieses Skript
# kopiert die UNVEROEFFENTLICHTE Fassung direkt in den Spielordner. Nur fuer
# Notfaelle: GitHub nicht erreichbar, oder ein Test VOR dem Release.
#
# 🔴 Vorher ANKUENDIGEN — Jonas sieht den Laptop nie. Drei Dinge nennen:
#    welche Datei, welcher Ordner, und dass nichts anderes angefasst wird
#    (keine Spiel-Einstellungen, keine anderen Addons, keine Charakterdaten).
#    Danach sagen, dass dort jetzt die unveroeffentlichte Fassung liegt und
#    WowUp sie beim naechsten Abgleich ueberschreibt.
# ---------------------------------------------------------------------------
# Kopiert unser Addon auf den Desktop-PC in den AddOns-Ordner.
# Danach im Spiel: /reload  und dann  /wup
#
# Nutzt tar ueber SSH (nicht scp) — der Zielpfad enthaelt Leerzeichen
# ("Program Files (x86)"), das ist damit unproblematisch.
set -euo pipefail

PC="jgerke@192.168.7.2"
KEY="$HOME/.ssh/id_ed25519"
NAME="wowutilsplus"
REMOTE_ADDONS='Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns'
QUELLE="$(cd "$(dirname "$0")" && pwd)"
ELTERN="$(dirname "$QUELLE")"
SSH=(ssh -o BatchMode=yes -o ConnectTimeout=8 -o IdentitiesOnly=yes -i "$KEY" "$PC")

if ! ping -c1 -W2 192.168.7.2 >/dev/null 2>&1; then
    echo "PC ist nicht erreichbar (aus oder im Standby). Erst einschalten."
    exit 1
fi

echo "Kopiere $NAME nach $PC ..."
tar -czf - -C "$ELTERN" --exclude='README.md' --exclude='deploy.sh' --exclude='.git' --exclude='tools' "$NAME" \
  | "${SSH[@]}" "rm -rf \"\$HOME/$REMOTE_ADDONS/$NAME\" && tar -xzf - -C \"\$HOME/$REMOTE_ADDONS\""

echo "--- Kontrolle auf dem PC ---"
"${SSH[@]}" "ls -la \"\$HOME/$REMOTE_ADDONS/$NAME\""
echo
echo "Fertig. Im Spiel: /reload  — dann  /wup"