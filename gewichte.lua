-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 02.10.2026 09:56

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
-- average:   Median der Parse-Prozente, nur Kills der eigenen Gilde,
--            Zeitfenster 4 Wochen. 100er Log = 1.00, 0er Log = 0.90 (linear).
-- firstkill: Rangfolge in den mythischen Erst-Kills, Platz 1 ohne Abzug, letzter Platz -15 %.
-- movement:  von Hand auf der Seite gepflegt.
ns.LEISTUNG_AVG_ABZUG = 0.100
ns.LEISTUNG_KADERSCHNITT = 37.0
ns.LEISTUNG_SPIELER = {
    ["balren"] = { average = 0.94, avgMedian = 43.0, avgKills = 23, firstkill = 0.94, fkPlatz = 10, fkVon = 23, fkAnteil = 82.2, fkKaempfe = 5, fkDps = 199641 },   -- Balren · Average 43,0 % (23 Kills) · Erst-Kill Platz 10/23
    ["beaybewhy"] = { average = 0.92, avgMedian = 20.0, avgKills = 4, firstkill = 0.86, fkPlatz = 22, fkVon = 23, fkAnteil = 68.0, fkKaempfe = 1, fkDps = 118632 },   -- Beaybewhy · Average 20,0 % (4 Kills) · Erst-Kill Platz 22/23
    ["bigboysushi"] = { firstkill = 0.92, fkPlatz = 13, fkVon = 23, fkAnteil = 79.9, fkKaempfe = 3, fkDps = 174375 },   -- Bigboysushi · Erst-Kill Platz 13/23
    ["blitzfaust"] = { average = 0.94, avgMedian = 43.0, avgKills = 8, firstkill = 0.88, fkPlatz = 18, fkVon = 23, fkAnteil = 74.5, fkKaempfe = 3, fkDps = 194188 },   -- Blitzfaust · Average 43,0 % (8 Kills) · Erst-Kill Platz 18/23
    ["cep"] = { average = 0.94, avgMedian = 39.0, avgKills = 12, firstkill = 0.99, fkPlatz = 3, fkVon = 23, fkAnteil = 91.7, fkKaempfe = 5, fkDps = 207483 },   -- Cep · Average 39,0 % (12 Kills) · Erst-Kill Platz 3/23
    ["cheliia"] = { average = 0.97, avgMedian = 68.5, avgKills = 18, firstkill = 0.98, fkPlatz = 4, fkVon = 23, fkAnteil = 90.2, fkKaempfe = 3, fkDps = 187133 },   -- Cheliia · Average 68,5 % (18 Kills) · Erst-Kill Platz 4/23
    ["dranash"] = { average = 0.93, avgMedian = 29.0, avgKills = 16 },   -- Dránash · Average 29,0 % (16 Kills)
    ["enshirou"] = { average = 0.92, avgMedian = 22.0, avgKills = 11, firstkill = 0.93, fkPlatz = 12, fkVon = 23, fkAnteil = 80.5, fkKaempfe = 3, fkDps = 183545 },   -- Enshirou · Average 22,0 % (11 Kills) · Erst-Kill Platz 12/23
    ["exorzist"] = { average = 0.93, avgMedian = 31.0, avgKills = 23 },   -- Exorzist · Average 31,0 % (23 Kills)
    ["exudes"] = { average = 0.93, avgMedian = 32.0, avgKills = 9, firstkill = 0.97, fkPlatz = 5, fkVon = 23, fkAnteil = 89.6, fkKaempfe = 2, fkDps = 199376 },   -- Exudes · Average 32,0 % (9 Kills) · Erst-Kill Platz 5/23
    ["garshu"] = { average = 0.93, avgMedian = 30.0, avgKills = 16, firstkill = 0.91, fkPlatz = 15, fkVon = 23, fkAnteil = 76.5, fkKaempfe = 5, fkDps = 189242 },   -- Garshû · Average 30,0 % (16 Kills) · Erst-Kill Platz 15/23
    ["gweni"] = { average = 0.93, avgMedian = 32.0, avgKills = 23, firstkill = 0.93, fkPlatz = 11, fkVon = 23, fkAnteil = 81.6, fkKaempfe = 5, fkDps = 178517 },   -- Gwêni · Average 32,0 % (23 Kills) · Erst-Kill Platz 11/23
    ["hyperhardw"] = { average = 0.96, avgMedian = 57.0, avgKills = 16, firstkill = 0.86, fkPlatz = 21, fkVon = 23, fkAnteil = 71.7, fkKaempfe = 3, fkDps = 148813 },   -- Hyperhardw · Average 57,0 % (16 Kills) · Erst-Kill Platz 21/23
    ["indydrakes"] = { average = 0.94, avgMedian = 35.0, avgKills = 22, firstkill = 0.87, fkPlatz = 20, fkVon = 23, fkAnteil = 71.9, fkKaempfe = 4, fkDps = 139149 },   -- Indydrakes · Average 35,0 % (22 Kills) · Erst-Kill Platz 20/23
    ["jekyl"] = { average = 0.90, avgMedian = 1.0, avgKills = 1, firstkill = 0.85, fkPlatz = 23, fkVon = 23, fkAnteil = 48.2, fkKaempfe = 1, fkDps = 125584 },   -- Jekyl · Average 1,0 % (1 Kills) · Erst-Kill Platz 23/23
    ["keito"] = { firstkill = 0.94, fkPlatz = 9, fkVon = 23, fkAnteil = 83.5, fkKaempfe = 1, fkDps = 217568 },   -- Keito · Erst-Kill Platz 9/23
    ["kiesel"] = { firstkill = 0.90, fkPlatz = 16, fkVon = 23, fkAnteil = 76.4, fkKaempfe = 2, fkDps = 166978 },   -- Kîesel · Erst-Kill Platz 16/23
    ["merlon"] = { average = 0.95, avgMedian = 53.5, avgKills = 16, firstkill = 0.97, fkPlatz = 6, fkVon = 23, fkAnteil = 87.2, fkKaempfe = 5, fkDps = 199563 },   -- Merlón · Average 53,5 % (16 Kills) · Erst-Kill Platz 6/23
    ["moriko"] = { average = 0.96, avgMedian = 58.0, avgKills = 18, firstkill = 0.95, fkPlatz = 8, fkVon = 23, fkAnteil = 84.2, fkKaempfe = 3, fkDps = 193055 },   -- Moríko · Average 58,0 % (18 Kills) · Erst-Kill Platz 8/23
    ["neyzxd"] = { average = 0.97, avgMedian = 67.0, avgKills = 1 },   -- Neyzxd · Average 67,0 % (1 Kills)
    ["notam"] = { average = 0.93, avgMedian = 32.0, avgKills = 16, firstkill = 0.91, fkPlatz = 14, fkVon = 23, fkAnteil = 78.1, fkKaempfe = 5, fkDps = 156005 },   -- Notam · Average 32,0 % (16 Kills) · Erst-Kill Platz 14/23
    ["ophrys"] = { average = 0.93, avgMedian = 34.0, avgKills = 16 },   -- Ophrys · Average 34,0 % (16 Kills)
    ["palacetamol"] = { average = 0.92, avgMedian = 18.0, avgKills = 1 },   -- Palacetamol · Average 18,0 % (1 Kills)
    ["schmeckies"] = { average = 0.94, avgMedian = 40.0, avgKills = 1 },   -- Schmeckies · Average 40,0 % (1 Kills)
    ["setupx"] = { average = 0.99, avgMedian = 91.5, avgKills = 14 },   -- Setupx · Average 91,5 % (14 Kills)
    ["sikkz"] = { average = 0.96, avgMedian = 61.0, avgKills = 23, firstkill = 0.99, fkPlatz = 2, fkVon = 23, fkAnteil = 95.2, fkKaempfe = 5, fkDps = 206547 },   -- Sikkz · Average 61,0 % (23 Kills) · Erst-Kill Platz 2/23
    ["silanhunt"] = { average = 0.92, avgMedian = 23.0, avgKills = 14, firstkill = 0.88, fkPlatz = 19, fkVon = 23, fkAnteil = 72.2, fkKaempfe = 4, fkDps = 169525 },   -- Silanhunt · Average 23,0 % (14 Kills) · Erst-Kill Platz 19/23
    ["thunderdebbo"] = { average = 0.96, avgMedian = 64.0, avgKills = 15, firstkill = 0.96, fkPlatz = 7, fkVon = 23, fkAnteil = 85.2, fkKaempfe = 1, fkDps = 148571 },   -- Thunderdebbo · Average 64,0 % (15 Kills) · Erst-Kill Platz 7/23
    ["tobii"] = { average = 0.95, avgMedian = 53.0, avgKills = 13 },   -- Tobii · Average 53,0 % (13 Kills)
    ["twosocks"] = { average = 0.92, avgMedian = 23.0, avgKills = 3, firstkill = 1.00, fkPlatz = 1, fkVon = 23, fkAnteil = 95.4, fkKaempfe = 1, fkDps = 206727 },   -- Twosocks · Average 23,0 % (3 Kills) · Erst-Kill Platz 1/23
    ["vilarie"] = { average = 0.96, avgMedian = 60.0, avgKills = 13, firstkill = 0.89, fkPlatz = 17, fkVon = 23, fkAnteil = 75.4, fkKaempfe = 2, fkDps = 163704 },   -- Vilarie · Average 60,0 % (13 Kills) · Erst-Kill Platz 17/23
}