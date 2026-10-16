-- Prüfstand für die Priorität → Faktor (core.lua: ns.PrioFaktor).
-- Aufruf:  cd ~/dev/wowutilsplus && lua5.1 tools/prio_pruefstand.lua
-- Kein Spiel nötig: core.lua wird mit einer Attrappen-Umgebung geladen.
--
-- 🔴 Jonas, 15.10.2026: Prioritäten gehen auf der Seite bis **10**. Die Plätze 1–9 bleiben in
-- 10-%-Schritten (1 = kein Abzug … 9 = −80 %), damit sich an bestehenden Werten nichts ändert.
-- **Platz 10 bekommt den vollen Abzug (−100 %, Faktor 0.00)** — alles darüber zählt wie 10.
--
-- 🔴 Die Tabelle auf der Website (`seite/app.js`, `FAKTOR`) muss dieselben Prozente zeigen —
-- deren Prüfung steht in `~/prioliste/seite/zellen_probe.js`.

local fehler = 0
local function pruefe(name, soll, ist)
    if soll == ist then
        print(string.format("  OK    %s", name))
    else
        fehler = fehler + 1
        print(string.format("  FEHL  %s\n          erwartet: %s\n          war:      %s",
                            name, tostring(soll), tostring(ist)))
    end
end

SlashCmdList = {}
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end
local ns = {}
local chunk = assert(loadfile("core.lua"))
chunk("WowUtilsPlus", ns)

-- Die erwartete Reihe: 10-%-Schritte, Platz 10 = voller Abzug.
local erwartet = {1.00, 0.90, 0.80, 0.70, 0.60, 0.50, 0.40, 0.30, 0.20, 0.00}
for i, soll in ipairs(erwartet) do
    pruefe(string.format("Platz %2d -> Faktor %.2f  (Abzug %3.0f %%)",
                         i, soll, (1 - soll) * 100),
           string.format("%.2f", soll), string.format("%.2f", ns.PrioFaktor(i)))
end
pruefe("ohne Priorität -> 1.00        ", "1.00", string.format("%.2f", ns.PrioFaktor(nil)))
pruefe("Platz 11 (über 10) -> 0.00    ", "0.00", string.format("%.2f", ns.PrioFaktor(11)))
pruefe("Platz 0 -> 1.00 (nicht negativ)", "1.00", string.format("%.2f", ns.PrioFaktor(0)))

print()
if fehler == 0 then
    print("Prio-Pruefstand: alle Pruefungen bestanden.")
else
    print(string.format("Prio-Pruefstand: %d Fehler.", fehler))
end
os.exit(fehler == 0 and 0 or 1)
