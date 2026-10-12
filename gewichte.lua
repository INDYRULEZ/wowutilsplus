-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 12.10.2026 17:42

local _, ns = ...

ns.WEIGHTS = {
    HEALER  = { factor = 0.95 },
    TANK    = { factor = 0.95 },
    DAMAGER = { factor = 1.00 },
}

-- Faktor nach Wunschlisten-Priorität (1 = Best in Slot, 2 = Upgrade).
-- Nur diese beiden sind belegt; alles andere bleibt bei 1.00.
-- Ist der Bereich auf der Seite abgeschaltet, stehen hier 1.00/1.00.
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
-- Ist der Bereich auf der Seite abgeschaltet, steht hier 0.000 / 1.000.   (Bereich ist abgeschaltet)
ns.ITEMS_HEUTE_ABZUG = 0.000
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
-- average:   Median der Parse-Prozente ueber die letzten 12 mythischen Kills
--            der eigenen Gilde. 100er Log = 1.00, 0er Log = 0.85 (linear).
-- firstkill: Rangfolge in den mythischen Erst-Kills, Platz 1 ohne Abzug, letzter Platz -20 %.
-- movement:  von Hand auf der Seite gepflegt, dort als Abzug in Prozent
--            (hoechstens 20 %, also Faktor bis 0.80).
ns.LEISTUNG_AVG_ABZUG = 0.150
ns.LEISTUNG_KADERSCHNITT = 36.0
ns.LEISTUNG_SPIELER = {
    ["balren"] = { average = 0.92, avgMedian = 48.0, avgKills = 12, firstkill = 0.91, fkPlatz = 10, fkVon = 22, fkAnteil = 84.6, fkKaempfe = 4, fkMenge = 204051, movement = 0.96 },   -- Balren · Average 48,0 % (12 Kills) · Erst-Kill Platz 10/22 · Movement -4,0 %
    ["beaybewhy"] = { average = 0.90, firstkill = 0.90, movement = 0.94 },   -- Beaybewhy · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["bigboysushi"] = { firstkill = 0.90, fkPlatz = 11, fkVon = 22, fkAnteil = 79.0, fkKaempfe = 2, fkMenge = 206268, average = 0.88, movement = 0.85 },   -- Bigboysushi · Erst-Kill Platz 11/22 · uebernommen aus Nebenkey: Average, Movement
    ["blitzfaust"] = { average = 0.90, avgMedian = 30.5, avgKills = 10, firstkill = 0.93, fkPlatz = 8, fkVon = 22, fkAnteil = 87.5, fkKaempfe = 2, fkMenge = 206721, movement = 0.94 },   -- Blitzfaust · Average 30,5 % (10 Kills) · Erst-Kill Platz 8/22 · Movement -6,0 %
    ["cep"] = { average = 0.95, avgMedian = 64.0, avgKills = 5, firstkill = 0.95, fkPlatz = 6, fkVon = 22, fkAnteil = 89.3, fkKaempfe = 4, fkMenge = 217097, movement = 0.95 },   -- Cep · Average 64,0 % (5 Kills) · Erst-Kill Platz 6/22 · Movement -5,0 %
    ["cheliia"] = { average = 0.93, avgMedian = 52.0, avgKills = 12, firstkill = 0.92, fkPlatz = 9, fkVon = 22, fkAnteil = 85.8, fkKaempfe = 3, fkMenge = 187664, movement = 0.90 },   -- Cheliia · Average 52,0 % (12 Kills) · Erst-Kill Platz 9/22 · Movement -10,0 %
    ["dranash"] = { movement = 0.93 },   -- Dránash · Movement -7,0 %
    ["enshirou"] = { average = 0.91, avgMedian = 37.0, avgKills = 8, firstkill = 0.90, fkPlatz = 12, fkVon = 22, fkAnteil = 78.6, fkKaempfe = 3, fkMenge = 183894, movement = 0.88 },   -- Enshirou · Average 37,0 % (8 Kills) · Erst-Kill Platz 12/22 · Movement -12,0 %
    ["exorzist"] = { average = 0.88, avgMedian = 22.5, avgKills = 10, firstkill = 0.92, fkPlatz = 9, fkVon = 22, fkAnteil = 75.6, fkKaempfe = 4, fkMenge = 329954, movement = 0.95 },   -- Exorzist · Average 22,5 % (10 Kills) · Erst-Kill Platz 9/22 von Hand · Movement -5,0 %
    ["exudes"] = { average = 0.90, avgMedian = 35.0, avgKills = 5, firstkill = 0.99, fkPlatz = 2, fkVon = 22, fkAnteil = 100.0, fkKaempfe = 1, fkMenge = 261388, movement = 0.96 },   -- Exudes · Average 35,0 % (5 Kills) · Erst-Kill Platz 2/22 · Movement -4,0 %
    ["garshu"] = { average = 0.88, avgMedian = 19.0, avgKills = 12, firstkill = 0.86, fkPlatz = 16, fkVon = 22, fkAnteil = 75.0, fkKaempfe = 4, fkMenge = 190873, movement = 0.92 },   -- Garshû · Average 19,0 % (12 Kills) · Erst-Kill Platz 16/22 · Movement -8,0 %
    ["gweni"] = { average = 0.85, avgMedian = 2.0, avgKills = 4, firstkill = 0.94, fkPlatz = 7, fkVon = 22, fkAnteil = 88.7, fkKaempfe = 4, fkMenge = 199003, movement = 0.97 },   -- Gwêni · Average 2,0 % (4 Kills) · Erst-Kill Platz 7/22 · Movement -3,0 %
    ["hyperhardw"] = { average = 0.87, avgMedian = 16.0, avgKills = 12, firstkill = 0.89, fkPlatz = 13, fkVon = 22, fkAnteil = 78.2, fkKaempfe = 3, fkMenge = 166480, movement = 0.93 },   -- Hyperhardw · Average 16,0 % (12 Kills) · Erst-Kill Platz 13/22 · Movement -7,0 %
    ["indydrakes"] = { average = 0.88, avgMedian = 20.0, avgKills = 12, firstkill = 0.83, fkPlatz = 19, fkVon = 22, fkAnteil = 71.9, fkKaempfe = 3, fkMenge = 152976, movement = 0.99 },   -- Indydrakes · Average 20,0 % (12 Kills) · Erst-Kill Platz 19/22 · Movement -1,0 %
    ["jekyl"] = { firstkill = 0.82, fkPlatz = 20, fkVon = 22, fkAnteil = 69.2, fkKaempfe = 1, fkMenge = 180751, average = 0.90, movement = 0.94 },   -- Jekyl · Erst-Kill Platz 20/22 · Ersatz aus Kader-Median: Average, Movement
    ["jirylock"] = { average = 0.87, avgMedian = 13.0, avgKills = 12, movement = 0.95, firstkill = 0.90 },   -- Jirylock · Average 13,0 % (12 Kills) · Movement -5,0 % · Ersatz aus Kader-Median: Erst-Kill
    ["merlon"] = { average = 0.96, avgMedian = 75.0, avgKills = 12, firstkill = 0.96, fkPlatz = 5, fkVon = 22, fkAnteil = 89.7, fkKaempfe = 4, fkMenge = 211328, movement = 0.93 },   -- Merlón · Average 75,0 % (12 Kills) · Erst-Kill Platz 5/22 · Movement -7,0 %
    ["neyzxd"] = { average = 0.92, avgMedian = 48.5, avgKills = 8, movement = 0.90, firstkill = 0.90 },   -- Neyzxd · Average 48,5 % (8 Kills) · Movement -10,0 % · Ersatz aus Kader-Median: Erst-Kill
    ["notam"] = { average = 0.86, avgMedian = 4.0, avgKills = 7, firstkill = 0.84, fkPlatz = 18, fkVon = 22, fkAnteil = 74.7, fkKaempfe = 4, fkMenge = 170184, movement = 0.90 },   -- Notam · Average 4,0 % (7 Kills) · Erst-Kill Platz 18/22 · Movement -10,0 %
    ["ophrys"] = { average = 0.89, avgMedian = 28.0, avgKills = 12, firstkill = 0.86, fkPlatz = 16, fkVon = 22, fkAnteil = 63.7, fkKaempfe = 4, fkMenge = 271314, movement = 0.88 },   -- Ophrys · Average 28,0 % (12 Kills) · Erst-Kill Platz 16/22 von Hand · Movement -12,0 %
    ["palaball"] = { firstkill = 0.84, fkPlatz = 18, fkVon = 22, movement = 0.97, average = 0.90 },   -- Palaball · Erst-Kill Platz 18/22 von Hand · Movement -3,0 % · Ersatz aus Kader-Median: Average
    ["rone"] = { firstkill = 0.82, average = 0.90, movement = 0.94 },   -- Rone · uebernommen aus Nebenkey: Erst-Kill · Ersatz aus Kader-Median: Average, Movement
    ["setupx"] = { movement = 0.95 },   -- Setupx · Movement -5,0 %
    ["sikkz"] = { average = 0.98, avgMedian = 90.0, avgKills = 12, firstkill = 0.97, fkPlatz = 4, fkVon = 22, fkAnteil = 90.0, fkKaempfe = 4, fkMenge = 215704, movement = 0.93 },   -- Sikkz · Average 90,0 % (12 Kills) · Erst-Kill Platz 4/22 · Movement -7,0 %
    ["silanhunt"] = { average = 0.93, avgMedian = 54.0, avgKills = 10, firstkill = 0.87, fkPlatz = 15, fkVon = 22, fkAnteil = 75.1, fkKaempfe = 4, fkMenge = 177886, movement = 0.98 },   -- Silanhunt · Average 54,0 % (10 Kills) · Erst-Kill Platz 15/22 · Movement -2,0 %
    ["thunderdebbo"] = { average = 0.96, avgMedian = 72.0, avgKills = 5, firstkill = 0.88, fkPlatz = 14, fkVon = 22, fkAnteil = 54.1, fkKaempfe = 4, fkMenge = 245802, movement = 0.94 },   -- Thunderdebbo · Average 72,0 % (5 Kills) · Erst-Kill Platz 14/22 von Hand · Movement -6,0 %
    ["tobii"] = { average = 1.00, avgMedian = 99.0, avgKills = 12, firstkill = 1.00, fkPlatz = 1, fkVon = 22, fkAnteil = 100.0, fkKaempfe = 4, fkMenge = 447149, movement = 0.99 },   -- Tobii · Average 99,0 % (12 Kills) · Erst-Kill Platz 1/22 von Hand · Movement -1,0 %
    ["twosocks"] = { average = 0.88, avgMedian = 17.0, avgKills = 12, firstkill = 0.98, fkPlatz = 3, fkVon = 22, fkAnteil = 95.6, fkKaempfe = 1, fkMenge = 207719, movement = 0.85 },   -- Twosocks · Average 17,0 % (12 Kills) · Erst-Kill Platz 3/22 · Movement -15,0 %
    ["vilarie"] = { average = 0.92, avgMedian = 49.0, avgKills = 7, firstkill = 0.85, fkPlatz = 17, fkVon = 22, fkAnteil = 74.7, fkKaempfe = 1, fkMenge = 195258, movement = 0.87 },   -- Vilarie · Average 49,0 % (7 Kills) · Erst-Kill Platz 17/22 · Movement -13,0 %
}