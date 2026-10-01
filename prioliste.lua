-- Automatisch erzeugt aus der LC-Prioliste.ods — NICHT von Hand editieren.
-- Quelle: /home/jgerke/LC - Prioliste.ods   (Spalte 1 = Name, Spalte 2 = Prioritaet 1-5)
-- Neu erzeugen: python3 tools/prioliste.py "<Pfad zur .ods>" > prioliste.lua
--
-- Schluessel = normalisierter Name (Kleinschreibung, ohne Akzente), damit
-- 'Dranash' aus der Liste auch den Char 'dránash' trifft.

local _, ns = ...

ns.PRIO = {
    ["balren"] = 2,   -- Balren
    ["beaybewhy"] = 4,   -- Beaybewhy
    ["blitzfaust"] = 3,   -- Blitzfaust
    ["cep"] = 1,   -- Cep
    ["cheliia"] = 2,   -- Cheliia
    ["dranash"] = 3,   -- Dranash
    ["enshirogue"] = 5,   -- Enshirogue
    ["exorzist"] = 2,   -- Exorzist
    ["exudes"] = 3,   -- Exudes
    ["garshu"] = 2,   -- Garshû
    ["gweni"] = 4,   -- Gwêni
    ["hyperhardw"] = 3,   -- Hyperhardw
    ["indydrakes"] = 2,   -- Indydrakes
    ["jekyl"] = 5,   -- Jekyl
    ["merlon"] = 2,   -- Merlón
    ["moriko"] = 5,   -- Moriko
    ["neyzxd"] = 5,   -- Neyzxd
    ["notam"] = 1,   -- Notam
    ["ophrys"] = 3,   -- Ophrys
    ["palacetamol"] = 5,   -- palacetamol
    ["schmeckies"] = 5,   -- Schmeckies
    ["setup"] = 3,   -- Setup
    ["sikkz"] = 1,   -- Sikkz
    ["silanhunt"] = 2,   -- Silanhunt
    ["thunderdebbo"] = 3,   -- Thunderdebbo
    ["tobii"] = 1,   -- Tobii
    ["twosocks"] = 1,   -- Twosocks
    ["vilarie"] = 2,   -- Vilarie
}

ns.PRIO_ANZAHL = 28
