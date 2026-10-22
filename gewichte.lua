-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 22.10.2026 23:59

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
ns.LEISTUNG_KADERSCHNITT = 49.5
ns.LEISTUNG_SPIELER = {
    ["auriga"] = { average = 0.92, firstkill = 0.92, movement = 0.91 },   -- Auriga · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["balren"] = { average = 0.93, avgMedian = 51.0, avgKills = 12, firstkill = 0.94, fkPlatz = 8, fkVon = 25, fkAnteil = 87.2, fkKaempfe = 6, fkMenge = 207919, movement = 0.96 },   -- Balren · Average 51,0 % (12 Kills) · Erst-Kill Platz 8/25 · Movement -4,0 %
    ["bigboysushi"] = { firstkill = 0.89, fkPlatz = 14, fkVon = 25, fkAnteil = 79.0, fkKaempfe = 2, fkMenge = 206268, average = 0.88, movement = 0.89 },   -- Bigboysushi · Erst-Kill Platz 14/25 · uebernommen aus Nebenkey: Average, Movement
    ["blitzfaust"] = { average = 0.91, avgMedian = 38.0, avgKills = 11, firstkill = 0.88, fkPlatz = 16, fkVon = 25, fkAnteil = 78.1, fkKaempfe = 3, fkMenge = 196202, movement = 0.88 },   -- Blitzfaust · Average 38,0 % (11 Kills) · Erst-Kill Platz 16/25 · Movement -12,0 %
    ["cep"] = { average = 0.97, avgMedian = 77.0, avgKills = 6, firstkill = 0.96, fkPlatz = 6, fkVon = 25, fkAnteil = 92.6, fkKaempfe = 5, fkMenge = 225031, movement = 0.92 },   -- Cep · Average 77,0 % (6 Kills) · Erst-Kill Platz 6/25 · Movement -8,0 %
    ["cheliia"] = { average = 0.91, avgMedian = 40.5, avgKills = 12, firstkill = 0.93, fkPlatz = 9, fkVon = 25, fkAnteil = 84.8, fkKaempfe = 5, fkMenge = 205959, movement = 0.90 },   -- Cheliia · Average 40,5 % (12 Kills) · Erst-Kill Platz 9/25 · Movement -10,0 %
    ["dranash"] = { movement = 0.92 },   -- Dránash · Movement -8,0 %
    ["enshirou"] = { average = 0.90, avgMedian = 36.0, avgKills = 9, firstkill = 0.84, fkPlatz = 20, fkVon = 25, fkAnteil = 76.8, fkKaempfe = 4, fkMenge = 183170, movement = 0.85 },   -- Enshirou · Average 36,0 % (9 Kills) · Erst-Kill Platz 20/25 · Movement -15,0 %
    ["exorzist"] = { average = 0.94, avgMedian = 57.0, avgKills = 10, firstkill = 0.93, fkPlatz = 9, fkVon = 25, fkAnteil = 75.1, fkKaempfe = 6, fkMenge = 359051, movement = 0.91 },   -- Exorzist · Average 57,0 % (10 Kills) · Erst-Kill Platz 9/25 von Hand · Movement -9,0 %
    ["exudes"] = { average = 0.92, avgMedian = 45.0, avgKills = 6, firstkill = 0.99, fkPlatz = 2, fkVon = 25, fkAnteil = 100.0, fkKaempfe = 1, fkMenge = 261388, movement = 0.93 },   -- Exudes · Average 45,0 % (6 Kills) · Erst-Kill Platz 2/25 · Movement -7,0 %
    ["garshu"] = { average = 0.93, avgMedian = 53.0, avgKills = 12, firstkill = 0.90, fkPlatz = 13, fkVon = 25, fkAnteil = 79.1, fkKaempfe = 6, fkMenge = 194915, movement = 0.92 },   -- Garshû · Average 53,0 % (12 Kills) · Erst-Kill Platz 13/25 · Movement -8,0 %
    ["gweni"] = { average = 0.85, avgMedian = 3.0, avgKills = 4, firstkill = 0.95, fkPlatz = 7, fkVon = 25, fkAnteil = 88.7, fkKaempfe = 4, fkMenge = 199003, movement = 0.96 },   -- Gwêni · Average 3,0 % (4 Kills) · Erst-Kill Platz 7/25 · Movement -4,0 %
    ["hyperhardw"] = { average = 0.96, avgMedian = 76.5, avgKills = 12, firstkill = 0.93, fkPlatz = 10, fkVon = 25, fkAnteil = 82.0, fkKaempfe = 5, fkMenge = 227563, movement = 0.89 },   -- Hyperhardw · Average 76,5 % (12 Kills) · Erst-Kill Platz 10/25 · Movement -11,0 %
    ["indydrakes"] = { average = 0.91, avgMedian = 42.5, avgKills = 12, firstkill = 0.83, fkPlatz = 21, fkVon = 25, fkAnteil = 76.2, fkKaempfe = 5, fkMenge = 194172, movement = 0.99 },   -- Indydrakes · Average 42,5 % (12 Kills) · Erst-Kill Platz 21/25 · Movement -1,0 %
    ["iowol"] = { firstkill = 0.88, fkPlatz = 15, fkVon = 25, fkAnteil = 78.5, fkKaempfe = 1, fkMenge = 255311, average = 0.88, movement = 0.89 },   -- Iòwól · Erst-Kill Platz 15/25 · uebernommen aus Nebenkey: Average, Movement
    ["jekyl"] = { firstkill = 0.82, fkPlatz = 23, fkVon = 25, fkAnteil = 69.2, fkKaempfe = 1, fkMenge = 180751, movement = 1.00, average = 0.92 },   -- Jekyl · Erst-Kill Platz 23/25 · uebernommen aus Nebenkey: Movement · Ersatz aus Kader-Median: Average
    ["jirylock"] = { average = 0.93, avgMedian = 50.0, avgKills = 11, firstkill = 0.86, fkPlatz = 18, fkVon = 25, fkAnteil = 77.2, fkKaempfe = 1, fkMenge = 187629, movement = 0.89 },   -- Jirylock · Average 50,0 % (11 Kills) · Erst-Kill Platz 18/25 · Movement -11,0 %
    ["jonkos"] = { average = 0.92, firstkill = 0.92, movement = 0.91 },   -- Jonkos · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["narande"] = { average = 0.92, firstkill = 0.92, movement = 0.91 },   -- Narande · Ersatz aus Kader-Median: Average, Erst-Kill, Movement
    ["neyzxd"] = { average = 0.95, avgMedian = 64.0, avgKills = 11, firstkill = 0.92, fkPlatz = 11, fkVon = 25, fkAnteil = 79.9, fkKaempfe = 2, fkMenge = 228264, movement = 0.88 },   -- Neyzxd · Average 64,0 % (11 Kills) · Erst-Kill Platz 11/25 · Movement -12,0 %
    ["notam"] = { average = 0.92, avgMedian = 49.0, avgKills = 7, firstkill = 0.91, fkPlatz = 12, fkVon = 25, fkAnteil = 79.1, fkKaempfe = 6, fkMenge = 188823, movement = 0.87 },   -- Notam · Average 49,0 % (7 Kills) · Erst-Kill Platz 12/25 · Movement -13,0 %
    ["ophrys"] = { average = 0.89, avgMedian = 28.0, avgKills = 12, firstkill = 0.88, fkPlatz = 16, fkVon = 25, fkAnteil = 65.9, fkKaempfe = 6, fkMenge = 290646, movement = 0.89 },   -- Ophrys · Average 28,0 % (12 Kills) · Erst-Kill Platz 16/25 von Hand · Movement -11,0 %
    ["rone"] = { movement = 1.00, firstkill = 0.82, average = 0.92 },   -- Rone · uebernommen aus Nebenkey: Erst-Kill · Ersatz aus Kader-Median: Average
    ["shywen"] = { average = 0.92, avgMedian = 44.0, avgKills = 1, firstkill = 0.97, fkPlatz = 5, fkVon = 25, fkAnteil = 93.0, fkKaempfe = 1, fkMenge = 302523, movement = 0.91 },   -- Shywen · Average 44,0 % (1 Kills) · Erst-Kill Platz 5/25 · Ersatz aus Kader-Median: Movement
    ["sikkz"] = { average = 0.98, avgMedian = 89.0, avgKills = 12, firstkill = 0.97, fkPlatz = 4, fkVon = 25, fkAnteil = 93.3, fkKaempfe = 6, fkMenge = 230781, movement = 0.95 },   -- Sikkz · Average 89,0 % (12 Kills) · Erst-Kill Platz 4/25 · Movement -5,0 %
    ["silanhunt"] = { average = 0.94, avgMedian = 62.0, avgKills = 11, firstkill = 0.85, fkPlatz = 19, fkVon = 25, fkAnteil = 77.0, fkKaempfe = 6, fkMenge = 207486, movement = 0.95 },   -- Silanhunt · Average 62,0 % (11 Kills) · Erst-Kill Platz 19/25 · Movement -5,0 %
    ["thunderdebbo"] = { average = 0.92, avgMedian = 44.5, avgKills = 12, firstkill = 0.89, fkPlatz = 14, fkVon = 25, fkAnteil = 56.7, fkKaempfe = 6, fkMenge = 263861, movement = 0.91 },   -- Thunderdebbo · Average 44,5 % (12 Kills) · Erst-Kill Platz 14/25 von Hand · Movement -9,0 %
    ["tobii"] = { average = 1.00, avgMedian = 99.0, avgKills = 12, firstkill = 1.00, fkPlatz = 1, fkVon = 25, fkAnteil = 100.0, fkKaempfe = 6, fkMenge = 476461, movement = 0.99 },   -- Tobii · Average 99,0 % (12 Kills) · Erst-Kill Platz 1/25 von Hand · Movement -1,0 %
    ["twosocks"] = { average = 0.88, avgMedian = 17.0, avgKills = 11, firstkill = 0.98, fkPlatz = 3, fkVon = 25, fkAnteil = 94.0, fkKaempfe = 2, fkMenge = 216162, movement = 0.89 },   -- Twosocks · Average 17,0 % (11 Kills) · Erst-Kill Platz 3/25 · Movement -11,0 %
    ["vilarie"] = { average = 0.95, avgMedian = 68.0, avgKills = 3, firstkill = 0.87, fkPlatz = 17, fkVon = 25, fkAnteil = 77.4, fkKaempfe = 2, fkMenge = 228017, movement = 0.89 },   -- Vilarie · Average 68,0 % (3 Kills) · Erst-Kill Platz 17/25 · Movement -11,0 %
}