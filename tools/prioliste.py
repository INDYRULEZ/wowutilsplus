#!/usr/bin/env python3
"""Erzeugt prioliste.lua fuer das WoWUtils-Plus-Addon aus der LC-Prioliste.ods.

Aufruf:
    python3 tools/prioliste.py "/home/jgerke/LC - Prioliste.ods" > prioliste.lua

Spalte 1 = Spielername, Spalte 2 = Prioritaet (1-5). Weitere Spalten werden ignoriert.
Namen werden normalisiert (Kleinschreibung, Akzente weg) — genau wie ns.Normalisiere im Addon.
"""

import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile

T = "urn:oasis:names:tc:opendocument:xmlns:table:1.0"
TXT = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"


def normalisiere(name: str) -> str:
    s = name.strip().lower().split("-")[0]
    s = unicodedata.normalize("NFKD", s)
    s = "".join(z for z in s if not unicodedata.combining(z))
    return "".join(z for z in s if z.isalnum())


def lese(pfad: str):
    with zipfile.ZipFile(pfad) as z:
        root = ET.fromstring(z.read("content.xml"))
    zeilen = []
    for tabelle in root.iter("{%s}table" % T):
        for zeile in tabelle.iter("{%s}table-row" % T):
            zellen = []
            for zelle in zeile.iter("{%s}table-cell" % T):
                txt = "".join(t.text or "" for t in zelle.iter("{%s}p" % TXT))
                wdh = int(zelle.get("{%s}number-columns-repeated" % T, 1))
                zellen.extend([txt] * min(wdh, 4))
            while zellen and zellen[-1] == "":
                zellen.pop()
            if zellen:
                zeilen.append(zellen)
    return zeilen


def main() -> None:
    pfad = sys.argv[1]
    eintraege = []
    for zellen in lese(pfad):
        if len(zellen) < 2:
            continue
        name, prio = zellen[0].strip(), zellen[1].strip()
        if not name or not prio.isdigit():
            continue
        p = int(prio)
        if not 1 <= p <= 5:
            continue
        eintraege.append((normalisiere(name), name, p))

    print("-- Automatisch erzeugt aus der LC-Prioliste.ods — NICHT von Hand editieren.")
    print("-- Quelle: /home/jgerke/LC - Prioliste.ods   (Spalte 1 = Name, Spalte 2 = Prioritaet 1-5)")
    print("-- Neu erzeugen: python3 tools/prioliste.py \"<Pfad zur .ods>\" > prioliste.lua")
    print("--")
    print("-- Schluessel = normalisierter Name (Kleinschreibung, ohne Akzente), damit")
    print("-- 'Dranash' aus der Liste auch den Char 'dránash' trifft.")
    print()
    print("local _, ns = ...")
    print()
    print("ns.PRIO = {")
    for schluessel, original, prio in sorted(eintraege):
        print(f'    ["{schluessel}"] = {prio},   -- {original}')
    print("}")
    print()
    print(f"ns.PRIO_ANZAHL = {len(eintraege)}")


if __name__ == "__main__":
    main()