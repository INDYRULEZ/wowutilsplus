--[[ WoWUtils Plus — Spalte im Loot-Council-Fenster (RCLootCouncil).

Nutzt die offizielle Spalten-API von RCLootCouncil:
  RCVotingFrame:AddColumn(spec, target, position)
Siehe RCLootCouncil/Modules/VotingFrame/ColumnAPI.lua.

Eigene Spalte "Gewichtet" rechts neben der WowUtils-Spalte:
  roher Sim-Gewinn -> gewichteter Gewinn (Rolle: Heiler x0.5, Tank x0.25)

Sortierung: ueber `comparesort` (lib-st) — numerisch nach dem gewichteten Wert,
nicht nach dem angezeigten Text. Der Wert wird beim Rendern in ns.cache abgelegt.
]]

local addonName, ns = ...

local SPALTE = "wowutilsplus"
local SPALTENNAME = "Gewichtet"
local BREITE = 90

-- RCLootCouncil muss geladen sein (OptionalDeps im .toc)
if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("RCLootCouncil")) then return end
local RCL = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil", true)
if not RCL then return end

local mod = RCL:NewModule("WowUtilsPlusRCLC", "AceHook-3.0")
ns.cache = {}          -- Kandidatenname -> gewichteter Wert (fuer die Sortierung)
ns.rohcache = {}       -- Kandidatenname -> { roh, faktor, grund, role, ilvl, prozent }
local session = 0
local lootTable

local function gelb(t) return ("|cffffd700%s|r"):format(t) end
local function grau(t) return ("|cff969696%s|r"):format(t) end
local function gruen(t) return ("|cff50dc64%s|r"):format(t) end
local function rot(t) return ("|cffff5a5a%s|r"):format(t) end

-- ---------------------------------------------------------------------------
-- Das aktuell zur Abstimmung stehende Item
-- ---------------------------------------------------------------------------

--- @return number? itemId, number? ilvl
local function aktuellesItem()
    if not (lootTable and lootTable[session]) then return nil, nil end
    local item = lootTable[session]
    local itemId = item.itemID
    if not itemId and item.link then
        itemId = C_Item.GetItemInfoInstant(item.link)
    end
    local ilvl
    if item.link then
        -- GetItemInfo liefert (name, link, quality, iLevel, ...)
        ilvl = select(4, C_Item.GetItemInfo(item.link))
    end
    return itemId, ilvl
end

-- ---------------------------------------------------------------------------
-- Gewichteten Wert fuer einen Kandidaten berechnen
-- ---------------------------------------------------------------------------

--- Sucht den besten Sim-Eintrag fuer das Item und gewichtet ihn nach Rolle.
--- @param kandidat string Charaktername wie RCL ihn fuehrt (name-realm)
--- Sammelt je Sim den passenden Eintrag fuer das Item — wie das Original:
--- bevorzugt den Eintrag mit exakt passender Item-Stufe, sonst den besten Wert.
--- @return table[] Liste von { e = Eintrag, role, simKey, simType, baseline }
local function sammleEintraege(daten, itemId, itemIlvl)
    local liste = {}
    for specId, sims in pairs(daten.specs) do
        local role = ns.RolleVonSpec(tonumber(specId))
        for simKey, sim in pairs(sims) do
            local ergebnisse = sim.items and sim.items[itemId]
            if ergebnisse then
                local treffer
                for _, e in ipairs(ergebnisse) do        -- 1. exakt passende Stufe
                    if itemIlvl and e.ilvl == itemIlvl then
                        treffer = e
                        break
                    end
                end
                if not treffer then                      -- 2. sonst bester Wert
                    for _, e in ipairs(ergebnisse) do
                        local wert = e.gain or e.gainPercent
                        local bester = treffer and (treffer.gain or treffer.gainPercent)
                        if wert and (not treffer or wert > bester) then treffer = e end
                    end
                end
                if treffer and (treffer.gain or treffer.gainPercent) then
                    liste[#liste + 1] = {
                        e = treffer, role = role, simKey = tostring(simKey),
                        simType = sim.simType, baseline = sim.baseline,
                    }
                end
            end
        end
    end
    return liste
end

--- @return number? gewichtet, table? details
local function berechne(kandidat)
    if not WowUtilsAPI or not kandidat then return nil end
    local itemId, itemIlvl = aktuellesItem()
    if not itemId then return nil end

    local daten = WowUtilsAPI.GetDroptimizers(kandidat)
    if not (daten and daten.specs) then return nil end

    local liste = sammleEintraege(daten, itemId, itemIlvl)
    if #liste == 0 then return nil end

    -- Wie das Original: den Patchwerk-1-Ziel-Sim bevorzugen (raidbots "…patchwerk-1",
    -- QE Live "…0-1"). Nur falls keiner dabei ist, den besten Wert nehmen.
    local gewaehlt
    for _, k in ipairs(liste) do
        local s = k.simKey:lower()
        if s:match("patchwerk%-1$") or s:match("0%-1$") then
            gewaehlt = k
            break
        end
    end
    if not gewaehlt then
        for _, k in ipairs(liste) do
            local w = k.e.gain or k.e.gainPercent
            if not gewaehlt or w > (gewaehlt.e.gain or gewaehlt.e.gainPercent) then
                gewaehlt = k
            end
        end
    end

    local e = gewaehlt.e
    local basis = e.gain or e.gainPercent
    local details = {
        basis = basis,
        prozent = e.gain == nil,       -- QE Live liefert nur Prozent
        ilvl = e.ilvl,
        role = gewaehlt.role,
        simKey = gewaehlt.simKey,
        simType = gewaehlt.simType,
        baseline = gewaehlt.baseline,
        anzahl = #liste,
    }
    local gewichtet, faktor, grund = ns.Gewichten(basis, gewaehlt.role)
    details.faktor, details.grund, details.gewichtet = faktor, grund, gewichtet
    return gewichtet, details
end

-- ---------------------------------------------------------------------------
-- Zell-Renderer + Tooltip
-- ---------------------------------------------------------------------------

local function tooltipZeigen(frame, kandidat)
    local d = ns.rohcache[kandidat]
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:AddLine(kandidat, 1, 1, 1)
    if not d then
        GameTooltip:AddLine(grau("Keine Sim-Daten fuer dieses Item."))
    else
        local einheit = d.prozent and "%" or ""
        GameTooltip:AddLine(("Roh:        %s"):format(ns.Zahl(d.basis, einheit)), 0.8, 0.8, 0.8)
        if d.faktor ~= 1.0 then
            GameTooltip:AddLine(("Gewichtet:  %s  (%s %s)")
                :format(ns.Zahl(d.gewichtet, einheit), d.role, ns.Faktor(d.faktor)), 1, 0.85, 0.2)
            GameTooltip:AddLine(d.grund or "", 0.7, 0.7, 0.7, true)
        else
            GameTooltip:AddLine(grau("Keine Gewichtung (Rolle " .. tostring(d.role) .. ")"), 0.8, 0.8, 0.8)
        end
        if d.ilvl then
            GameTooltip:AddLine(grau(("Item-Stufe im Sim: %d"):format(d.ilvl)))
        end
    end
    GameTooltip:Show()
end

function ns.UpdateZelle(rowFrame, frame, data, cols, row, realrow, column, fShow, table)
    local kandidat = data and data[realrow] and data[realrow].name
    if not kandidat then
        frame.text:SetText("---")
        return
    end

    local gewichtet, details = berechne(kandidat)
    ns.cache[kandidat] = gewichtet
    ns.rohcache[kandidat] = details

    frame.text:SetWordWrap(false)
    frame.text:SetNonSpaceWrap(false)

    if not gewichtet then
        frame.text:SetText("---")
        frame.text:SetTextColor(0.6, 0.6, 0.6)
    else
        local einheit = details.prozent and "%" or ""
        local text = ns.Zahl(gewichtet, einheit)
        frame.text:SetText(text)
        frame.text:SetTextColor(gewichtet >= 0 and 0.31 or 1.0, gewichtet >= 0 and 0.86 or 0.35, 0.39)
    end

    frame:SetScript("OnEnter", function(self) tooltipZeigen(self, kandidat) end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

--- Numerische Sortierung nach dem gewichteten Wert (lib-st ruft das auf).
local function vergleiche(self, rowa, rowb)
    local na = self.data and self.data[rowa] and self.data[rowa].name
    local nb = self.data and self.data[rowb] and self.data[rowb].name
    local a = na and ns.cache[na] or -math.huge
    local b = nb and ns.cache[nb] or -math.huge
    if a == b then return false end
    return a < b
end

-- ---------------------------------------------------------------------------
-- Spalte einhaengen
-- ---------------------------------------------------------------------------

local eingehaengt = false

function mod:SpalteEinhaengen()
    if eingehaengt then return true end
    local voting = RCL:GetActiveModule("votingframe") or RCL:GetModule("RCVotingFrame", true)
    if not (voting and voting.AddColumn) then return false end

    local ok, fehler = pcall(function()
        voting:AddColumn({
            colName = SPALTE,
            name = SPALTENNAME,
            width = BREITE,
            align = "CENTER",
            sortnext = "wowutils",          -- naechster Klick sortiert nach deren Spalte
            comparesort = vergleiche,
            DoCellUpdate = ns.UpdateZelle,
        }, "wowutils", "after")             -- rechts neben die WowUtils-Spalte
    end)
    if not ok then
        ns.spaltenFehler = tostring(fehler)
        return false
    end
    eingehaengt = true
    return true
end

function mod:OnInitialize()
    -- RCL braucht einen Moment, bis das Abstimmungsfenster-Modul steht
    local versuche = 0
    local t = C_Timer.NewTicker(1, function()
        versuche = versuche + 1
        if mod:SpalteEinhaengen() then
            t:Cancel()
        elseif versuche >= 20 then
            t:Cancel()
            print("|cffff5a5aWoWUtils Plus:|r Spalte konnte nicht eingehängt werden — "
                  .. tostring(ns.spaltenFehler or "Fenster nicht gefunden"))
        end
    end)
end

-- Session + Loot-Tabelle mitverfolgen (wie das Original)
mod:SecureHook(RCL, "OnLootTableReceived", function()
    lootTable = RCL:GetLootTable()
end)

local function sessionHook()
    local voting = RCL:GetActiveModule("votingframe") or RCL:GetModule("RCVotingFrame", true)
    if voting and voting.SwitchSession and not mod._sessionHooked then
        mod._sessionHooked = true
        mod:SecureHook(voting, "SwitchSession", function(_, neueSession)
            session = neueSession or 0
            lootTable = RCL:GetLootTable()
        end)
    end
end
C_Timer.After(2, sessionHook)
-- ---------------------------------------------------------------------------
-- Diagnose: /wup rcl  — zeigt, was das Addon zum aktuellen Item sieht
-- ---------------------------------------------------------------------------

local function kandidatenAusFenster()
    local liste = {}
    local ok = pcall(function()
        local v = RCL:GetActiveModule("votingframe") or RCL:GetModule("RCVotingFrame", true)
        local daten = v and v.frame and v.frame.data
        if type(daten) == "table" then
            for _, zeile in ipairs(daten) do
                if zeile and zeile.name then liste[#liste + 1] = zeile.name end
            end
        end
    end)
    return ok and liste or {}
end

function ns.DebugRCL()
    print("|cffffd700WoWUtils Plus — RCL-Diagnose|r")
    local item = lootTable and lootTable[session]
    if not item then
        print("  Kein Item im Abstimmungsfenster (Fenster offen?).")
        return
    end
    print("  Link:        " .. tostring(item.link))
    print("  itemID:      " .. tostring(item.itemID))
    local itemId = item.itemID
    local ilvl
    if item.link then
        ilvl = select(4, C_Item.GetItemInfo(item.link))
        local _, ctx = C_Item.GetItemCreationContext(item.link)
        print("  Stufe:       " .. tostring(ilvl))
        print("  Kontext:     " .. tostring(ctx))
        if not itemId then itemId = C_Item.GetItemInfoInstant(item.link) end
        print("  Stufe (nur ID, ohne Bonus): " .. tostring(itemId and select(4, C_Item.GetItemInfo(itemId))))
        local bonus = {}
        for _, teil in ipairs({ strsplit(":", item.link) }) do
            if tonumber(teil) and tonumber(teil) > 1000 then bonus[#bonus + 1] = teil end
        end
        print("  Bonus-IDs:   " .. (#bonus > 0 and table.concat(bonus, ", ") or "-"))
    end

    local namen = kandidatenAusFenster()
    print("  Kandidaten im Fenster: " .. (#namen > 0 and table.concat(namen, ", ") or "(keine erkannt)"))
    print("  Eintraege fuer Item " .. tostring(itemId) .. ":")
    for _, name in ipairs(namen) do
        local daten = WowUtilsAPI and WowUtilsAPI.GetDroptimizers(name)
        if daten and daten.specs then
            for specId, sims in pairs(daten.specs) do
                local role = ns.RolleVonSpec(tonumber(specId))
                for simKey, sim in pairs(sims) do
                    local ergebnisse = sim.items and sim.items[itemId]
                    if ergebnisse then
                        for _, e in ipairs(ergebnisse) do
                            print(("    %s | spec=%s (%s) | sim=%s | simType=%s | ilvl=%s | diff=%s | gain=%s | pct=%s")
                                :format(name, tostring(specId), tostring(role), tostring(simKey),
                                        tostring(sim.simType), tostring(e.ilvl), tostring(e.difficultyId),
                                        tostring(e.gain), tostring(e.gainPercent)))
                        end
                    end
                end
            end
        end
    end
    print("|cff969696  (Item im Fenster auswaehlen, dann /wup rcl)|r")
end
