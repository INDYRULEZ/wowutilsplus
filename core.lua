--[[ WoWUtils Plus — Zusatz-Auswertung auf Basis der WowUtils-Daten.

Liest die Daten NICHT selbst aus der Bridge-Datei, sondern ueber die offizielle
Schnittstelle des Original-Addons (Global `WowUtilsAPI`, siehe publicAPI.lua).
Damit bleibt ein Update des Originals konfliktfrei.

Erste Ausbaustufe: EIN Gewichtungsfaktor (Heiler), Anzeige im Chat.
Der Grund fuer die Reduzierung wird immer mitgeliefert ("warum").
]]

local addonName, ns = ...   -- ns ist nur unser eigener Namensraum

ns.VERSION = "0.1.0"

-- ---------------------------------------------------------------------------
-- Gewichtungen
-- Rolle -> Faktor + Begruendung. Bewusst als Tabelle, damit die weiteren
-- Faktoren (Jonas hat 4-5 im Kopf) einfach ergaenzt werden koennen.
-- Testphase: nur HEALER aktiv, alle anderen 1.0 = unveraendert.
-- ---------------------------------------------------------------------------
ns.WEIGHTS = {
    HEALER  = { factor = 0.5,  reason = "Heilung bringt weniger direkten Kill-Beitrag als Schaden" },
    TANK    = { factor = 0.25, reason = "Tank-Schaden skaliert nicht mit dem Raid-Fortschritt" },
    DAMAGER = { factor = 1.0,  reason = "unveraendert" },
}

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

--- Zahl mit zwei Nachkommastellen, deutschem Komma und Vorzeichen.
--- "+492,50" / "-10,00" / "+2,50%" — Sortierung nutzt weiterhin den exakten Wert.
--- @param wert number
--- @param einheit string? z. B. "%"
function ns.Zahl(wert, einheit)
    local s = ("%.2f"):format(wert)
    s = s:gsub("%.", ",")
    if wert >= 0 then s = "+" .. s end
    return s .. (einheit or "")
end

--- Faktor ohne Vorzeichen, deutsches Komma: "x0,25"
function ns.Faktor(f)
    local s = ("x%.2f"):format(f)
    return (s:gsub("%.", ","))
end

local function farbe(text, r, g, b)
    return ("|cff%02x%02x%02x%s|r"):format(r, g, b, text)
end

local function gelb(t) return farbe(t, 255, 215, 0) end
local function grau(t) return farbe(t, 150, 150, 150) end
local function gruen(t) return farbe(t, 80, 220, 100) end
local function rot(t) return farbe(t, 240, 90, 90) end
local function blau(t) return farbe(t, 120, 170, 255) end

--- Rolle eines Sims bestimmen. specId -> "TANK"/"HEALER"/"DAMAGER" kommt direkt
--- aus dem Spiel (GetSpecializationInfoByID), also keine eigene Heuristik noetig.
--- @param specId number
--- @return string role
function ns.RolleVonSpec(specId)
    if not specId then return "DAMAGER" end
    -- GetSpecializationInfoByID liefert: id, name, description, icon, role, primaryStat
    local ok, _, _, _, _, role = pcall(GetSpecializationInfoByID, specId)
    if ok and role then return role end
    return "DAMAGER"
end

--- Einen einzelnen Gewinn gewichten.
--- @param wert number Basiswert (absoluter Gewinn ODER Prozentwert)
--- @param role string
--- @return number gewichtet, number faktor, string grund
function ns.Gewichten(wert, role)
    local w = ns.WEIGHTS[role]
    if not w or w.factor == 1.0 then
        return wert, 1.0, nil
    end
    return wert * w.factor, w.factor, w.reason
end

-- ---------------------------------------------------------------------------
-- Datenzugriff
-- ---------------------------------------------------------------------------

--- Alle Charaktere, fuer die Daten vorliegen: Spieler + Raid.
--- @return table[] Liste aus { unit, name, class, daten }
function ns.CharaktereSammeln()
    local gesehen, liste = {}, {}
    local function nimm(unit)
        if not unit or not UnitExists(unit) then return end
        local name = UnitName(unit)
        if not name or gesehen[name] then return end
        gesehen[name] = true
        local ok, daten = pcall(WowUtilsAPI.GetDroptimizers, unit)
        liste[#liste + 1] = {
            unit = unit,
            name = name,
            class = select(2, UnitClass(unit)),
            daten = ok and daten or nil,
        }
    end
    nimm("player")
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do nimm("raid" .. i) end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do nimm("party" .. i) end
    end
    return liste
end

-- ---------------------------------------------------------------------------
-- Slash-Befehle
-- ---------------------------------------------------------------------------

local function hilfe()
    print(gelb("WoWUtils Plus ") .. grau("v" .. ns.VERSION))
    print("  " .. blau("/wup") .. "            Datenlage pruefen (wie viele Charaktere haben Daten)")
    print("  " .. blau("/wup gewichte") .. "    aktive Gewichtungen anzeigen")
    print("  " .. blau("/wup test") .. "        eigene Wunschliste mit gewichteten Gewinnen zeigen")
    print("  " .. blau("/wup rcl") .. "         Diagnose: was das Addon zum aktuellen Item sieht")
end

local function datenlage()
    local liste = ns.CharaktereSammeln()
    print(gelb("WoWUtils Plus — Datenlage"))
    if not WowUtilsAPI then
        print("  " .. rot("WowUtilsAPI nicht gefunden") .. " — laeuft das Original-Addon 'wowutils'?")
        return
    end
    local mit, ohne = 0, 0
    for _, c in ipairs(liste) do
        if c.daten and c.daten.specs and next(c.daten.specs) then mit = mit + 1 else ohne = ohne + 1 end
    end
    print(("  Charaktere geprueft: %d — mit Sim-Daten: %s, ohne: %s")
        :format(#liste, gruen(mit), grau(ohne)))
end

local function gewichte()
    print(gelb("Aktive Gewichtungen"))
    for role, w in pairs(ns.WEIGHTS) do
        local zustand = w.factor == 1.0 and grau("aus") or gruen(("x%.2f"):format(w.factor))
        print(("  %-8s %s  %s"):format(role, zustand, grau(w.reason)))
    end
end

--- Die eigene Wunschliste mit rohen und gewichteten Gewinnen ausgeben.
local function test()
    local daten = WowUtilsAPI and WowUtilsAPI.GetDroptimizers("player")
    if not daten then
        print(rot("Keine eigenen Daten gefunden.") .. " Liegt die Bridge-Datei vor (/wup)?")
        return
    end

    -- Gewinne je Item aus allen Sims des Charakters einsammeln
    local jeItem = {}
    for specId, sims in pairs(daten.specs or {}) do
        local role = ns.RolleVonSpec(tonumber(specId))
        for _, sim in pairs(sims) do
            for itemId, ergebnisse in pairs(sim.items or {}) do
                for _, e in ipairs(ergebnisse) do
                    local istProzent = e.gain == nil
                    local basis = e.gain or e.gainPercent
                    if basis then
                        local gewichtet, faktor, grund = ns.Gewichten(basis, role)
                        local alt = jeItem[itemId]
                        if not alt or math.abs(basis) > math.abs(alt.basis) then
                            jeItem[itemId] = {
                                basis = basis, istProzent = istProzent,
                                gewichtet = gewichtet, faktor = faktor,
                                grund = grund, role = role, ilvl = e.ilvl,
                            }
                        end
                    end
                end
            end
        end
    end

    local zeilen = {}
    for itemId, v in pairs(jeItem) do zeilen[#zeilen + 1] = { itemId = itemId, v = v } end
    table.sort(zeilen, function(a, b) return a.v.basis > b.v.basis end)

    local name = UnitName("player")
    print(gelb("Wunschliste mit Gewichtung — ") .. (name or "?"))
    if #zeilen == 0 then
        print("  " .. grau("Keine Sim-Ergebnisse vorhanden."))
        return
    end
    for i = 1, math.min(#zeilen, 12) do
        local z = zeilen[i]
        local v = z.v
        local einheit = v.istProzent and "%" or ""
        local roh = ns.Zahl(v.basis, einheit)
        local gew = ns.Zahl(v.gewichtet, einheit)
        local itemName
        if C_Item and C_Item.GetItemInfo then
            itemName = C_Item.GetItemInfo(z.itemId)
        end
        local bezeichnung = itemName or ("Item " .. z.itemId)
        local farbe_roh = v.basis >= 0 and gruen(roh) or rot(roh)
        local text = ("  %-26s %s"):format(bezeichnung:sub(1, 26), farbe_roh)
        if v.faktor ~= 1.0 then
            text = text .. "  " .. grau("→") .. " " .. gelb(gew) ..
                   "  " .. grau(("(%s %s)"):format(v.role, ns.Faktor(v.faktor)))
        end
        print(text)
        if v.grund and i <= 3 then
            print("      " .. grau(v.grund))
        end
    end
    print("  " .. grau("(max. 12 Eintraege, sortiert nach rohem Gewinn)"))
end

SLASH_WOWUTILSPLUS1 = "/wup"
SlashCmdList["WOWUTILSPLUS"] = function(eingabe)
    local befehl = (eingabe or ""):lower():match("^%s*(%S*)")
    if befehl == "" or befehl == "help" then hilfe()
    elseif befehl == "test" then test()
    elseif befehl == "gewichte" then gewichte()
    elseif befehl == "rcl" and ns.DebugRCL then ns.DebugRCL()
    else datenlage() end
end

-- Beim Login einmal kurz melden, damit man sieht dass es geladen ist
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    print(gelb("WoWUtils Plus") .. grau(" geladen — /wup fuer Hilfe"))
end)