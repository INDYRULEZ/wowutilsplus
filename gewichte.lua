-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 02.10.2026 03:07

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

-- Leistungsfaktor je Spieler, automatisch aus Warcraft Logs.
-- Nur Kills der eigenen Gilde, nur die letzten 4 Wochen.
-- Nulllinie = Kaderschnitt (36,5 %), volle Auswirkung ab 25 Punkten Abstand,
-- begrenzt auf 0.95 bis 1.05.
ns.LEISTUNG_REFERENZ = 36.5
ns.LEISTUNG_SPANNE = 25.0
ns.LEISTUNG_SPIELER = {
    ["cheliia"] = 1.05,   -- Cheliia · Median 68,5 % · 18 Kills
    ["neyzxd"] = 1.05,   -- Neyzxd · Median 67,0 % · 1 Kills
    ["setupx"] = 1.05,   -- Setupx · Median 91,5 % · 14 Kills
    ["thunderdebbo"] = 1.05,   -- Thunderdebbo · Median 64,0 % · 15 Kills
    ["sikkz"] = 1.05,   -- Sikkz · Median 61,0 % · 23 Kills
    ["vilarie"] = 1.05,   -- Vilarie · Median 60,0 % · 13 Kills
    ["moriko"] = 1.04,   -- Moríko · Median 58,0 % · 18 Kills
    ["hyperhardw"] = 1.04,   -- Hyperhardw · Median 57,5 % · 16 Kills
    ["merlon"] = 1.03,   -- Merlón · Median 53,5 % · 16 Kills
    ["tobii"] = 1.03,   -- Tobii · Median 53,0 % · 13 Kills
    ["balren"] = 1.01,   -- Balren · Median 43,0 % · 23 Kills
    ["blitzfaust"] = 1.01,   -- Blitzfaust · Median 43,0 % · 8 Kills
    ["schmeckies"] = 1.01,   -- Schmeckies · Median 40,0 % · 1 Kills
    ["cep"] = 1.00,   -- Cep · Median 38,5 % · 12 Kills
    ["indydrakes"] = 1.00,   -- Indydrakes · Median 34,5 % · 22 Kills
    ["ophrys"] = 0.99,   -- Ophrys · Median 34,0 % · 16 Kills
    ["exudes"] = 0.99,   -- Exudes · Median 32,0 % · 9 Kills
    ["gweni"] = 0.99,   -- Gwêni · Median 32,0 % · 23 Kills
    ["notam"] = 0.99,   -- Notam · Median 32,0 % · 16 Kills
    ["exorzist"] = 0.99,   -- Exorzist · Median 31,0 % · 23 Kills
    ["garshu"] = 0.99,   -- Garshû · Median 30,0 % · 16 Kills
    ["dranash"] = 0.98,   -- Dránash · Median 29,0 % · 16 Kills
    ["silanhunt"] = 0.97,   -- Silanhunt · Median 23,0 % · 14 Kills
    ["twosocks"] = 0.97,   -- Twosocks · Median 23,0 % · 3 Kills
    ["enshirou"] = 0.97,   -- Enshirou · Median 22,0 % · 11 Kills
    ["beaybewhy"] = 0.97,   -- Beaybewhy · Median 20,0 % · 4 Kills
    ["palacetamol"] = 0.96,   -- Palacetamol · Median 18,0 % · 1 Kills
    ["jekyl"] = 0.95,   -- Jekyl · Median 1,0 % · 1 Kills
}