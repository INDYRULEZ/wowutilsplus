-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 02.10.2026 11:55

local _, ns = ...

ns.WEIGHTS = {
    HEALER  = { factor = 0.52 },
    TANK    = { factor = 1.15 },
    DAMAGER = { factor = 1.00 },
}

-- Faktor nach Wunschlisten-Priorität (1 = Best in Slot, 2 = Upgrade).
-- Nur diese beiden sind belegt; alles andere bleibt bei 1.00.
ns.WUNSCH = {
    [1] = 1.00,   -- Best in Slot
    [2] = 0.60,   -- Upgrade
}

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
--            der eigenen Gilde. 100er Log = 1.00, 0er Log = 0.90 (linear).
-- firstkill: Rangfolge in den mythischen Erst-Kills, Platz 1 ohne Abzug, letzter Platz -15 %.
-- movement:  von Hand auf der Seite gepflegt, dort als Abzug in Prozent
--            (hoechstens 20 %, also Faktor bis 0.80).
ns.LEISTUNG_AVG_ABZUG = 0.100
ns.LEISTUNG_KADERSCHNITT = 30.5
ns.LEISTUNG_SPIELER = {
    ["balren"] = { average = 0.93, avgMedian = 31.0, avgKills = 9, firstkill = 0.94, fkPlatz = 10, fkVon = 22, fkAnteil = 85.3, fkKaempfe = 4, fkMenge = 204026 },   -- Balren · Average 31,0 % (9 Kills) · Erst-Kill Platz 10/22
    ["bigboysushi"] = { firstkill = 0.92, fkPlatz = 12, fkVon = 22, fkAnteil = 79.1, fkKaempfe = 2, fkMenge = 205011 },   -- Bigboysushi · Erst-Kill Platz 12/22
    ["blitzfaust"] = { average = 0.94, avgMedian = 43.0, avgKills = 4, firstkill = 0.95, fkPlatz = 8, fkVon = 22, fkAnteil = 87.5, fkKaempfe = 2, fkMenge = 206535 },   -- Blitzfaust · Average 43,0 % (4 Kills) · Erst-Kill Platz 8/22
    ["cep"] = { average = 0.93, avgMedian = 30.0, avgKills = 7, firstkill = 0.96, fkPlatz = 6, fkVon = 22, fkAnteil = 89.3, fkKaempfe = 4, fkMenge = 216898 },   -- Cep · Average 30,0 % (7 Kills) · Erst-Kill Platz 6/22
    ["cheliia"] = { average = 0.94, avgMedian = 37.5, avgKills = 8, firstkill = 0.94, fkPlatz = 9, fkVon = 22, fkAnteil = 85.7, fkKaempfe = 3, fkMenge = 187583 },   -- Cheliia · Average 37,5 % (8 Kills) · Erst-Kill Platz 9/22
    ["enshirou"] = { average = 0.92, avgMedian = 19.0, avgKills = 8, firstkill = 0.91, fkPlatz = 13, fkVon = 22, fkAnteil = 78.8, fkKaempfe = 3, fkMenge = 183840 },   -- Enshirou · Average 19,0 % (8 Kills) · Erst-Kill Platz 13/22
    ["exorzist"] = { average = 0.94, avgMedian = 40.0, avgKills = 9, firstkill = 0.92, fkPlatz = 12, fkVon = 22, fkAnteil = 75.6, fkKaempfe = 4, fkMenge = 329954 },   -- Exorzist · Average 40,0 % (9 Kills) · Erst-Kill Platz 12/22 von Hand
    ["exudes"] = { average = 0.93, avgMedian = 29.5, avgKills = 2, firstkill = 0.99, fkPlatz = 2, fkVon = 22, fkAnteil = 100.0, fkKaempfe = 1, fkMenge = 261258 },   -- Exudes · Average 29,5 % (2 Kills) · Erst-Kill Platz 2/22
    ["garshu"] = { average = 0.92, avgMedian = 24.0, avgKills = 9, firstkill = 0.89, fkPlatz = 16, fkVon = 22, fkAnteil = 75.0, fkKaempfe = 4, fkMenge = 190778 },   -- Garshû · Average 24,0 % (9 Kills) · Erst-Kill Platz 16/22
    ["gweni"] = { average = 0.92, avgMedian = 23.0, avgKills = 9, firstkill = 0.96, fkPlatz = 7, fkVon = 22, fkAnteil = 88.9, fkKaempfe = 4, fkMenge = 197025 },   -- Gwêni · Average 23,0 % (9 Kills) · Erst-Kill Platz 7/22
    ["hyperhardw"] = { average = 0.93, avgMedian = 25.0, avgKills = 8, firstkill = 0.91, fkPlatz = 14, fkVon = 22, fkAnteil = 77.5, fkKaempfe = 3, fkMenge = 164303 },   -- Hyperhardw · Average 25,0 % (8 Kills) · Erst-Kill Platz 14/22
    ["indydrakes"] = { average = 0.90, avgMedian = 4.0, avgKills = 8, firstkill = 0.87, fkPlatz = 19, fkVon = 22, fkAnteil = 72.3, fkKaempfe = 3, fkMenge = 153253 },   -- Indydrakes · Average 4,0 % (8 Kills) · Erst-Kill Platz 19/22
    ["jekyl"] = { average = 0.90, avgMedian = 1.0, avgKills = 1, firstkill = 0.86, fkPlatz = 20, fkVon = 22, fkAnteil = 67.9, fkKaempfe = 1, fkMenge = 177508 },   -- Jekyl · Average 1,0 % (1 Kills) · Erst-Kill Platz 20/22
    ["merlon"] = { average = 0.95, avgMedian = 52.0, avgKills = 9, firstkill = 0.97, fkPlatz = 5, fkVon = 22, fkAnteil = 89.8, fkKaempfe = 4, fkMenge = 211056 },   -- Merlón · Average 52,0 % (9 Kills) · Erst-Kill Platz 5/22
    ["neyzxd"] = { average = 0.97, avgMedian = 67.0, avgKills = 1 },   -- Neyzxd · Average 67,0 % (1 Kills)
    ["notam"] = { average = 0.91, avgMedian = 6.0, avgKills = 9, firstkill = 0.89, fkPlatz = 17, fkVon = 22, fkAnteil = 74.9, fkKaempfe = 4, fkMenge = 169359 },   -- Notam · Average 6,0 % (9 Kills) · Erst-Kill Platz 17/22
    ["ophrys"] = { average = 0.94, avgMedian = 45.0, avgKills = 9, firstkill = 0.88, fkPlatz = 18, fkVon = 22, fkAnteil = 63.7, fkKaempfe = 4, fkMenge = 271314 },   -- Ophrys · Average 45,0 % (9 Kills) · Erst-Kill Platz 18/22 von Hand
    ["palaball"] = { firstkill = 0.90, fkPlatz = 18, fkVon = 27 },   -- palaball · Erst-Kill Platz 18/27 von Hand
    ["palacetamol"] = { average = 0.99, avgMedian = 95.0, avgKills = 1, firstkill = 0.93, fkPlatz = 14, fkVon = 27 },   -- Palacetamol · Average 95,0 % (1 Kills) · Erst-Kill Platz 14/27 von Hand
    ["schmeckies"] = { average = 0.94, avgMedian = 40.0, avgKills = 1 },   -- Schmeckies · Average 40,0 % (1 Kills)
    ["sikkz"] = { average = 0.96, avgMedian = 64.0, avgKills = 9, firstkill = 0.98, fkPlatz = 4, fkVon = 22, fkAnteil = 90.5, fkKaempfe = 4, fkMenge = 215172 },   -- Sikkz · Average 64,0 % (9 Kills) · Erst-Kill Platz 4/22
    ["silanhunt"] = { average = 0.91, avgMedian = 6.0, avgKills = 9, firstkill = 0.93, fkPlatz = 11, fkVon = 22, fkAnteil = 79.5, fkKaempfe = 4, fkMenge = 187334 },   -- Silanhunt · Average 6,0 % (9 Kills) · Erst-Kill Platz 11/22
    ["thunderdebbo"] = { average = 0.91, avgMedian = 12.0, avgKills = 8, firstkill = 0.91, fkPlatz = 14, fkVon = 22, fkAnteil = 54.1, fkKaempfe = 4, fkMenge = 245802 },   -- Thunderdebbo · Average 12,0 % (8 Kills) · Erst-Kill Platz 14/22 von Hand
    ["tobii"] = { average = 1.00, avgMedian = 99.0, avgKills = 8, firstkill = 1.00, fkPlatz = 1, fkVon = 22, fkAnteil = 100.0, fkKaempfe = 4, fkMenge = 447149 },   -- Tobii · Average 99,0 % (8 Kills) · Erst-Kill Platz 1/22 von Hand
    ["twosocks"] = { average = 0.92, avgMedian = 23.0, avgKills = 3, firstkill = 0.99, fkPlatz = 3, fkVon = 22, fkAnteil = 95.6, fkKaempfe = 1, fkMenge = 207568 },   -- Twosocks · Average 23,0 % (3 Kills) · Erst-Kill Platz 3/22
    ["vilarie"] = { average = 0.95, avgMedian = 49.0, avgKills = 2, firstkill = 0.88, fkPlatz = 18, fkVon = 22, fkAnteil = 74.7, fkKaempfe = 1, fkMenge = 195189 },   -- Vilarie · Average 49,0 % (2 Kills) · Erst-Kill Platz 18/22
}