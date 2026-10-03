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

--- Zuordnung Erzeugungs-Kontext -> Schwierigkeit im Sim (difficultyId)
local KONTEXT_ZU_DIF = {
    ["raid-finder"] = 17,          -- RaidLFR
    ["raid-normal"] = 14,          -- RaidNormal
    ["raid-heroic"] = 15,          -- RaidHeroic
    ["raid-mythic"] = 16,          -- RaidMythic
    ["dungeon-mythic-plus"] = 8,   -- DungeonKeystone
}

--- Schluessel des Erzeugungs-Kontexts, z. B. "raid-mythic".
--- @return string? schluessel, string? quelle
local function kontextSchluessel(link)
    if not link then return nil, nil end
    local ctx, ctxString = C_Item.GetItemCreationContext(link)
    if type(ctxString) == "string" then return ctxString:lower(), "string" end
    local e = Enum and Enum.ItemCreationContext
    if e and ctx then
        for name, wert in pairs(e) do
            if wert == ctx then
                local s = name:gsub("(%u)", "-%1"):lower()
                return (s:gsub("^%-", "")), "enum"
            end
        end
    end
    return nil, nil
end

--- Das Abstimmungsfenster-Modul von RCL.
local function votingFrame()
    return RCL:GetActiveModule("votingframe") or RCL:GetModule("RCVotingFrame", true)
end

--- Der Eintrag des Items, das gerade im Fenster steht (frisch gelesen).
--- @return table?
function ns.ItemImFenster()
    local v = votingFrame()
    local lt = (v and v.GetLootTable and v:GetLootTable())
        or (RCL.GetLootTable and RCL:GetLootTable())
        or lootTable
    local s = (v and v.GetCurrentSession and v:GetCurrentSession()) or session
    if lt and s and lt[s] then return lt[s] end
    return nil
end

--- @return number? itemId, number? ilvl, number? zielDif, string? kontext, string? quelle
local function aktuellesItem()
    local item = ns.ItemImFenster()
    if not item then return nil, nil, nil, nil end
    local itemId = item.itemID
    if not itemId and item.link then
        itemId = C_Item.GetItemInfoInstant(item.link)
    end
    local ilvl, kontext, zielDif, quelle
    if item.link then
        ilvl = select(4, C_Item.GetItemInfo(item.link))   -- Stufe laut Link (mit Bonus-IDs)
        kontext, quelle = kontextSchluessel(item.link)
        zielDif = kontext and KONTEXT_ZU_DIF[kontext]
    end
    return itemId, ilvl, zielDif, kontext, quelle
end

-- ---------------------------------------------------------------------------
-- Gewichteten Wert fuer einen Kandidaten berechnen
-- ---------------------------------------------------------------------------

--- Sucht den besten Sim-Eintrag fuer das Item und gewichtet ihn nach Rolle.
--- @param kandidat string Charaktername wie RCL ihn fuehrt (name-realm)
--- Sammelt je Sim den passenden Eintrag — wie das Original: **nur** Eintraege mit der
--- Schwierigkeit des gedroppten Items, davon den besten Wert.
--- Ohne bekannte Schwierigkeit wird bewusst NICHTS geliefert statt geraten (das Original
--- zeigt dann ebenfalls `---`); der Zell-Renderer versucht es danach erneut.
--- @return table[] Liste von { e, role, simKey, simType, baseline, art }
local function sammleEintraege(daten, itemId, zielDif)
    local liste = {}
    if not zielDif then return liste end
    for specId, sims in pairs(daten.specs) do
        local role = ns.RolleVonSpec(tonumber(specId))
        for simKey, sim in pairs(sims) do
            local ergebnisse = sim.items and sim.items[itemId]
            if ergebnisse then
                local treffer
                for _, e in ipairs(ergebnisse) do
                    if e.difficultyId == zielDif then
                        local wert = e.gain or e.gainPercent
                        local bester = treffer and (treffer.gain or treffer.gainPercent)
                        if wert and (not treffer or wert > bester) then
                            treffer = e
                        end
                    end
                end
                if treffer and (treffer.gain or treffer.gainPercent) then
                    liste[#liste + 1] = {
                        e = treffer, role = role, simKey = tostring(simKey),
                        simType = sim.simType, baseline = sim.baseline, art = "dif",
                    }
                end
            end
        end
    end
    return liste
end

--- Diagnose: alle Sims + Eintraege zum aktuellen Item mitschreiben (fuer /wup rcl
--- und zum Auslesen aus der SavedVariables-Datei).
local function diagnoseErfassen(kandidat, daten, itemId, itemIlvl, zielDif, kontext, gewaehlt, quelle)
    ns.diagnose = ns.diagnose or {}
    local eintraege = {}
    for specId, sims in pairs(daten.specs or {}) do
        for simKey, sim in pairs(sims) do
            local ergebnisse = sim.items and sim.items[itemId]
            if ergebnisse then
                for _, e in ipairs(ergebnisse) do
                    eintraege[#eintraege + 1] = ("%s | spec %s | sim %s | simType %s | ilvl %s | diff %s | gain %s | pct %s")
                        :format(kandidat, tostring(specId), tostring(simKey), tostring(sim.simType),
                                tostring(e.ilvl), tostring(e.difficultyId), tostring(e.gain), tostring(e.gainPercent))
                end
            end
        end
    end
    ns.diagnose[kandidat] = {
        itemId = itemId, ilvlLink = itemIlvl, kontext = kontext, zielDif = zielDif,
        kontextQuelle = quelle,
        nameNormalisiert = select(2, ns.PrioVon(kandidat)),
        prio = ns.PrioVon(kandidat),
        gewaehlt = gewaehlt and {
            simKey = gewaehlt.simKey, ilvl = gewaehlt.e.ilvl, difficultyId = gewaehlt.e.difficultyId,
            gain = gewaehlt.e.gain, gainPercent = gewaehlt.e.gainPercent, art = gewaehlt.art,
        } or nil,
        eintraege = eintraege,
    }
end

--- Diagnose in die SavedVariables schreiben — wird beim /reload bzw. Logout
--- als Datei gespeichert und kann dann ausgelesen werden.
local function diagnoseSichern()
    WowUtilsPlusDB = WowUtilsPlusDB or {}
    WowUtilsPlusDB.diagnose = ns.diagnose
    WowUtilsPlusDB.diagnoseGesehen = ns.gerenderteNamen
    WowUtilsPlusDB.diagnoseZeit = date("%Y-%m-%d %H:%M:%S")
end

--- Fenster erneut zeichnen lassen. Direkt nach einem /reload ist die Item-Info oft noch
--- nicht im Cache, dann ist der Kontext unbekannt — ein Wimpernschlag spaeter aber schon.
--- Max. 8 Versuche je Item, damit das keine Schleife wird.
function ns.NeuZeichnenPlanen()
    local item = ns.ItemImFenster()
    local link = item and item.link
    if not link then return end
    if ns.warteAufLink ~= link then
        ns.warteAufLink, ns.warteZaehler = link, 0
    end
    if (ns.warteZaehler or 0) >= 8 then return end
    ns.warteZaehler = (ns.warteZaehler or 0) + 1
    C_Timer.After(0.5, function()
        local v = RCL:GetActiveModule("votingframe") or RCL:GetModule("RCVotingFrame", true)
        if v and v.Update then v:Update() end
    end)
end

--- @return number? gewichtet, table? details
local function berechne(kandidat)
    if not WowUtilsAPI or not kandidat then return nil end
    local itemId, itemIlvl, zielDif, kontext, quelle = aktuellesItem()
    if not itemId then return nil end
    if not zielDif then
        ns.letzteUrsache = "kein-kontext"   -- Item-Info noch nicht geladen -> spaeter erneut
    end

    -- Wunschliste des Kandidaten fuer genau dieses Item in dieser Schwierigkeit.
    -- Im Spiel liegt sie unter "<difficultyId>-<itemId>" mit priorityId 1-5.
    local wunschPrio
    if zielDif and WowUtilsAPI.GetWishlist then
        local wunsch = WowUtilsAPI.GetWishlist(kandidat)
        local eintrag = wunsch and wunsch[("%d-%d"):format(zielDif, itemId)]
        if eintrag then
            wunschPrio = eintrag.priorityId or tonumber(eintrag.priority)
        end
    end

    local daten = WowUtilsAPI.GetDroptimizers(kandidat)
    if not (daten and daten.specs) then return nil end

    local liste = sammleEintraege(daten, itemId, zielDif)
    if #liste == 0 then
        if zielDif then ns.letzteUrsache = "kein-eintrag" end
        diagnoseErfassen(kandidat, daten, itemId, itemIlvl, zielDif, kontext, nil, quelle)
        return nil
    end
    ns.letzteUrsache = nil

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
        difficultyId = e.difficultyId,
        role = gewaehlt.role,
        simKey = gewaehlt.simKey,
        simType = gewaehlt.simType,
        baseline = gewaehlt.baseline,
        anzahl = #liste,
        zielDif = zielDif,
        kontext = kontext,
        kontextQuelle = quelle,
        art = gewaehlt.art,
    }
    local gewichtet, info = ns.Gewichten(basis, gewaehlt.role, kandidat, wunschPrio)
    details.faktor, details.grund, details.gewichtet = info.faktor, info.grund, gewichtet
    details.roleFaktor, details.prioFaktor, details.prio = info.roleFaktor, info.prioFaktor, info.prio
    details.wunschFaktor, details.wunsch = info.wunschFaktor, info.wunsch
    details.leistungFaktor = info.leistungFaktor
    details.leistung = info.leistung          -- Average log / First kill samt absoluten Zahlen
    details.wunschPrio = wunschPrio
    diagnoseErfassen(kandidat, daten, itemId, itemIlvl, zielDif, kontext, gewaehlt)
    return gewichtet, details
end

-- ---------------------------------------------------------------------------
-- Zell-Renderer + Tooltip
-- ---------------------------------------------------------------------------

local function tooltipZeigen(frame, kandidat)
    local d = ns.rohcache[kandidat]
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")

    -- Ohne Ergebnis bleibt nur die Ursache zu nennen. Die erste Zeile zeichnet WoW gross.
    if not d or d.fehlt then
        if d and d.fehlt == "kein-kontext" then
            GameTooltip:AddLine(rot("Item-Info noch nicht geladen — wird gleich erneut versucht"), 1, 0.4, 0.4)
        elseif d and d.fehlt == "kein-eintrag" then
            GameTooltip:AddLine(grau("Kein Sim-Eintrag fuer diese Schwierigkeit."))
        else
            GameTooltip:AddLine(grau("Keine Sim-Daten fuer dieses Item."))
        end
        GameTooltip:Show()
        return
    end

    local einheit = d.prozent and "%" or ""

    -- 1) Oben der Grundwert, aus dem gerechnet wird — der kommt aus WowUtils.
    GameTooltip:AddDoubleLine("Grundwert aus WowUtils", ns.Zahl(d.basis, einheit),
        1, 1, 1, 1, 1, 1)

    -- 2) Darunter Zeile fuer Zeile, was davon abgezogen wird.
    --    Drei Spalten: Faktor | Begruendung | Betrag, der in DIESEM Schritt wegfaellt.
    --    🔴 Der Faktor steht VORN. Ein Tooltip richtet nur zwei Spalten aus (links- und
    --    rechtsbuendig); der Faktor ist durch seine feste Form ("x0,90") von sich aus
    --    gleich breit und bildet so die dritte Spalte. Stuende er hinten, waeren die
    --    Spalten wieder versetzt. Die Betraege laufen mit und summieren sich zum Ergebnis.
    local lauf = d.basis
    local function zeile(faktor, text)
        faktor = tonumber(faktor) or 1.0
        local neu = lauf * faktor
        local betrag = neu - lauf
        lauf = neu
        GameTooltip:AddDoubleLine(
            ("%s  %s"):format(ns.Faktor(faktor), text),
            ns.Zahl(betrag, einheit),
            0.62, 0.62, 0.62, 1, 1, 1)
    end

    zeile(d.roleFaktor, "Rolle: " .. ns.RollenName(d.role))
    if d.prio then
        zeile(d.prioFaktor, "Prio: " .. tostring(d.prio))
    end
    if d.wunsch then
        zeile(d.wunschFaktor, "Wunschliste: "
            .. (ns.WUNSCHNAME[d.wunsch] or ("Wunsch " .. tostring(d.wunsch))))
    end

    local lw = d.leistung
    local det = lw and lw.details or nil
    if lw and lw.average and lw.average ~= 1.0 then
        local wert = (det and det.avgMedian) and ns.ZahlEinfach(det.avgMedian, " %") or ""
        zeile(lw.average, "Average log: " .. wert)
    end
    if lw and lw.firstkill and lw.firstkill ~= 1.0 then
        local wert = (det and det.fkPlatz) and ("Platz %s/%s"):format(
            tostring(det.fkPlatz), tostring(det.fkVon)) or ""
        zeile(lw.firstkill, "First kill: " .. wert)
    end
    if lw and lw.movement and lw.movement ~= 1.0 then
        -- Movement wird auf der Seite als Abzug in Prozent gepflegt.
        local abzug = (1.0 - lw.movement) * 100.0
        zeile(lw.movement, "Movement: -" .. ns.ZahlEinfach(abzug) .. " %")
    end

    -- 3) Unten das Ergebnis.
    GameTooltip:AddDoubleLine("Gewichtet", ns.Zahl(d.gewichtet, einheit),
        1, 1, 1, 1, 0.85, 0.2)

    if d.grund then
        GameTooltip:AddLine(d.grund, 0.7, 0.7, 0.7, true)
    end
    if not d.kontext then
        GameTooltip:AddLine(rot("Item-Kontext noch nicht lesbar — wird gleich erneut versucht"),
            1, 0.4, 0.4)
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
    ns.rohcache[kandidat] = details or { fehlt = ns.letzteUrsache }
    ns.gerenderteNamen = ns.gerenderteNamen or {}
    ns.gerenderteNamen[kandidat] = true
    diagnoseSichern()
    if ns.letzteUrsache == "kein-kontext" then
        ns.NeuZeichnenPlanen()
    end

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
    -- Chat-Logging einschalten: die Ausgabe landet dann in Logs/WoWChatLog.txt auf dem PC.
    -- Chat-Text laesst sich im Spiel nicht kopieren, die Datei kann ich aber auslesen.
    pcall(SetCVar, "LogChat", 1)
    print("|cffffd700WoWUtils Plus — RCL-Diagnose|r")
    local item = ns.ItemImFenster()
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
    if #namen == 0 and ns.gerenderteNamen then
        for n in pairs(ns.gerenderteNamen) do namen[#namen + 1] = n end
    end
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
    print("|cff969696  (Diagnose wird beim /reload automatisch in die Datei geschrieben)|r")
end
