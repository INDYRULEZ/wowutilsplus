-- Automatisch erzeugt — NICHT von Hand editieren.
-- Quelle: Weboberfläche (Loot-Council-Prioritäten), Stand: 02.10.2026 09:41

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
-- firstkill: Rangfolge in den Erst-Kills, Platz 1 ohne Abzug, letzter Platz -15 %.
-- movement:  von Hand auf der Seite gepflegt.
ns.LEISTUNG_AVG_ABZUG = 0.100
ns.LEISTUNG_KADERSCHNITT = 36.8
ns.LEISTUNG_SPIELER = {
    ["auakaka"] = { firstkill = 0.91 },   -- Auakaka · Erst-Kill Platz 12/20
    ["balren"] = { average = 0.94, firstkill = 0.88 },   -- Balren · Erst-Kill Platz 16/20
    ["beaybewhy"] = { average = 0.92, firstkill = 0.94 },   -- Beaybewhy · Erst-Kill Platz 9/20
    ["blitzfaust"] = { average = 0.94, firstkill = 0.94 },   -- Blitzfaust · Erst-Kill Platz 8/20
    ["cep"] = { average = 0.94, firstkill = 0.95 },   -- Cep · Erst-Kill Platz 7/20
    ["cheliia"] = { average = 0.97 },
    ["cornfakez"] = { firstkill = 1.00 },   -- Cornfakez · Erst-Kill Platz 1/20
    ["cornzwojer"] = { firstkill = 0.85 },   -- Cornzwojer · Erst-Kill Platz 20/20
    ["dranash"] = { average = 0.93 },
    ["enshirou"] = { average = 0.92 },
    ["exorzist"] = { average = 0.93 },
    ["exudes"] = { average = 0.93, firstkill = 0.87 },   -- Exudes · Erst-Kill Platz 18/20
    ["garshu"] = { average = 0.93, firstkill = 0.91 },   -- Garshû · Erst-Kill Platz 13/20
    ["gweni"] = { average = 0.93, firstkill = 0.92 },   -- Gwêni · Erst-Kill Platz 11/20
    ["hyperhardw"] = { average = 0.96, firstkill = 0.86 },   -- Hyperhardw · Erst-Kill Platz 19/20
    ["indydrakes"] = { average = 0.94, firstkill = 0.98 },   -- Indydrakes · Erst-Kill Platz 4/20
    ["jekyl"] = { average = 0.90, firstkill = 0.90 },   -- Jekyl · Erst-Kill Platz 14/20
    ["kiesel"] = { firstkill = 0.99 },   -- Kîesel · Erst-Kill Platz 2/20
    ["merlon"] = { average = 0.95, firstkill = 0.97 },   -- Merlón · Erst-Kill Platz 5/20
    ["moriko"] = { average = 0.96 },
    ["neyzxd"] = { average = 0.97, firstkill = 0.96 },   -- Neyzxd · Erst-Kill Platz 6/20
    ["notam"] = { average = 0.93 },
    ["ophrys"] = { average = 0.93 },
    ["palacetamol"] = { average = 0.92 },
    ["schmeckies"] = { average = 0.94 },
    ["setupx"] = { average = 0.99 },
    ["sikkz"] = { average = 0.96, firstkill = 0.98 },   -- Sikkz · Erst-Kill Platz 3/20
    ["silanhunt"] = { average = 0.92 },
    ["sillan"] = { firstkill = 0.87 },   -- Sillan · Erst-Kill Platz 17/20
    ["thunderdebbo"] = { average = 0.96, firstkill = 0.93 },   -- Thunderdebbo · Erst-Kill Platz 10/20
    ["tobii"] = { average = 0.95 },
    ["twosocks"] = { average = 0.92 },
    ["vilarie"] = { average = 0.96, firstkill = 0.89 },   -- Vilarie · Erst-Kill Platz 15/20
}