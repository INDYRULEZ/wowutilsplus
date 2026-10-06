-- Prüfstand fuer die ein-/ausblendbaren Spalten (rclc.lua): Set und Crests.
-- Aufruf:  cd ~/dev/wowutilsplus && lua5.1 tools/spalten_pruefstand.lua
-- Kein Spiel, kein PC: RCLootCouncil, LibStub, AceConfig und C_Timer sind Attrappen,
-- die mitschreiben. Die Attrappe wirft Fehler bei doppelter colName und wenn ein
-- `sortnext` auf eine Spalte zeigt, die es nicht gibt — genau die zwei Fallen.
-- 🔴 Vorgabe beider Spalten ist AUS (Jonas, 06.10.2026).

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

-- ---- Attrappen, die es fuer alle Welten einmal gibt ------------------------------
C_AddOns = { IsAddOnLoaded = function() return true end }
local ticks = {}
C_Timer = {
    After = function() end,
    NewTicker = function(_, f) ticks[#ticks + 1] = f; return { Cancel = function() end } end,
}
--- Alle angemeldeten Takte einmal ausloesen (so laeuft es im Spiel: OnInitialize -> Ticker).
local function tickAusloesen()
    local liste = ticks
    ticks = {}
    for _, f in ipairs(liste) do f() end
end

--- Spalten-Attrappe: fuehrt die Reihenfolge und prueft beim Einhaengen.
local function spaltenAttrappe()
    local spalten = {}
    local function index(name)
        for i, s in ipairs(spalten) do if s.colName == name then return i end end
    end
    local v = {}
    function v:AddColumn(spec, ziel, position)
        assert(spec and spec.colName, "AddColumn ohne colName")
        assert(index(spec.colName) == nil, "doppelte colName einghaengt: " .. tostring(spec.colName))
        if spec.sortnext then
            assert(index(spec.sortnext),
                   "sortnext zeigt ins Leere: " .. spec.colName .. " -> " .. tostring(spec.sortnext))
        end
        local stelle = #spalten
        if ziel ~= nil then
            local zi = index(ziel)
            assert(zi, "Zielspalte fehlt: " .. tostring(ziel))
            stelle = (position == "before") and (zi - 1) or zi
        end
        table.insert(spalten, stelle + 1,
                     { colName = spec.colName, name = spec.name, sortnext = spec.sortnext })
    end
    function v:GetColumn(name) local i = index(name); return i and spalten[i] end
    function v:RemoveColumn(name)
        local i = index(name)
        if i then table.remove(spalten, i) end
    end
    v.frame = { Update = function() end }
    v.spalten = spalten
    return v
end

--- Eine frische "Welt": eigenes ns, eigene Spalten-Attrappe, eigenes RCL, frische Datei-Locals.
local function welt(einstellungen)
    local w = { ns = {} }
    w.ns.LEISTUNG = { average = 1.0, firstkill = 1.0, movement = 1.0 }
    w.vw = spaltenAttrappe()
    w.vw:AddColumn({ colName = "wowutils", name = "WowUtils" }, nil, nil)   -- RCLs eigene Spalte

    local modul
    local RCL_ATT
    RCL_ATT = {
        _vw = w.vw,
        NewModule = function(self, name)
            modul = { SecureHook = function() end, name = name }
            return modul
        end,
        GetActiveModule = function(self) return self._vw end,
        GetModule = function() return nil end,
        GetLootTable = function() return {} end,
    }
    _G.RCL = RCL_ATT
    _G.WowUtilsPlusDB = { einstellungen = einstellungen or {} }

    -- AceConfig/AceConfigDialog als Sammler (fuer die Klick-Kaestchen)
    w.optionstabellen, w.blizSeiten = {}, {}
    LibStub = function(name)
        if name == "AceAddon-3.0" then
            return { GetAddon = function() return RCL_ATT end }
        elseif name == "AceConfig-3.0" then
            return { RegisterOptionsTable = function(_, app, tabelle)
                assert(w.optionstabellen[app] == nil, "Options-Tabelle doppelt angemeldet: " .. app)
                w.optionstabellen[app] = tabelle
            end }
        elseif name == "AceConfigDialog-3.0" then
            return {
                BlizOptionsIDMap = { ["RCLootCouncil"] = true },
                AddToBlizOptions = function(_, app, name, eltern)
                    assert(eltern == nil or w.blizSeiten[eltern] ~= nil or eltern == "RCLootCouncil",
                           "Elternseite unbekannt: " .. tostring(eltern))
                    w.blizSeiten[app] = { name = name, eltern = eltern }
                    return app
                end,
            }
        end
        return {}
    end

    local addon = "wowutilsplus"
    local function lade(datei, erwarteterFehler)
        local f = assert(loadfile(datei))
        local ok, f2 = pcall(f, addon, w.ns)
        if not ok and not erwarteterFehler then
            print("  !! " .. datei .. " konnte nicht geladen werden: " .. tostring(f2))
            fehler = fehler + 1
        end
    end
    -- core.lua wirft am Ende an CreateFrame — das ist erwartbar und unschaedlich.
    lade("gewichte.lua"); lade("prioliste.lua"); lade("core.lua", true); lade("rclc.lua")
    w.modul = modul            -- erst jetzt gesetzt: rclc.lua ruft NewModule beim Laden
    return w
end

local function namen(vw)
    local t = {}
    for _, s in ipairs(vw.spalten) do t[#t + 1] = s.colName end
    return table.concat(t, ", ")
end

local function sortnext(vw, colName)
    for _, s in ipairs(vw.spalten) do
        if s.colName == colName then return s.sortnext end
    end
end

local BASIS = "wowutils, wowutilsplus, wowutilsplusitems"

print("1) Vorgabe: nur Gewichtet + Items — Crests und Set sind aus")
do
    local w = welt({})
    w.modul:SpalteEinhaengen()
    pruefe("Spalten", BASIS, namen(w.vw))
end

print("2) Set eingeschaltet, Crests weiter aus: Set hinter Items, Kette auf Items")
do
    local w = welt({ setSpalte = true })
    w.modul:SpalteEinhaengen()
    pruefe("Spalten", BASIS .. ", wowutilsplusset", namen(w.vw))
    pruefe("Set zeigt auf Items", "wowutilsplusitems", sortnext(w.vw, "wowutilsplusset"))
end

print("3) Crests zur Laufzeit ein: Set zieht nach, Kette auf Crests")
do
    local w = welt({ setSpalte = true })
    w.modul:SpalteEinhaengen()
    pruefe("Umschalten möglich", true, w.ns.CrestSpalteLiveUmschalten(true))
    pruefe("Spalten", BASIS .. ", wowutilspluscrests, wowutilsplusset", namen(w.vw))
    pruefe("Set zeigt auf Crests", "wowutilspluscrests", sortnext(w.vw, "wowutilsplusset"))
    -- Die Live-Umschaltung aendert NUR die Spalte; die Einstellung schreibt der Befehl/das Kaestchen.
    pruefe("Einstellung unangetastet", false, w.ns.Einstellung("crestSpalte", false))

    pruefe("wieder aus", true, w.ns.CrestSpalteLiveUmschalten(false))
    pruefe("Spalten", BASIS .. ", wowutilsplusset", namen(w.vw))
    pruefe("Set zeigt wieder auf Items", "wowutilsplusitems", sortnext(w.vw, "wowutilsplusset"))
end

print("4) Crests zur Laufzeit ein, ohne Set — nichts anderes passiert")
do
    local w = welt({})
    w.modul:SpalteEinhaengen()
    w.ns.CrestSpalteLiveUmschalten(true)
    pruefe("Spalten", BASIS .. ", wowutilspluscrests", namen(w.vw))
    pruefe("Set ist nicht da", nil, sortnext(w.vw, "wowutilsplusset"))
end

print("5) Crests beim Start an")
do
    local w = welt({ crestSpalte = true })
    w.modul:SpalteEinhaengen()
    pruefe("Spalten", BASIS .. ", wowutilspluscrests", namen(w.vw))
end

print("6) Beide beim Start an")
do
    local w = welt({ crestSpalte = true, setSpalte = true })
    w.modul:SpalteEinhaengen()
    pruefe("Spalten", BASIS .. ", wowutilspluscrests, wowutilsplusset", namen(w.vw))
    pruefe("Set zeigt auf Crests", "wowutilspluscrests", sortnext(w.vw, "wowutilsplusset"))
end

print("7) Set an, Crests beim Start aus (Set muss auf Items zeigen)")
do
    local w = welt({ crestSpalte = false, setSpalte = true })
    w.modul:SpalteEinhaengen()
    pruefe("Spalten", BASIS .. ", wowutilsplusset", namen(w.vw))
    pruefe("Set zeigt auf Items", "wowutilsplusitems", sortnext(w.vw, "wowutilsplusset"))
end

print("8) Klick-Kaestchen in den RCL-Einstellungen")
do
    local w = welt({})
    w.modul:OnInitialize()          -- meldet die Seite an und startet den Ticker
    tickAusloesen()                 -- im Spiel haengt der Ticker die Spalten ein
    local t = w.optionstabellen["WowUtilsPlusRCL"]
    pruefe("Tabelle angemeldet", true, t ~= nil)
    pruefe("als Unterseite unter RCL", "RCLootCouncil",
           w.blizSeiten["WowUtilsPlusRCL"] and w.blizSeiten["WowUtilsPlusRCL"].eltern)
    pruefe("Set-Kaestchen", "toggle", t and t.args.setSpalte and t.args.setSpalte.type)
    pruefe("Crests-Kaestchen", "toggle", t and t.args.crestSpalte and t.args.crestSpalte.type)
    pruefe("Crests ist bei Vorgabe aus", false, t.args.crestSpalte.get())
    pruefe("Set ist bei Vorgabe aus", false, t.args.setSpalte.get())
    pruefe("Crests vor Set angeordnet", true,
           t.args.crestSpalte.order < t.args.setSpalte.order)
    -- Klick auf "an" schreibt die Einstellung UND schaltet sofort um
    t.args.crestSpalte.set(nil, true)
    pruefe("Einstellung geschrieben", true, w.ns.Einstellung("crestSpalte", false))
    pruefe("Spalte sofort da", BASIS .. ", wowutilspluscrests", namen(w.vw))
    t.args.crestSpalte.set(nil, false)
    pruefe("Einstellung zurueck", false, w.ns.Einstellung("crestSpalte", false))
    pruefe("Spalte sofort weg", BASIS, namen(w.vw))
end

print("9) Ohne offenes Fenster: nur die Einstellung, keine Ausnahme")
do
    local w = welt({})
    w.vw.AddColumn = nil          -- Fenster/RCL-API steht noch nicht
    w.vw.RemoveColumn = nil
    pruefe("Umschalten meldet 'nicht möglich'", false, w.ns.CrestSpalteLiveUmschalten(true))
    pruefe("Einstellung bleibt unangetastet", false, w.ns.Einstellung("crestSpalte", false))
end

print(string.rep("-", 58))
if fehler == 0 then print("ALLE PRUEFUNGEN BESTANDEN") else print("FEHLER: " .. fehler) end
os.exit(fehler == 0 and 0 or 1)