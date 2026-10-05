-- Prüfstand fuer die Inspizier-Logik in sets.lua (Hermes, 05.10.2026)
-- Aufruf:  cd ~/dev/wowutilsplus && lua5.1 tools/inspect_pruefstand.lua
-- Kein Spiel noetig: alle Spiel-API-Aufrufe sind Attrappen, die mitschreiben.

local ZEIT = 1000
local ticks, rahmen = {}, {}
local inspectAufrufe = {}
local guidVon = { raid1 = "G-1", raid2 = "G-2", raid3 = "G-3", raid4 = "G-4" }
local existiert = { raid1 = true, raid2 = true, raid3 = true, raid4 = true }
local neuladen = 0

-- ---- Attrappen -----------------------------------------------------------------
GetTime        = function() return ZEIT end
UnitExists     = function(u) return existiert[u] or false end
UnitGUID       = function(u) return guidVon[u] end
UnitName       = function(u) return u end
NotifyInspect  = function(u) inspectAufrufe[#inspectAufrufe + 1] = u end
IsInRaid       = function() return true end
IsInGroup      = function() return true end
GetNumGroupMembers = function() return 4 end
GetInventoryItemLink = function() return nil end
GetInventorySlotInfo = function() return 1 end
C_Timer = {
    After = function(_, _) end,
    NewTicker = function(_, f) ticks[#ticks + 1] = f; return { Cancel = function() end } end,
}
CreateFrame = function()
    local f = {}
    f.RegisterEvent = function(self, e) self.event = e end
    f.SetScript    = function(self, _, fn) self.fn = fn end
    rahmen[#rahmen + 1] = f
    return f
end

local ns = {}
local RCL_Attrappe = {
    GetActiveModule = function() return { Update = function() neuladen = neuladen + 1 end } end,
    GetModule = function() return nil end,
}
RCL = RCL_Attrappe
_G.RCL = RCL_Attrappe

-- ---- sets.lua laden ------------------------------------------------------------
local chunk = assert(loadfile("sets.lua"))
chunk("wowutilsplus", ns)

local fehler = 0
local function pruefe(name, soll, ist)
    if soll == ist then
        print(string.format("  OK    %s", name))
    else
        fehler = fehler + 1
        print(string.format("  FEHL  %s  (erwartet %s, war %s)", name, tostring(soll), tostring(ist)))
    end
end

local function tick() for _, f in ipairs(ticks) do f() end end
local function eventfeuer(guid) if rahmen[1] and rahmen[1].fn then rahmen[1].fn(rahmen[1], "INSPECT_READY", guid) end end

print("1) Rahmen und Takt wurden angelegt")
pruefe("ein Rahmen", 1, #rahmen)
pruefe("Ereignis registriert", "INSPECT_READY", rahmen[1].event)
pruefe("mindestens ein Takt", true, #ticks >= 1)

print("2) Anmelden fuellt die Warteliste, ohne sofort zu untersuchen")
ns.InspectAnfordern("raid1")
ns.InspectAnfordern("raid2")
ns.InspectAnfordern("raid1")          -- doppelt -> darf nicht doppelt drinstehen
pruefe("Liste hat 2 Eintraege", 2, #ns.Inspect.liste)
pruefe("noch nichts untersucht", 0, #inspectAufrufe)

print("3) Erster Takt startet genau EINE Untersuchung")
tick()
pruefe("ein Aufruf", 1, #inspectAufrufe)
pruefe("richtige Einheit", "raid1", inspectAufrufe[1])
pruefe("laeuft gesetzt", "raid1", ns.Inspect.laeuft and ns.Inspect.laeuft.unit)

print("4) Antwort kommt -> fertig, Fenster wird neu gezeichnet")
eventfeuer("G-1")
pruefe("laeuft wieder frei", nil, ns.Inspect.laeuft)
pruefe("als fertig vermerkt", true, ns.Inspect.fertig["G-1"] ~= nil)
pruefe("Fenster neu gezeichnet", 1, neuladen)

print("5) Naechster Takt nimmt das zweite Ziel")
tick()
pruefe("jetzt raid2", "raid2", inspectAufrufe[#inspectAufrufe])
pruefe("Aufrufe insgesamt 2", 2, #inspectAufrufe)

print("6) Keine Antwort -> Nachfassen, dann aufgeben (nie in einer Schleife)")
ZEIT = ZEIT + 3; tick()   -- 2. Versuch
pruefe("Versuch 2", 3, #inspectAufrufe)
pruefe("Versuchszaehler", 2, ns.Inspect.laeuft and ns.Inspect.laeuft.versuche)
ZEIT = ZEIT + 3; tick()   -- 3. Versuch
pruefe("Versuch 3", 4, #inspectAufrufe)
ZEIT = ZEIT + 3; tick()   -- Ende
pruefe("aufgegeben, nichts laeuft", nil, ns.Inspect.laeuft)
pruefe("keine weiteren Aufrufe", 4, #inspectAufrufe)
pruefe("Pause fuer die GUID gesetzt", true, ns.Inspect.pause["G-2"] ~= nil)

print("7) Wer fertig ist, wird nicht sofort erneut angemeldet")
ns.InspectAnfordern("raid1")
pruefe("Liste bleibt leer", 0, #ns.Inspect.liste)

print("8) Nicht existierende Einheit wird uebersprungen")
guidVon.raid3 = "G-3"; existiert.raid3 = false
ns.InspectAnfordern("raid3")
pruefe("nichts angemeldet", 0, #ns.Inspect.liste)

print("9) Pause laeuft ab -> dann wieder erlaubt")
ZEIT = ZEIT + 61
ns.InspectAnfordern("raid2")
pruefe("wieder angemeldet", 1, #ns.Inspect.liste)

print(string.rep("-", 58))
if fehler == 0 then print("ALLE PRUEFUNGEN BESTANDEN") else print("FEHLER: " .. fehler) end
os.exit(fehler == 0 and 0 or 1)
