-- Prüfstand fuer den Prozent-Zusatz hinter dem Endwert (core.lua: ProzentGewinn / GewinnZusatz).
-- Aufruf:  cd ~/dev/wowutilsplus && lua5.1 tools/prozent_pruefstand.lua
-- Kein Spiel nötig: core.lua wird mit einer Attrappen-Umgebung geladen.
--
-- 🔴 Zweck (Jonas, 09.10.2026): DPS- und Heiler-Gewinne sollen vergleichbar sein. Bei DPS steht
-- der absolute Wert in der Spalte, dahinter der Gewinn in Prozent (Grundwert / Bezugswert).
-- Bei Heilern (QE Live) IST der Wert schon Prozent, dort darf nichts dazukommen — und wenn die
-- Sim keinen Bezugswert mitliefert, ebenfalls nicht. Genau das prüft dieser Prüfstand.

local fehler = 0
local function pruefe(name, soll, ist)
    if soll == ist then
        print(string.format("  OK    %s", name))
    else
        fehler = fehler + 1
        print(string.format("  FEHL  %s\n          erwartet: %q\n          war:      %q",
                            name, tostring(soll), tostring(ist)))
    end
end

-- ---- core.lua laden (es holt sich sein ns über ...) -------------------------------
-- Attrappen für die Spiel-Umgebung, die core.lua beim Laden anfasst.
SlashCmdList = {}
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end
local ns = {}
local chunk = assert(loadfile("core.lua"))
chunk("WowUtilsPlus", ns)

-- ---- ProzentGewinn: die Rechnung selbst -------------------------------------------
pruefe("ProzentGewinn 2700 / 196201  (cep, Item 271092)", "1.376", string.format("%.3f", ns.ProzentGewinn(2700, 196201)))
pruefe("ProzentGewinn -2490 / 196201                       ", "-1.269", string.format("%.3f", ns.ProzentGewinn(-2490, 196201)))
pruefe("ProzentGewinn 510 / 207905   (Vilarie)             ", "0.245", string.format("%.3f", ns.ProzentGewinn(510, 207905)))
pruefe("kein Bezugswert (Heiler) -> nil                    ", "nil", tostring(ns.ProzentGewinn(0.66, nil)))
pruefe("Bezugswert 0 -> nil                               ", "nil", tostring(ns.ProzentGewinn(500, 0)))
pruefe("Grundwert fehlt -> nil                            ", "nil", tostring(ns.ProzentGewinn(nil, 196201)))

-- ---- GewinnZusatz: was hinter dem Wert steht --------------------------------------
pruefe("DPS-Zusatz bei 510 / 196201        ", " (+0,26 %)", ns.GewinnZusatz(510, 196201, false))
pruefe("DPS-Zusatz bei 2700 / 196201       ", " (+1,38 %)", ns.GewinnZusatz(2700, 196201, false))
pruefe("DPS-Zusatz negativ (-2490)         ", " (-1,27 %)", ns.GewinnZusatz(-2490, 196201, false))
pruefe("Heiler (istProzent) -> nichts      ", "", ns.GewinnZusatz(0.66, nil, true))
pruefe("Heiler mit Bezugswert -> nichts    ", "", ns.GewinnZusatz(0.66, 350000, true))
pruefe("kein Bezugswert -> nichts          ", "", ns.GewinnZusatz(510, nil, false))
pruefe("Bezugswert 0 -> nichts             ", "", ns.GewinnZusatz(510, 0, false))
pruefe("Grundwert fehlt -> nichts          ", "", ns.GewinnZusatz(nil, 196201, false))

-- ---- So sieht die Zelle aus (Spalte „Gewichtet") ----------------------------------
pruefe("DPS-Zelle     ",
       "+376,38 (+0,26 %)",
       ns.Zahl(376.38, "") .. ns.GewinnZusatz(510, 196201, false))
pruefe("Heiler-Zelle  ",
       "+0,66%",
       ns.Zahl(0.66, "%") .. ns.GewinnZusatz(0.66, nil, true))
pruefe("DPS ohne Sim-Bezugswert ",
       "+376,38",
       ns.Zahl(376.38, "") .. ns.GewinnZusatz(510, nil, false))

print()
if fehler == 0 then
    print("Prozent-Pruefstand: alle Pruefungen bestanden.")
else
    print(string.format("Prozent-Pruefstand: %d Fehler.", fehler))
end
os.exit(fehler == 0 and 0 or 1)
