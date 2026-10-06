-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 06.10.2026 13:26

local _, ns = ...

ns.WEIGHTS = {
    HEALER  = { factor = 0.52 },
    TANK    = { factor = 0.90 },
    DAMAGER = { factor = 1.00 },
}

-- Faktor nach Wunschlisten-Priorität (1 = Best in Slot, 2 = Upgrade).
-- Nur diese beiden sind belegt; alles andere bleibt bei 1.00.
ns.WUNSCH = {
    [1] = 1.00,   -- Best in Slot
    [2] = 0.60,   -- Upgrade
}

-- Items seit Reset / Crests — Stellschrauben der Weboberflaeche.
-- Items:      Abzug je Item, das der Spieler SEIT DEM LETZTEN WEEKLY-RESET
--             erhalten hat; der Faktor faellt nicht unter ITEMS_UNTEN.
--             Die Gesamtzahl der Items wird nur angezeigt.
-- Crests:      Faktor linear von CREST_MIN (0 Crests) bis 1.00 ab CREST_SCHWELLE.
--              Eingang ist 'hat + diese Woche noch frei' (nur Stufe Mythic).
ns.ITEMS_HEUTE_ABZUG = 0.200
ns.ITEMS_UNTEN = 0.500
ns.CREST_MIN = 1.000
ns.CREST_SCHWELLE = 80

-- Leistungs-Faktoren: Average log, First kill log, Movement/Survival.
-- Die Werte je Spieler werden spaeter automatisch berechnet und hier eingesetzt;
-- vorerst neutral 1.00 (ohne Wirkung).
ns.LEISTUNG = {
    average   = 1.00,   -- Average log (je Spieler siehe unten)
    firstkill = 1.00,   -- First kill log
    movement  = 1.00,   -- Movement/Survival
}

-- Leistungswerte je Spieler, automatisch aus Warcraft Logs.
-- average:   Median der Parse-Prozente ueber die letzten 10 mythischen Kills
--            der eigenen Gilde. 100er Log = 1.00, 0er Log = 0.85 (linear).
-- firstkill: Rangfolge in den mythischen Erst-Kills, Platz 1 ohne Abzug, letzter Platz -20 %.
-- movement:  von Hand auf der Seite gepflegt, dort als Abzug in Prozent
--            (hoechstens 20 %, also Faktor bis 0.80).
ns.LEISTUNG_AVG_ABZUG = 0.150
ns.LEISTUNG_KADERSCHNITT = 38.0
ns.LEISTUNG_SPIELER = {
    ["balren"] = { average = 0.90, avgMedian = 34.5, avgKills = 10, firstkill = 0.91, fkPlatz = 10, fkVon = 22, fkAnteil = 85.3, fkKaempfe = 4, fkMenge = 204026, movement = 0.96 },   -- Balren · Average 34,5 % (10 Kills) · Erst-Kill Platz 10/22 · Movement -4,0 %
    ["bigboysushi"] = { firstkill = 0.90, fkPlatz = 12, fkVon = 22, fkAnteil = 79.1, fkKaempfe = 2, fkMenge = 205011 },   -- Bigboysushi · Erst-Kill Platz 12/22
    ["blitzfaust"] = { average = 0.89, avgMedian = 27.0, avgKills = 8, firstkill = 0.93, fkPlatz = 8, fkVon = 22, fkAnteil = 87.5, fkKaempfe = 2, fkMenge = 206535, movement = 0.94 },   -- Blitzfaust · Average 27,0 % (8 Kills) · Erst-Kill Platz 8/22 · Movement -6,0 %
    ["cep"] = { average = 0.92, avgMedian = 46.0, avgKills = 1, firstkill = 0.95, fkPlatz = 6, fkVon = 22, fkAnteil = 89.3, fkKaempfe = 4, fkMenge = 216898, movement = 0.95 },   -- Cep · Average 46,0 % (1 Kills) · Erst-Kill Platz 6/22 · Movement -5,0 %
    ["cheliia"] = { average = 0.95, avgMedian = 66.5, avgKills = 10, firstkill = 0.92, fkPlatz = 9, fkVon = 22, fkAnteil = 85.7, fkKaempfe = 3, fkMenge = 187583, movement = 0.90 },   -- Cheliia · Average 66,5 % (10 Kills) · Erst-Kill Platz 9/22 · Movement -10,0 %
    ["dranash"] = { movement = 0.93 },   -- dranash · Movement -7,0 %
    ["enshirou"] = { average = 0.86, avgMedian = 4.0, avgKills = 6, firstkill = 0.89, fkPlatz = 13, fkVon = 22, fkAnteil = 78.8, fkKaempfe = 3, fkMenge = 183840, movement = 0.88 },   -- Enshirou · Average 4,0 % (6 Kills) · Erst-Kill Platz 13/22 · Movement -12,0 %
    ["exorzist"] = { average = 0.88, avgMedian = 19.0, avgKills = 10, firstkill = 0.92, fkPlatz = 9, fkVon = 22, fkAnteil = 75.6, fkKaempfe = 4, fkMenge = 329954, movement = 0.95 },   -- Exorzist · Average 19,0 % (10 Kills) · Erst-Kill Platz 9/22 von Hand · Movement -5,0 %
    ["exudes"] = { firstkill = 0.99, fkPlatz = 2, fkVon = 22, fkAnteil = 100.0, fkKaempfe = 1, fkMenge = 261258, movement = 0.96 },   -- Exudes · Erst-Kill Platz 2/22 · Movement -4,0 %
    ["garshu"] = { average = 0.88, avgMedian = 22.0, avgKills = 10, firstkill = 0.86, fkPlatz = 16, fkVon = 22, fkAnteil = 75.0, fkKaempfe = 4, fkMenge = 190778, movement = 0.92 },   -- Garshû · Average 22,0 % (10 Kills) · Erst-Kill Platz 16/22 · Movement -8,0 %
    ["gweni"] = { average = 0.89, avgMedian = 26.0, avgKills = 4, firstkill = 0.94, fkPlatz = 7, fkVon = 22, fkAnteil = 88.9, fkKaempfe = 4, fkMenge = 197025, movement = 0.97 },   -- Gwêni · Average 26,0 % (4 Kills) · Erst-Kill Platz 7/22 · Movement -3,0 %
    ["hyperhardw"] = { average = 0.92, avgMedian = 46.5, avgKills = 10, firstkill = 0.88, fkPlatz = 14, fkVon = 22, fkAnteil = 77.5, fkKaempfe = 3, fkMenge = 164303, movement = 0.93 },   -- Hyperhardw · Average 46,5 % (10 Kills) · Erst-Kill Platz 14/22 · Movement -7,0 %
    ["indydrakes"] = { average = 0.90, avgMedian = 31.5, avgKills = 10, firstkill = 0.83, fkPlatz = 19, fkVon = 22, fkAnteil = 72.3, fkKaempfe = 3, fkMenge = 153253, movement = 0.99 },   -- Indydrakes · Average 31,5 % (10 Kills) · Erst-Kill Platz 19/22 · Movement -1,0 %
    ["jekyl"] = { firstkill = 0.82, fkPlatz = 20, fkVon = 22, fkAnteil = 67.9, fkKaempfe = 1, fkMenge = 177508, movement = 0.90 },   -- Jekyl · Erst-Kill Platz 20/22 · Movement -10,0 %
    ["jirylock"] = { average = 0.85, avgMedian = 3.0, avgKills = 9, movement = 0.95 },   -- Jirylock · Average 3,0 % (9 Kills) · Movement -5,0 %
    ["merlon"] = { average = 0.96, avgMedian = 75.5, avgKills = 10, firstkill = 0.96, fkPlatz = 5, fkVon = 22, fkAnteil = 89.8, fkKaempfe = 4, fkMenge = 211056, movement = 0.93 },   -- Merlón · Average 75,5 % (10 Kills) · Erst-Kill Platz 5/22 · Movement -7,0 %
    ["neyzxd"] = { average = 0.95, avgMedian = 66.0, avgKills = 5, movement = 0.90 },   -- Neyzxd · Average 66,0 % (5 Kills) · Movement -10,0 %
    ["notam"] = { average = 0.86, avgMedian = 4.0, avgKills = 10, firstkill = 0.85, fkPlatz = 17, fkVon = 22, fkAnteil = 74.9, fkKaempfe = 4, fkMenge = 169359, movement = 0.90 },   -- Notam · Average 4,0 % (10 Kills) · Erst-Kill Platz 17/22 · Movement -10,0 %
    ["ophrys"] = { average = 0.93, avgMedian = 50.0, avgKills = 10, firstkill = 0.86, fkPlatz = 16, fkVon = 22, fkAnteil = 63.7, fkKaempfe = 4, fkMenge = 271314, movement = 0.88 },   -- Ophrys · Average 50,0 % (10 Kills) · Erst-Kill Platz 16/22 von Hand · Movement -12,0 %
    ["palaball"] = { firstkill = 0.84, fkPlatz = 18, fkVon = 22, movement = 0.97 },   -- palaball · Erst-Kill Platz 18/22 von Hand · Movement -3,0 %
    ["palacetamol"] = { average = 0.97, avgMedian = 81.0, avgKills = 9, firstkill = 0.88, fkPlatz = 14, fkVon = 22, movement = 0.96 },   -- Palacetamol · Average 81,0 % (9 Kills) · Erst-Kill Platz 14/22 von Hand · Movement -4,0 %
    ["schmeckies"] = { average = 0.91, avgMedian = 39.0, avgKills = 9, movement = 0.94 },   -- Schmeckies · Average 39,0 % (9 Kills) · Movement -6,0 %
    ["setupx"] = { movement = 0.95 },   -- setupx · Movement -5,0 %
    ["sikkz"] = { average = 0.93, avgMedian = 54.0, avgKills = 10, firstkill = 0.97, fkPlatz = 4, fkVon = 22, fkAnteil = 90.5, fkKaempfe = 4, fkMenge = 215172, movement = 0.93 },   -- Sikkz · Average 54,0 % (10 Kills) · Erst-Kill Platz 4/22 · Movement -7,0 %
    ["silanhunt"] = { average = 0.88, avgMedian = 20.0, avgKills = 8, firstkill = 0.90, fkPlatz = 11, fkVon = 22, fkAnteil = 79.5, fkKaempfe = 4, fkMenge = 187334, movement = 0.98 },   -- Silanhunt · Average 20,0 % (8 Kills) · Erst-Kill Platz 11/22 · Movement -2,0 %
    ["thunderdebbo"] = { average = 0.85, avgMedian = 1.0, avgKills = 1, firstkill = 0.88, fkPlatz = 14, fkVon = 22, fkAnteil = 54.1, fkKaempfe = 4, fkMenge = 245802, movement = 0.94 },   -- Thunderdebbo · Average 1,0 % (1 Kills) · Erst-Kill Platz 14/22 von Hand · Movement -6,0 %
    ["tobii"] = { average = 1.00, avgMedian = 99.0, avgKills = 10, firstkill = 1.00, fkPlatz = 1, fkVon = 22, fkAnteil = 100.0, fkKaempfe = 4, fkMenge = 447149, movement = 0.99 },   -- Tobii · Average 99,0 % (10 Kills) · Erst-Kill Platz 1/22 von Hand · Movement -1,0 %
    ["twosocks"] = { average = 0.91, avgMedian = 38.0, avgKills = 10, firstkill = 0.98, fkPlatz = 3, fkVon = 22, fkAnteil = 95.6, fkKaempfe = 1, fkMenge = 207568, movement = 0.85 },   -- Twosocks · Average 38,0 % (10 Kills) · Erst-Kill Platz 3/22 · Movement -15,0 %
    ["vilarie"] = { average = 0.94, avgMedian = 61.0, avgKills = 9, firstkill = 0.84, fkPlatz = 18, fkVon = 22, fkAnteil = 74.7, fkKaempfe = 1, fkMenge = 195189, movement = 0.87 },   -- Vilarie · Average 61,0 % (9 Kills) · Erst-Kill Platz 18/22 · Movement -13,0 %
}