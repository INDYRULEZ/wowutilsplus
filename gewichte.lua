-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 19.10.2026 20:18

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
    [2] = 0.50,   -- Upgrade
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
ns.LEISTUNG_KADERSCHNITT = 46.0
ns.LEISTUNG_SPIELER = {
    ["balren"] = { average = 0.92, avgMedian = 47.5, avgKills = 12, firstkill = 0.95, fkPlatz = 7, fkVon = 23, fkAnteil = 85.4, fkKaempfe = 5, fkMenge = 207457, movement = 0.96 },   -- Balren · Average 47,5 % (12 Kills) · Erst-Kill Platz 7/23 · Movement -4,0 %
    ["beaybewhy"] = { movement = 1.00, average = 0.92, firstkill = 0.90 },   -- Beaybewhy · Ersatz aus Kader-Median: Average, Erst-Kill
    ["bigboysushi"] = { firstkill = 0.92, fkPlatz = 10, fkVon = 23, fkAnteil = 79.0, fkKaempfe = 2, fkMenge = 206268, average = 0.88, movement = 0.89 },   -- Bigboysushi · Erst-Kill Platz 10/23 · uebernommen aus Nebenkey: Average, Movement
    ["blitzfaust"] = { average = 0.91, avgMedian = 36.5, avgKills = 12, firstkill = 0.91, fkPlatz = 11, fkVon = 23, fkAnteil = 78.1, fkKaempfe = 3, fkMenge = 196202, movement = 0.88 },   -- Blitzfaust · Average 36,5 % (12 Kills) · Erst-Kill Platz 11/23 · Movement -12,0 %
    ["cep"] = { average = 0.94, avgMedian = 63.0, avgKills = 5, firstkill = 0.96, fkPlatz = 5, fkVon = 23, fkAnteil = 89.3, fkKaempfe = 4, fkMenge = 217097, movement = 0.92 },   -- Cep · Average 63,0 % (5 Kills) · Erst-Kill Platz 5/23 · Movement -8,0 %
    ["cheliia"] = { average = 0.91, avgMedian = 40.5, avgKills = 12, firstkill = 0.94, fkPlatz = 8, fkVon = 23, fkAnteil = 85.3, fkKaempfe = 4, fkMenge = 196812, movement = 0.90 },   -- Cheliia · Average 40,5 % (12 Kills) · Erst-Kill Platz 8/23 · Movement -10,0 %
    ["depressionen"] = { movement = 0.88 },   -- Depressionen · Movement -12,0 %
    ["dranash"] = { movement = 0.92 },   -- Dránash · Movement -8,0 %
    ["enshirou"] = { average = 0.90, avgMedian = 36.0, avgKills = 9, firstkill = 0.88, fkPlatz = 14, fkVon = 23, fkAnteil = 76.8, fkKaempfe = 4, fkMenge = 183170, movement = 0.85 },   -- Enshirou · Average 36,0 % (9 Kills) · Erst-Kill Platz 14/23 · Movement -15,0 %
    ["exorzist"] = { average = 0.94, avgMedian = 57.0, avgKills = 10, firstkill = 0.93, fkPlatz = 9, fkVon = 23, fkAnteil = 75.1, fkKaempfe = 5, fkMenge = 340037, movement = 0.91 },   -- Exorzist · Average 57,0 % (10 Kills) · Erst-Kill Platz 9/23 von Hand · Movement -9,0 %
    ["exudes"] = { average = 0.92, avgMedian = 45.0, avgKills = 6, firstkill = 0.99, fkPlatz = 2, fkVon = 23, fkAnteil = 100.0, fkKaempfe = 1, fkMenge = 261388, movement = 0.93 },   -- Exudes · Average 45,0 % (6 Kills) · Erst-Kill Platz 2/23 · Movement -7,0 %
    ["garshu"] = { average = 0.93, avgMedian = 53.0, avgKills = 12, firstkill = 0.87, fkPlatz = 15, fkVon = 23, fkAnteil = 76.7, fkKaempfe = 5, fkMenge = 191736, movement = 0.92 },   -- Garshû · Average 53,0 % (12 Kills) · Erst-Kill Platz 15/23 · Movement -8,0 %
    ["gweni"] = { average = 0.85, avgMedian = 3.0, avgKills = 4, firstkill = 0.95, fkPlatz = 6, fkVon = 23, fkAnteil = 88.7, fkKaempfe = 4, fkMenge = 199003, movement = 0.96 },   -- Gwêni · Average 3,0 % (4 Kills) · Erst-Kill Platz 6/23 · Movement -4,0 %
    ["hyperhardw"] = { average = 0.93, avgMedian = 54.5, avgKills = 12, firstkill = 0.93, fkPlatz = 9, fkVon = 23, fkAnteil = 80.1, fkKaempfe = 4, fkMenge = 197021, movement = 0.89 },   -- Hyperhardw · Average 54,5 % (12 Kills) · Erst-Kill Platz 9/23 · Movement -11,0 %
    ["indydrakes"] = { average = 0.91, avgMedian = 39.5, avgKills = 12, firstkill = 0.83, fkPlatz = 20, fkVon = 23, fkAnteil = 74.0, fkKaempfe = 4, fkMenge = 173574, movement = 0.99 },   -- Indydrakes · Average 39,5 % (12 Kills) · Erst-Kill Platz 20/23 · Movement -1,0 %
    ["jekyl"] = { firstkill = 0.82, fkPlatz = 21, fkVon = 23, fkAnteil = 69.2, fkKaempfe = 1, fkMenge = 180751, movement = 1.00, average = 0.92 },   -- Jekyl · Erst-Kill Platz 21/23 · uebernommen aus Nebenkey: Movement · Ersatz aus Kader-Median: Average
    ["jirylock"] = { average = 0.90, avgMedian = 35.5, avgKills = 12, firstkill = 0.90, fkPlatz = 12, fkVon = 23, fkAnteil = 77.2, fkKaempfe = 1, fkMenge = 187629, movement = 0.89 },   -- Jirylock · Average 35,5 % (12 Kills) · Erst-Kill Platz 12/23 · Movement -11,0 %
    ["neyzxd"] = { average = 0.95, avgMedian = 68.5, avgKills = 10, firstkill = 0.89, fkPlatz = 13, fkVon = 23, fkAnteil = 76.9, fkKaempfe = 1, fkMenge = 186755, movement = 0.88 },   -- Neyzxd · Average 68,5 % (10 Kills) · Erst-Kill Platz 13/23 · Movement -12,0 %
    ["notam"] = { average = 0.91, avgMedian = 41.0, avgKills = 7, firstkill = 0.86, fkPlatz = 16, fkVon = 23, fkAnteil = 76.4, fkKaempfe = 5, fkMenge = 177653, movement = 0.87 },   -- Notam · Average 41,0 % (7 Kills) · Erst-Kill Platz 16/23 · Movement -13,0 %
    ["ophrys"] = { average = 0.89, avgMedian = 28.0, avgKills = 12, firstkill = 0.86, fkPlatz = 16, fkVon = 23, fkAnteil = 63.9, fkKaempfe = 5, fkMenge = 271986, movement = 0.89 },   -- Ophrys · Average 28,0 % (12 Kills) · Erst-Kill Platz 16/23 von Hand · Movement -11,0 %
    ["palaball"] = { firstkill = 0.85, fkPlatz = 18, fkVon = 23, movement = 1.00, average = 0.92 },   -- Palaball · Erst-Kill Platz 18/23 von Hand · Ersatz aus Kader-Median: Average
    ["rone"] = { movement = 1.00, firstkill = 0.82, average = 0.92 },   -- Rone · uebernommen aus Nebenkey: Erst-Kill · Ersatz aus Kader-Median: Average
    ["shywen"] = { average = 0.92, firstkill = 0.90, movement = 0.92 },   -- Shywen · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["sikkz"] = { average = 0.98, avgMedian = 89.0, avgKills = 12, firstkill = 0.97, fkPlatz = 4, fkVon = 23, fkAnteil = 93.0, fkKaempfe = 5, fkMenge = 218560, movement = 0.95 },   -- Sikkz · Average 89,0 % (12 Kills) · Erst-Kill Platz 4/23 · Movement -5,0 %
    ["silanhunt"] = { average = 0.94, avgMedian = 63.0, avgKills = 11, firstkill = 0.85, fkPlatz = 17, fkVon = 23, fkAnteil = 76.2, fkKaempfe = 5, fkMenge = 193605, movement = 0.95 },   -- Silanhunt · Average 63,0 % (11 Kills) · Erst-Kill Platz 17/23 · Movement -5,0 %
    ["thunderdebbo"] = { average = 0.92, avgMedian = 46.0, avgKills = 11, firstkill = 0.88, fkPlatz = 14, fkVon = 23, fkAnteil = 55.4, fkKaempfe = 5, fkMenge = 255859, movement = 0.91 },   -- Thunderdebbo · Average 46,0 % (11 Kills) · Erst-Kill Platz 14/23 von Hand · Movement -9,0 %
    ["tobii"] = { average = 1.00, avgMedian = 99.0, avgKills = 12, firstkill = 1.00, fkPlatz = 1, fkVon = 23, fkAnteil = 100.0, fkKaempfe = 5, fkMenge = 468595, movement = 0.99 },   -- Tobii · Average 99,0 % (12 Kills) · Erst-Kill Platz 1/23 von Hand · Movement -1,0 %
    ["twosocks"] = { average = 0.88, avgMedian = 20.0, avgKills = 12, firstkill = 0.98, fkPlatz = 3, fkVon = 23, fkAnteil = 94.0, fkKaempfe = 2, fkMenge = 216162, movement = 0.89 },   -- Twosocks · Average 20,0 % (12 Kills) · Erst-Kill Platz 3/23 · Movement -11,0 %
    ["vilarie"] = { average = 0.95, avgMedian = 68.0, avgKills = 3, firstkill = 0.84, fkPlatz = 19, fkVon = 23, fkAnteil = 74.7, fkKaempfe = 1, fkMenge = 195258, movement = 0.89 },   -- Vilarie · Average 68,0 % (3 Kills) · Erst-Kill Platz 19/23 · Movement -11,0 %
}