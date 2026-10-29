-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 29.10.2026 18:30

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
    ["auriga"] = { average = 0.93, firstkill = 0.91, movement = 0.91 },   -- Auriga · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["balren"] = { average = 0.93, avgMedian = 51.0, avgKills = 12, firstkill = 0.94, fkPlatz = 7, fkVon = 20, fkAnteil = 87.2, fkKaempfe = 6, fkMenge = 207919, movement = 0.94 },   -- Balren · Average 51,0 % (12 Kills) · Erst-Kill Platz 7/20 · Movement -6,0 %
    ["blitzfaust"] = { average = 0.90, avgMedian = 35.0, avgKills = 11, firstkill = 0.87, fkPlatz = 13, fkVon = 20, fkAnteil = 78.1, fkKaempfe = 3, fkMenge = 196202, movement = 0.88 },   -- Blitzfaust · Average 35,0 % (11 Kills) · Erst-Kill Platz 13/20 · Movement -12,0 %
    ["cep"] = { average = 0.96, avgMedian = 75.5, avgKills = 6, firstkill = 0.96, fkPlatz = 5, fkVon = 20, fkAnteil = 92.6, fkKaempfe = 5, fkMenge = 225031, movement = 0.90 },   -- Cep · Average 75,5 % (6 Kills) · Erst-Kill Platz 5/20 · Movement -10,0 %
    ["cheliia"] = { average = 0.90, avgMedian = 36.0, avgKills = 12, firstkill = 0.93, fkPlatz = 8, fkVon = 20, fkAnteil = 84.8, fkKaempfe = 5, fkMenge = 205959, movement = 0.90 },   -- Cheliia · Average 36,0 % (12 Kills) · Erst-Kill Platz 8/20 · Movement -10,0 %
    ["dranash"] = { average = 0.93, firstkill = 0.85, fkPlatz = 15, fkVon = 20, movement = 0.92 },   -- Dránash · Average 50,0 % von Hand · Erst-Kill Platz 15/20 von Hand · Movement -8,0 %
    ["enshirou"] = { average = 0.90, avgMedian = 36.0, avgKills = 9, firstkill = 0.83, fkPlatz = 17, fkVon = 20, fkAnteil = 76.8, fkKaempfe = 4, fkMenge = 183170, movement = 0.85 },   -- Enshirou · Average 36,0 % (9 Kills) · Erst-Kill Platz 17/20 · Movement -15,0 %
    ["exorzist"] = { average = 0.94, avgMedian = 57.0, avgKills = 10, firstkill = 0.91, fkPlatz = 10, fkVon = 20, fkAnteil = 75.1, fkKaempfe = 6, fkMenge = 359051, movement = 0.91 },   -- Exorzist · Average 57,0 % (10 Kills) · Erst-Kill Platz 10/20 von Hand · Movement -9,0 %
    ["garshu"] = { average = 0.93, avgMedian = 51.0, avgKills = 12, firstkill = 0.89, fkPlatz = 11, fkVon = 20, fkAnteil = 79.1, fkKaempfe = 6, fkMenge = 194915, movement = 0.90 },   -- Garshû · Average 51,0 % (12 Kills) · Erst-Kill Platz 11/20 · Movement -10,0 %
    ["gweni"] = { average = 0.85, avgMedian = 3.0, avgKills = 4, firstkill = 0.95, fkPlatz = 6, fkVon = 20, fkAnteil = 88.7, fkKaempfe = 4, fkMenge = 199003, movement = 0.96 },   -- Gwêni · Average 3,0 % (4 Kills) · Erst-Kill Platz 6/20 · Movement -4,0 %
    ["hayzm"] = { average = 0.93, firstkill = 0.91, movement = 0.91 },   -- Hayzm · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["hyperhardw"] = { average = 0.96, avgMedian = 70.5, avgKills = 12, firstkill = 0.92, fkPlatz = 9, fkVon = 20, fkAnteil = 82.0, fkKaempfe = 5, fkMenge = 227563, movement = 0.91 },   -- Hyperhardw · Average 70,5 % (12 Kills) · Erst-Kill Platz 9/20 · Movement -9,0 %
    ["indydrakes"] = { average = 0.91, avgMedian = 40.0, avgKills = 12, firstkill = 0.82, fkPlatz = 18, fkVon = 20, fkAnteil = 76.2, fkKaempfe = 5, fkMenge = 194172, movement = 0.98 },   -- Indydrakes · Average 40,0 % (12 Kills) · Erst-Kill Platz 18/20 · Movement -2,0 %
    ["iowol"] = { average = 0.87, avgMedian = 12.0, avgKills = 1, firstkill = 0.88, fkPlatz = 12, fkVon = 20, fkAnteil = 78.5, fkKaempfe = 1, fkMenge = 255311, movement = 0.90 },   -- Iòwól · Average 12,0 % (1 Kills) · Erst-Kill Platz 12/20 · Movement -10,0 %
    ["itchytoes"] = { average = 0.93, firstkill = 0.91, movement = 0.91 },   -- Itchytoes · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["jirylock"] = { average = 0.92, avgMedian = 46.0, avgKills = 11, firstkill = 0.85, fkPlatz = 15, fkVon = 20, fkAnteil = 77.2, fkKaempfe = 1, fkMenge = 187629, movement = 0.89 },   -- Jirylock · Average 46,0 % (11 Kills) · Erst-Kill Platz 15/20 · Movement -11,0 %
    ["neyzdk"] = { movement = 0.88, average = 0.93, firstkill = 0.91 },   -- Neyzdk · Movement -12,0 % · Ersatz aus Kader-Median: Average, Erst-Kill
    ["notam"] = { average = 0.92, avgMedian = 46.0, avgKills = 7, firstkill = 0.91, fkPlatz = 10, fkVon = 20, fkAnteil = 79.1, fkKaempfe = 6, fkMenge = 188823, movement = 0.87 },   -- Notam · Average 46,0 % (7 Kills) · Erst-Kill Platz 10/20 · Movement -13,0 %
    ["shywen"] = { average = 0.91, avgMedian = 39.0, avgKills = 1, firstkill = 0.97, fkPlatz = 4, fkVon = 20, fkAnteil = 93.0, fkKaempfe = 1, fkMenge = 302523, movement = 0.95 },   -- Shywen · Average 39,0 % (1 Kills) · Erst-Kill Platz 4/20 · Movement -5,0 %
    ["sikkz"] = { average = 0.98, avgMedian = 89.0, avgKills = 12, firstkill = 0.98, fkPlatz = 3, fkVon = 20, fkAnteil = 93.3, fkKaempfe = 6, fkMenge = 230781, movement = 0.94 },   -- Sikkz · Average 89,0 % (12 Kills) · Erst-Kill Platz 3/20 · Movement -6,0 %
    ["silanhunt"] = { average = 0.94, avgMedian = 58.0, avgKills = 11, firstkill = 0.84, fkPlatz = 16, fkVon = 20, fkAnteil = 77.0, fkKaempfe = 6, fkMenge = 207486, movement = 0.96 },   -- Silanhunt · Average 58,0 % (11 Kills) · Erst-Kill Platz 16/20 · Movement -4,0 %
    ["snoow"] = { average = 0.96, firstkill = 0.91, fkPlatz = 10, fkVon = 20 },   -- Snoow · Average 75,0 % von Hand · Erst-Kill Platz 10/20 von Hand
    ["thunderdebbo"] = { average = 0.92, avgMedian = 45.0, avgKills = 12, firstkill = 0.84, fkPlatz = 16, fkVon = 20, fkAnteil = 56.7, fkKaempfe = 6, fkMenge = 263861, movement = 0.91 },   -- Thunderdebbo · Average 45,0 % (12 Kills) · Erst-Kill Platz 16/20 von Hand · Movement -9,0 %
    ["tobii"] = { average = 1.00, avgMedian = 99.0, avgKills = 12, firstkill = 1.00, fkPlatz = 1, fkVon = 20, fkAnteil = 100.0, fkKaempfe = 6, fkMenge = 476461, movement = 0.98 },   -- Tobii · Average 99,0 % (12 Kills) · Erst-Kill Platz 1/20 von Hand · Movement -2,0 %
    ["twosocks"] = { firstkill = 0.99, fkPlatz = 2, fkVon = 20, fkAnteil = 94.0, fkKaempfe = 2, fkMenge = 216162, average = 0.87, movement = 0.90 },   -- Twosocks · Erst-Kill Platz 2/20 · uebernommen aus Nebenkey: Average, Movement
    ["vilarie"] = { average = 0.95, avgMedian = 68.0, avgKills = 3, firstkill = 0.86, fkPlatz = 14, fkVon = 20, fkAnteil = 77.4, fkKaempfe = 2, fkMenge = 228017, movement = 0.87 },   -- Vilarie · Average 68,0 % (3 Kills) · Erst-Kill Platz 14/20 · Movement -13,0 %
}