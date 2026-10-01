#!/usr/bin/env python3
"""Erzeugt prioliste.lua fuer das WoWUtils-Plus-Addon aus der LC-Prioliste.ods.

Aufruf (Kommandozeile):
    python3 tools/prioliste.py "/home/jgerke/LC - Prioliste.ods" > prioliste.lua

Wird auch von der Weboberflaeche (~/prioliste/server.py) importiert — dort kommen die
Werte aus data.json statt aus der ODS, das Lua-Format ist aber dasselbe.
"""

import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile

T = "urn:oasis:names:tc:opendocument:xmlns:table:1.0"
TXT = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"


def normalisiere(name: str) -> str:
    """Wie ns.Normalisiere im Addon: Kleinschreibung, Realm weg, Akzente weg."""
    s = str(name).strip().lower().split("-")[0]
    s = unicodedata.normalize("NFKD", s)
    s = "".join(z for z in s if not unicodedata.combining(z))
    return "".join(z for z in s if z.isalnum())


def lese_ods(pfad: str):
    """-> Liste von (schluessel, originalname, prio) aus Spalte 1 und 2."""
    with zipfile.ZipFile(pfad) as z:
        root = ET.fromstring(z.read("content.xml"))
    eintraege = []
    for tabelle in root.iter("{%s}table" % T):
        for zeile in tabelle.iter("{%s}table-row" % T):
            zellen = []
            for zelle in zeile.iter("{%s}table-cell" % T):
                txt = "".join(t.text or "" for t in zelle.iter("{%s}p" % TXT))
                wdh = int(zelle.get("{%s}number-columns-repeated" % T, 1))
                zellen.extend([txt] * min(wdh, 4))
            while zellen and zellen[-1] == "":
                zellen.pop()
            if len(zellen) < 2:
                continue
            name, prio = zellen[0].strip(), zellen[1].strip()
            if not name or not prio.isdigit():
                continue
            p = int(prio)
            if 1 <= p <= 5:
                eintraege.append((normalisiere(name), name, p))
    return eintraege


def lua_text(eintraege, stand: str = "", quelle: str = "") -> str:
    """Baut den Inhalt von prioliste.lua.

    eintraege: Liste von (schluessel, originalname, prio)
    """
    zeilen = [
        "-- Automatisch erzeugt — NICHT von Hand editieren.",
        "-- Quelle: %s" % (quelle or "LC-Prioliste.ods (Spalte 1 = Name, Spalte 2 = Prioritaet 1-5)"),
    ]
    if stand:
        zeilen.append("-- Stand: %s" % stand)
    zeilen += [
        "--",
        "-- Schluessel = normalisierter Name (Kleinschreibung, ohne Akzente), damit",
        "-- 'Dranash' aus der Liste auch den Char 'dránash' trifft.",
        "",
        "local _, ns = ...",
        "",
        "ns.PRIO = {",
    ]
    for schluessel, original, prio in sorted(eintraege):
        zeilen.append('    ["%s"] = %d,   -- %s' % (schluessel, prio, original))
    zeilen += ["}", "", "ns.PRIO_ANZAHL = %d" % len(eintraege), ""]
    if stand:
        zeilen.append('ns.PRIO_STAND = "%s"' % stand)
    return "\n".join(zeilen) + "\n"


def main() -> None:
    pfad = sys.argv[1]
    import datetime
    stand = datetime.datetime.now().strftime("%d.%m.%Y %H:%M")
    print(lua_text(lese_ods(pfad), stand=stand, quelle=pfad), end="")


if __name__ == "__main__":
    main()