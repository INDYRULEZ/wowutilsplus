-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 02.10.2026 10:24

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
-- average:   Median der Parse-Prozente, nur mythischen Kills der eigenen Gilde,
--            Zeitfenster 4 Wochen. 100er Log = 1.00, 0er Log = 0.90 (linear).
-- firstkill: Rangfolge in den mythischen Erst-Kills, Platz 1 ohne Abzug, letzter Platz -15 %.
-- movement:  von Hand auf der Seite gepflegt.
ns.LEISTUNG_AVG_ABZUG = 0.100
ns.LEISTUNG_KADERSCHNITT = 30.2
ns.LEISTUNG_SPIELER = {
    ["balren"] = { average = 0.93, avgMedian = 31.0, avgKills = 11, firstkill = 0.95, fkPlatz = 7, fkVon = 21, fkAnteil = 89.1, fkKaempfe = 4, fkDps = 203887 },   -- Balren · Average 31,0 % (11 Kills) · Erst-Kill Platz 7/21
    ["beaybewhy"] = { average = 0.90, avgMedian = 0.0, avgKills = 1 },   -- Beaybewhy · Average 0,0 % (1 Kills)
    ["bigboysushi"] = { firstkill = 0.91, fkPlatz = 13, fkVon = 21, fkAnteil = 79.5, fkKaempfe = 2, fkDps = 196395 },   -- Bigboysushi · Erst-Kill Platz 13/21
    ["blitzfaust"] = { average = 0.94, avgMedian = 42.0, avgKills = 5, firstkill = 0.95, fkPlatz = 8, fkVon = 21, fkAnteil = 87.3, fkKaempfe = 2, fkDps = 205486 },   -- Blitzfaust · Average 42,0 % (5 Kills) · Erst-Kill Platz 8/21
    ["cep"] = { average = 0.93, avgMedian = 29.5, avgKills = 8, firstkill = 0.98, fkPlatz = 4, fkVon = 21, fkAnteil = 92.0, fkKaempfe = 4, fkDps = 215783 },   -- Cep · Average 29,5 % (8 Kills) · Erst-Kill Platz 4/21
    ["cheliia"] = { average = 0.94, avgMedian = 37.0, avgKills = 9, firstkill = 0.96, fkPlatz = 6, fkVon = 21, fkAnteil = 90.2, fkKaempfe = 3, fkDps = 187133 },   -- Cheliia · Average 37,0 % (9 Kills) · Erst-Kill Platz 6/21
    ["dranash"] = { average = 0.94, avgMedian = 40.0, avgKills = 11 },   -- Dránash · Average 40,0 % (11 Kills)
    ["enshirou"] = { average = 0.92, avgMedian = 22.0, avgKills = 9, firstkill = 0.92, fkPlatz = 12, fkVon = 21, fkAnteil = 80.5, fkKaempfe = 3, fkDps = 183545 },   -- Enshirou · Average 22,0 % (9 Kills) · Erst-Kill Platz 12/21
    ["exorzist"] = { average = 0.93, avgMedian = 25.0, avgKills = 11 },   -- Exorzist · Average 25,0 % (11 Kills)
    ["exudes"] = { average = 0.92, avgMedian = 22.0, avgKills = 4, firstkill = 1.00, fkPlatz = 1, fkVon = 21, fkAnteil = 100.0, fkKaempfe = 1, fkDps = 260533 },   -- Exudes · Average 22,0 % (4 Kills) · Erst-Kill Platz 1/21
    ["garshu"] = { average = 0.92, avgMedian = 20.0, avgKills = 11, firstkill = 0.90, fkPlatz = 15, fkVon = 21, fkAnteil = 78.1, fkKaempfe = 4, fkDps = 190251 },   -- Garshû · Average 20,0 % (11 Kills) · Erst-Kill Platz 15/21
    ["gweni"] = { average = 0.92, avgMedian = 23.0, avgKills = 11, firstkill = 0.94, fkPlatz = 9, fkVon = 21, fkAnteil = 84.8, fkKaempfe = 4, fkDps = 180562 },   -- Gwêni · Average 23,0 % (11 Kills) · Erst-Kill Platz 9/21
    ["hyperhardw"] = { average = 0.94, avgMedian = 42.0, avgKills = 9, firstkill = 0.86, fkPlatz = 19, fkVon = 21, fkAnteil = 71.7, fkKaempfe = 3, fkDps = 148813 },   -- Hyperhardw · Average 42,0 % (9 Kills) · Erst-Kill Platz 19/21
    ["indydrakes"] = { average = 0.91, avgMedian = 10.0, avgKills = 10, firstkill = 0.86, fkPlatz = 20, fkVon = 21, fkAnteil = 64.6, fkKaempfe = 3, fkDps = 140020 },   -- Indydrakes · Average 10,0 % (10 Kills) · Erst-Kill Platz 20/21
    ["jekyl"] = { average = 0.90, avgMedian = 1.0, avgKills = 1, firstkill = 0.85, fkPlatz = 21, fkVon = 21, fkAnteil = 48.2, fkKaempfe = 1, fkDps = 125584 },   -- Jekyl · Average 1,0 % (1 Kills) · Erst-Kill Platz 21/21
    ["keito"] = { firstkill = 0.93, fkPlatz = 11, fkVon = 21, fkAnteil = 83.5, fkKaempfe = 1, fkDps = 217568 },   -- Keito · Erst-Kill Platz 11/21
    ["kiesel"] = { firstkill = 0.90, fkPlatz = 14, fkVon = 21, fkAnteil = 78.5, fkKaempfe = 1, fkDps = 204428 },   -- Kîesel · Erst-Kill Platz 14/21
    ["merlon"] = { average = 0.95, avgMedian = 52.0, avgKills = 11, firstkill = 0.97, fkPlatz = 5, fkVon = 21, fkAnteil = 90.2, fkKaempfe = 4, fkDps = 209515 },   -- Merlón · Average 52,0 % (11 Kills) · Erst-Kill Platz 5/21
    ["moriko"] = { average = 0.95, avgMedian = 46.0, avgKills = 9, firstkill = 0.93, fkPlatz = 10, fkVon = 21, fkAnteil = 84.2, fkKaempfe = 3, fkDps = 193055 },   -- Moríko · Average 46,0 % (9 Kills) · Erst-Kill Platz 10/21
    ["neyzxd"] = { average = 0.97, avgMedian = 67.0, avgKills = 1 },   -- Neyzxd · Average 67,0 % (1 Kills)
    ["notam"] = { average = 0.92, avgMedian = 21.0, avgKills = 11, firstkill = 0.89, fkPlatz = 16, fkVon = 21, fkAnteil = 76.7, fkKaempfe = 4, fkDps = 164437 },   -- Notam · Average 21,0 % (11 Kills) · Erst-Kill Platz 16/21
    ["ophrys"] = { average = 0.94, avgMedian = 42.0, avgKills = 11 },   -- Ophrys · Average 42,0 % (11 Kills)
    ["palacetamol"] = { average = 0.92, avgMedian = 18.0, avgKills = 1 },   -- Palacetamol · Average 18,0 % (1 Kills)
    ["schmeckies"] = { average = 0.94, avgMedian = 40.0, avgKills = 1 },   -- Schmeckies · Average 40,0 % (1 Kills)
    ["setupx"] = { average = 0.99, avgMedian = 91.0, avgKills = 11 },   -- Setupx · Average 91,0 % (11 Kills)
    ["sikkz"] = { average = 0.96, avgMedian = 61.0, avgKills = 11, firstkill = 0.98, fkPlatz = 3, fkVon = 21, fkAnteil = 94.5, fkKaempfe = 4, fkDps = 212062 },   -- Sikkz · Average 61,0 % (11 Kills) · Erst-Kill Platz 3/21
    ["silanhunt"] = { average = 0.91, avgMedian = 6.0, avgKills = 10, firstkill = 0.87, fkPlatz = 18, fkVon = 21, fkAnteil = 72.2, fkKaempfe = 4, fkDps = 169525 },   -- Silanhunt · Average 6,0 % (10 Kills) · Erst-Kill Platz 18/21
    ["thunderdebbo"] = { average = 0.96, avgMedian = 62.0, avgKills = 10 },   -- Thunderdebbo · Average 62,0 % (10 Kills)
    ["tobii"] = { average = 0.96, avgMedian = 57.0, avgKills = 9 },   -- Tobii · Average 57,0 % (9 Kills)
    ["twosocks"] = { average = 0.92, avgMedian = 23.0, avgKills = 3, firstkill = 0.99, fkPlatz = 2, fkVon = 21, fkAnteil = 95.4, fkKaempfe = 1, fkDps = 206727 },   -- Twosocks · Average 23,0 % (3 Kills) · Erst-Kill Platz 2/21
    ["vilarie"] = { average = 0.93, avgMedian = 28.0, avgKills = 3, firstkill = 0.88, fkPlatz = 17, fkVon = 21, fkAnteil = 74.8, fkKaempfe = 1, fkDps = 194805 },   -- Vilarie · Average 28,0 % (3 Kills) · Erst-Kill Platz 17/21
}