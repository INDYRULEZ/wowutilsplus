#!/usr/bin/env python3
"""Fehlersammlung des Spiel-PCs auslesen (BugSack / !BugGrabber).

Holt die SavedVariables-Datei `!BugGrabber.lua` vom Spiel-PC, wertet sie aus und
zeigt die Fehler als lesbare Liste. Filtert auf Wunsch nach Addon-Namen.

Warum so: BugGrabber schreibt eine reine Datendatei (kein Code), also wird sie
mit dem echten Lua 5.1 eingelesen statt mit regulaeren Ausdruecken geparst —
damit stimmen auch verschachtelte Felder und Umlaute.

Aufruf:
    tools/bugmeldungen_lesen.py                 # alle Fehler, neueste zuerst
    tools/bugmeldungen_lesen.py wowutilsplus    # nur die unseres Addons
    tools/bugmeldungen_lesen.py --alles         # ohne Kuerzung der Meldung
"""

import argparse
import datetime
import os
import re
import subprocess
import sys
import tempfile

PC = "jgerke@192.168.7.2"
KEY = os.path.expanduser("~/.ssh/id_ed25519")
FERN = ("$HOME/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/"
        "_retail_/WTF/Account/128341967#1/SavedVariables/!BugGrabber.lua")

# Fehler, die nichts mit einem Addon-Fehler zu tun haben, aber die Liste fluten.
RAUSCHEN = (
    "LUA_WARNING: ...ace/AddOns/Blizzard_",
    "secret string value tainted by",
)


def datei_holen() -> str:
    """BugGrabber-Datei vom PC holen. Bricht mit klarer Meldung ab."""
    p = subprocess.run(
        ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8",
         "-o", "IdentitiesOnly=yes", "-i", KEY, PC, f'cat "{FERN}"'],
        capture_output=True, text=True, timeout=120)
    if p.returncode != 0:
        sys.exit("PC nicht erreichbar oder Datei fehlt:\n" + (p.stderr or "").strip())
    if not p.stdout.strip():
        sys.exit("Die Datei ist leer — BugGrabber hat noch nichts gespeichert.\n"
                 "Erst im Spiel /reload (laedt das Addon), Fehler erzeugen, dann erneut /reload.")
    return p.stdout


def auswerten(lua_quelle: str):
    """Die Datendatei mit echtem Lua 5.1 einlesen und als Zeilen ausgeben."""
    skript = r'''
local datei = arg[1]
local ok, fehler = pcall(dofile, datei)
if not ok then io.stderr:write("Datei nicht lesbar: " .. tostring(fehler) .. "\n"); os.exit(2) end
local db = BugGrabberDB
if type(db) ~= "table" or type(db.errors) ~= "table" then
    io.stderr:write("Keine Fehlerliste gefunden.\n"); os.exit(3)
end
local trenner = string.char(31)
for i, e in ipairs(db.errors) do
    local t = type(e) == "table" and e or {}
    local msg = tostring(t.message or ""):gsub("[\r\n]+", " ")
    local stk = tostring(t.stack or ""):gsub("[\r\n]+", " ")
    io.write(string.format("%d%s%s%s%s%s%s\n", i, trenner,
        tostring(t.time or "?"), trenner, msg, trenner, stk))
end
'''
    # 🔴 Beide Dateien als echte Skripte aufrufen: `lua -e "code" datei` setzt `...`
    # NICHT auf den Dateinamen — der Auswerter haette dann stdin gelesen und still
    # nichts gefunden. Deshalb Skript-Datei + Argument.
    with tempfile.TemporaryDirectory() as ordner:
        skript_pfad = os.path.join(ordner, "auswerten.lua")
        daten_pfad = os.path.join(ordner, "daten.lua")
        with open(skript_pfad, "w", encoding="utf-8") as f:
            f.write(skript)
        with open(daten_pfad, "w", encoding="utf-8", newline="") as f:
            f.write(lua_quelle)
        p = subprocess.run(["lua5.1", skript_pfad, daten_pfad],
                           capture_output=True, text=True, timeout=120)
    if p.returncode != 0:
        sys.exit("Lua-Auswertung fehlgeschlagen:\n" + (p.stderr or "").strip())
    zeilen = []
    for zeile in p.stdout.splitlines():
        teile = zeile.split("\x1f")
        # Aufbau: Nummer | Zeit | Meldung | Stapel  (4 Felder, nicht mehr)
        if len(teile) >= 4:
            zeilen.append({"nr": teile[0], "zeit": teile[1],
                           "meldung": teile[2], "stapel": teile[3]})
    return zeilen


def zeit_lesbar(wert: str) -> str:
    """BugGrabber legt je nach Fassung eine Unix-Zahl oder schon Text ab."""
    try:
        return datetime.datetime.fromtimestamp(int(wert)).strftime("%d.%m.%Y %H:%M")
    except (TypeError, ValueError, OSError, OverflowError):
        return str(wert)


def addon_aus_stapel(eintrag: dict) -> str:
    """Welches Addon war schuld? Aus der Stapelspur raten ist erlaubt — es ist eine Anzeige."""
    text = eintrag["meldung"] + " " + eintrag["stapel"]
    treffer = re.findall(r"AddOns[/\\]([A-Za-z0-9_!\-]+)[/\\]", text)
    if treffer:
        # letzter Treffer ist meist der Ausloeser, der erste oft nur FrameXML
        return treffer[-1]
    if text.startswith("LUA_WARNING") or "tainted by" in text:
        return "(Blizzard/Verunreinigung)"
    return "?"


def main():
    ap = argparse.ArgumentParser(description="Fehler von BugSack/BugGrabber auslesen")
    ap.add_argument("filter", nargs="?", default=None,
                    help="nur Fehler, die diesen Namen enthalten (z. B. wowutilsplus)")
    ap.add_argument("--alles", action="store_true", help="Meldungen nicht kuerzen")
    ap.add_argument("--rauschen", action="store_true",
                    help="auch die bekannten Blizzard-/Verunreinigungs-Meldungen zeigen")
    args = ap.parse_args()

    quelle = datei_holen()
    eintraege = auswerten(quelle)

    if not args.rauschen:
        eintraege = [e for e in eintraege
                     if not any(r in e["meldung"] for r in RAUSCHEN)]
    if args.filter:
        eintraege = [e for e in eintraege
                     if args.filter.lower() in (e["meldung"] + e["stapel"]).lower()]

    print(f"{len(eintraege)} Fehler{' (gefiltert: ' + args.filter + ')' if args.filter else ''}")
    print("=" * 72)
    # neueste zuerst
    for e in reversed(eintraege):
        kurz = e["meldung"]
        if not args.alles and len(kurz) > 300:
            kurz = kurz[:300] + " …"
        print(f"\n[{zeit_lesbar(e['zeit'])}]  {addon_aus_stapel(e)}")
        print("  " + kurz)
        if args.alles and e["stapel"]:
            print("  Stapel: " + e["stapel"][:800])
    print("\n" + "=" * 72)
    print("Hinweis: BugGrabber schreibt die Datei nur beim Ausloggen oder /reload.")


if __name__ == "__main__":
    main()