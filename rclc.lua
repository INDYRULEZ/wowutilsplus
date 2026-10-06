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
local SPALTE_ITEMS = "wowutilsplusitems"
local SPALTE_CRESTS = "wowutilspluscrests"
local SPALTE_SET = "wowutilsplusset"
local BREITE = 90

-- RCLootCouncil muss geladen sein (OptionalDeps im .toc)
if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("RCLootCouncil")) then return end
local RCL = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil", true)
if not RCL then return end

local mod = RCL:NewModule("WowUtilsPlusRCLC", "AceHook-3.0")
ns.RCL = RCL               -- fuer daten.lua: die Loot-Historie liegt in RCL
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
    details.itemsFaktor, details.itemsStand = info.itemsFaktor, info.itemsStand
    details.crestFaktor, details.crestStand = info.crestFaktor, info.crestStand
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

    -- 🔴 Der Leistungsblock (Average, First kill, Movement) wird ADDIERT, nicht multipliziert
    -- (Jonas, 06.10.2026). Alle drei Abzuege rechnen deshalb auf denselben Stand — den Wert
    -- nach Rolle/Prio/Wunschliste. Nur so summieren sich die Betraege genau zum Ergebnis;
    -- multiplikativ wuerde jeder Abzug auf dem schon verkleinerten Wert rechnen.
    local blockBasis, blockSumme = nil, 0.0
    local function zeileAdditiv(faktor, text)
        faktor = tonumber(faktor) or 1.0
        if not blockBasis then blockBasis, blockSumme = lauf, 0.0 end
        local betrag = -blockBasis * (1.0 - faktor)
        blockSumme = blockSumme + (1.0 - faktor)
        GameTooltip:AddDoubleLine(
            ("%s  %s"):format(ns.Faktor(faktor), text),
            ns.Zahl(betrag, einheit),
            0.62, 0.62, 0.62, 1, 1, 1)
    end
    local function blockSchliessen()
        if blockBasis then
            lauf = blockBasis * (1.0 - blockSumme)
            blockBasis = nil
        end
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
        zeileAdditiv(lw.average, "Average log: " .. wert)
    end
    if lw and lw.firstkill and lw.firstkill ~= 1.0 then
        local wert = (det and det.fkPlatz) and ("Platz %s/%s"):format(
            tostring(det.fkPlatz), tostring(det.fkVon)) or ""
        zeileAdditiv(lw.firstkill, "First kill: " .. wert)
    end
    if lw and lw.movement and lw.movement ~= 1.0 then
        -- Movement wird auf der Seite als Abzug in Prozent gepflegt.
        local abzug = (1.0 - lw.movement) * 100.0
        zeileAdditiv(lw.movement, "Movement: -" .. ns.ZahlEinfach(abzug) .. " %")
    end
    blockSchliessen()
    -- Items + Crests: EIN Faktor, addiert (Jonas, 06.10.2026). Schreibweise der Zahlen wie in
    -- den beiden Spalten: Items "gesamt · seit Reset n", Crests "hat + frei".
    if d.itemsFaktor and d.crestFaktor
            and (d.itemsFaktor ~= 1.0 or d.crestFaktor ~= 1.0) then
        local zusammen = 1.0 - ((1.0 - d.itemsFaktor) + (1.0 - d.crestFaktor))
        local teile = {}
        if d.itemsStand and d.itemsFaktor ~= 1.0 then
            teile[#teile + 1] = "Items " .. tostring(d.itemsStand.gesamt or "?")
                .. " · seit Reset " .. tostring(d.itemsStand.seitReset or "?")
        end
        if d.crestStand and d.crestFaktor ~= 1.0 then
            local text = tostring(d.crestStand.hat or "?")
            if d.crestStand.frei then text = text .. " + " .. tostring(d.crestStand.frei) end
            teile[#teile + 1] = "Crests " .. text
        end
        zeile(zusammen, table.concat(teile, " · "))
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
-- Spalten „Items" und „Crests"
--
-- Items:  insgesamt + heute. Nur „heute" wirkt als Faktor (siehe loot.lua).
-- Crests: „hat + frei" der Stufe Mythic; die anderen drei Stufen stehen im Tooltip.
-- Beide Spalten rechnen zur Not selbst nach — sie haengen nicht daran, dass die
-- Spalte „Gewichtet" vorher gezeichnet wurde.
-- ---------------------------------------------------------------------------

ns.cacheItems, ns.cacheCrests = {}, {}

local function itemsDaten(kandidat)
    local d = ns.rohcache and ns.rohcache[kandidat]
    if d and d.itemsStand then return d.itemsStand, d.itemsFaktor or 1.0 end
    local stand = ns.ItemsStand and ns.ItemsStand(kandidat)
    if not stand then return nil, 1.0 end
    return stand, (ns.ItemsFaktorKurve and ns.ItemsFaktorKurve(stand.seitReset)) or 1.0
end

local function crestDaten(kandidat)
    local d = ns.rohcache and ns.rohcache[kandidat]
    if d and d.crestStand then return d.crestStand, d.crestFaktor or 1.0 end
    local stand = ns.CrestStand and ns.CrestStand(kandidat)
    if not stand then return nil, 1.0 end
    local wert = (tonumber(stand.hat) or 0) + (tonumber(stand.frei) or 0)
    return stand, (ns.CrestWertFaktor and ns.CrestWertFaktor(wert)) or 1.0
end

local function tooltipItems(frame, kandidat)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    local stand, faktor = itemsDaten(kandidat)
    if not stand then
        GameTooltip:AddLine(grau("Keine Loot-Historie fuer diesen Spieler."))
        GameTooltip:Show()
        return
    end
    GameTooltip:AddLine("Items")
    GameTooltip:AddDoubleLine("insgesamt", tostring(stand.gesamt), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("seit Reset", tostring(stand.seitReset), 1, 1, 1, 1, 1, 1)
    for i = 1, math.min(#(stand.seitResetListe or {}), 8) do
        GameTooltip:AddLine(stand.seitResetListe[i], 0.62, 0.62, 0.62, true)
    end
    if faktor ~= 1.0 then
        GameTooltip:AddDoubleLine("Faktor", ns.Faktor(faktor), 1, 1, 1, 1, 0.85, 0.2)
    end
    GameTooltip:Show()
end

function ns.UpdateZelleItems(rowFrame, frame, data, cols, row, realrow, column, fShow, table)
    local kandidat = data and data[realrow] and data[realrow].name
    if not kandidat then
        frame.text:SetText("---")
        return
    end
    local stand = itemsDaten(kandidat)
    ns.cacheItems[kandidat] = stand and stand.seitReset or -math.huge
    frame.text:SetWordWrap(false)
    frame.text:SetNonSpaceWrap(false)
    if not stand then
        frame.text:SetText("---")
        frame.text:SetTextColor(0.6, 0.6, 0.6)
    else
        frame.text:SetText(tostring(stand.gesamt) .. " · seit Reset " .. tostring(stand.seitReset))
        if stand.seitReset > 0 then
            frame.text:SetTextColor(1.0, 0.62, 0.31)
        else
            frame.text:SetTextColor(0.31, 0.86, 0.39)
        end
    end
    frame:SetScript("OnEnter", function(self) tooltipItems(self, kandidat) end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function tooltipCrests(frame, kandidat)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    local stand, faktor = crestDaten(kandidat)
    if not stand then
        GameTooltip:AddLine(grau("Keine Crest-Daten — dieser Spieler laeuft WowUtils nicht."))
        GameTooltip:Show()
        return
    end
    GameTooltip:AddLine("Crests")
    for _, s in ipairs(stand.stufen) do
        -- 🔴 Nur Hero (3445) und Mythic (3446) zeigen — Veteran und Champion sind fuer
        -- die Vergabe uninteressant (Jonas, 04.10.2026). Nicht wieder einblenden.
        if s.id ~= 3443 and s.id ~= 3444 then
            local rechts = tostring(s.hat)
            if s.frei then rechts = rechts .. " + " .. tostring(s.frei) .. " frei" end
            if s.grenze then rechts = rechts .. "  / " .. tostring(s.grenze) end
            if s.id == 3446 then
                GameTooltip:AddDoubleLine(s.name, rechts, 0.62, 0.62, 0.62, 1, 0.85, 0.2)
            else
                GameTooltip:AddDoubleLine(s.name, rechts, 0.62, 0.62, 0.62, 1, 1, 1)
            end
        end
    end
    if faktor ~= 1.0 then
        GameTooltip:AddDoubleLine("Faktor (Mythic)", ns.Faktor(faktor), 1, 1, 1, 1, 0.85, 0.2)
    end
    GameTooltip:Show()
end

function ns.UpdateZelleCrests(rowFrame, frame, data, cols, row, realrow, column, fShow, table)
    local kandidat = data and data[realrow] and data[realrow].name
    if not kandidat then
        frame.text:SetText("---")
        return
    end
    local stand, faktor = crestDaten(kandidat)
    ns.cacheCrests[kandidat] = stand and faktor or -math.huge
    frame.text:SetWordWrap(false)
    frame.text:SetNonSpaceWrap(false)
    if not stand then
        frame.text:SetText("---")
        frame.text:SetTextColor(0.6, 0.6, 0.6)
    else
        local text = tostring(stand.hat)
        if stand.frei then text = text .. " + " .. tostring(stand.frei) end
        frame.text:SetText(text)
        if faktor >= 0.9995 then
            frame.text:SetTextColor(0.31, 0.86, 0.39)
        else
            frame.text:SetTextColor(1.0, 0.62, 0.31)
        end
    end
    frame:SetScript("OnEnter", function(self) tooltipCrests(self, kandidat) end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function vergleicheItems(self, rowa, rowb)
    local na = self.data and self.data[rowa] and self.data[rowa].name
    local nb = self.data and self.data[rowb] and self.data[rowb].name
    local a = na and ns.cacheItems[na] or -math.huge
    local b = nb and ns.cacheItems[nb] or -math.huge
    if a == b then return false end
    return a < b
end

local function vergleicheCrests(self, rowa, rowb)
    local na = self.data and self.data[rowa] and self.data[rowa].name
    local nb = self.data and self.data[rowb] and self.data[rowb].name
    local a = na and ns.cacheCrests[na] or -math.huge
    local b = nb and ns.cacheCrests[nb] or -math.huge
    if a == b then return false end
    return a < b
end

-- ---------------------------------------------------------------------------
-- Spalte „Set": H S C G L
--
-- Ein Buchstabe je Tier-Slot, Reihenfolge fix: Kopf, Schulter, Brust, Hände, Beine.
--   grün   = hat das Teil (Token bekommen oder aus der Truhe geholt)
--   gelb   = liegt in seiner Truhe und ist noch nicht abgeholt
--   rot    = der Slot, um den es gerade geht, ist bei ihm schon belegt -> darf er nicht
--   grau   = nichts bekannt
-- ---------------------------------------------------------------------------

ns.cacheSets = {}

local SET_FARBE = {
    hat    = "|cff50dc64",
    offen  = "|cfff0c040",
    nichts = "|cff6b6b6b",
    belegt = "|cffff5a5a",
}

local ZUSTAND_TEXT = {
    angezogen = "angezogen",
    token = "Token bekommen",
    vault = "aus der Truhe geholt",
    ["vault-offen"] = "liegt noch in der Truhe",
}

--- Slot-Schluessel des Tokens, das gerade im Fenster steht (oder nil).
local function zielSlot()
    if not ns.TokenImFenster then return nil end
    local slot = ns.TokenImFenster()
    return slot
end

local function tooltipSet(frame, kandidat)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    local stand, anzahl = ns.SetStand(kandidat)
    local ziel = zielSlot()

    GameTooltip:AddLine("Tier-Set")
    if ziel then
        GameTooltip:AddLine("Ziel: " .. ns.SlotName(ziel), 1, 0.85, 0.2)
    end
    for _, s in ipairs(ns.SET_SLOTS) do
        local d = stand and stand[s.key]
        local rechts, warnung, wr, wg, wb = nil, nil, 1, 1, 1
        if d then
            rechts = ZUSTAND_TEXT[d.zustand] or d.zustand
            if d.name then rechts = rechts .. " · " .. d.name end
            if d.datum then rechts = rechts .. " · " .. d.datum end
        else
            rechts = "nichts bekannt"
        end
        if ziel == s.key and d then
            -- 🔴 Nur wer das Teil WIRKLICH hat, ist ausgeschlossen. Ein Teil, das noch in der
            -- Truhe liegt, ist ein Hinweis — kein Ausschluss.
            if d.zustand == "vault-offen" then
                warnung, wr, wg, wb = "liegt in der TRUHE", 1, 0.75, 0.2
            else
                warnung, wr, wg, wb = "SCHON BELEGT", 1, 0.35, 0.35
            end
            rechts = warnung .. " — " .. rechts
            GameTooltip:AddDoubleLine(s.name, rechts, 1, 1, 1, wr, wg, wb)
        else
            GameTooltip:AddDoubleLine(s.name, rechts, 0.62, 0.62, 0.62, 1, 1, 1)
        end
    end
    if (anzahl or 0) > 0 then
        GameTooltip:AddDoubleLine("bekannt", string.format("%d von 5", anzahl), 1, 1, 1, 1, 0.85, 0.2)
    end
    GameTooltip:Show()
end

-- 🔴 Der letzte Parameter heißt in der RCL-API `table` und verdeckt damit Luas
-- Tabellen-Bibliothek — `table.concat` wäre hier ein Nil-Zugriff. Deshalb `tabelle`.
function ns.UpdateZelleSet(rowFrame, frame, data, cols, row, realrow, column, fShow, tabelle)
    local kandidat = data and data[realrow] and data[realrow].name
    frame.text:SetWordWrap(false)
    frame.text:SetNonSpaceWrap(false)
    if not kandidat then
        frame.text:SetText("---")
        return
    end
    local stand, anzahl = ns.SetStand(kandidat)
    ns.cacheSets[kandidat] = anzahl or 0
    if not anzahl or anzahl == 0 then
        frame.text:SetText("---")
        frame.text:SetTextColor(0.6, 0.6, 0.6)
    else
        local ziel = zielSlot()
        local teile = {}
        for _, s in ipairs(ns.SET_SLOTS) do
            local d = stand and stand[s.key]
            local farbe
            if d and (d.zustand == "angezogen" or d.zustand == "token" or d.zustand == "vault") then
                farbe = SET_FARBE.hat
            elseif d then
                farbe = SET_FARBE.offen
            else
                farbe = SET_FARBE.nichts
            end
            -- Ziel-Slot und wirklich schon vorhanden: rot, das ist die Ausschluss-Markierung.
            -- Ein blosses Truhen-Teil bleibt gelb — es ist ein Hinweis, kein Ausschluss.
            if ziel == s.key and d and d.zustand ~= "vault-offen" then
                farbe = SET_FARBE.belegt
            end
            teile[#teile + 1] = farbe .. s.brief .. "|r"
        end
        frame.text:SetText(table.concat(teile, " ") .. "  " .. anzahl .. "/5")
        frame.text:SetTextColor(1, 1, 1)
    end
    frame:SetScript("OnEnter", function(self) tooltipSet(self, kandidat) end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function vergleicheSet(self, rowa, rowb)
    local na = self.data and self.data[rowa] and self.data[rowa].name
    local nb = self.data and self.data[rowb] and self.data[rowb].name
    local a = na and ns.cacheSets[na] or -math.huge
    local b = nb and ns.cacheSets[nb] or -math.huge
    if a == b then return false end
    return a < b
end

-- ---------------------------------------------------------------------------
-- Spalte einhaengen
-- ---------------------------------------------------------------------------

local eingehaengt = false

--- Das Abstimmungsfenster (fuer die Live-Umschaltung).
local function votingFenster()
    return RCL:GetActiveModule("votingframe") or RCL:GetModule("RCVotingFrame", true)
end

--- Ist eine Spalte gerade im Fenster?
local function spalteDa(voting, colName)
    local da = false
    pcall(function() da = voting.GetColumn and voting:GetColumn(colName) ~= nil end)
    return da and true or false
end

--- Die Set-Spalte einhaengen. Wird beim Start UND beim Einschalten benutzt, damit es
--- nur eine Stelle gibt, die sie definiert.
--- 🔴 `sortnext` muss auf eine Spalte zeigen, die es WIRKLICH gibt: ist die Crests-Spalte
--- ausgeblendet, laeuft die Sortierkette sonst ins Leere. Der Nachbar ist deshalb nicht
--- fest verdrahtet, sondern wird beim Einhaengen bestimmt.
local function setSpalteEinhaengen(voting, crestsDa)
    if spalteDa(voting, SPALTE_SET) then return true end
    if crestsDa == nil then crestsDa = spalteDa(voting, SPALTE_CRESTS) end
    local ziel = crestsDa and SPALTE_CRESTS or SPALTE_ITEMS
    voting:AddColumn({
        colName = SPALTE_SET,
        name = "Set",
        width = 112,
        align = "CENTER",
        sortnext = ziel,
        comparesort = vergleicheSet,
        DoCellUpdate = ns.UpdateZelleSet,
    }, ziel, "after")
    return true
end

--- Die Crests-Spalte einhaengen (Start UND Einschalten).
local function crestSpalteEinhaengen(voting)
    if spalteDa(voting, SPALTE_CRESTS) then return true end
    voting:AddColumn({
        colName = SPALTE_CRESTS,
        name = "Crests",
        width = 96,
        align = "CENTER",
        sortnext = SPALTE_ITEMS,
        comparesort = vergleicheCrests,
        DoCellUpdate = ns.UpdateZelleCrests,
    }, SPALTE_ITEMS, "after")
    return true
end

--- Die Set-Spalte neu einhaengen, damit ihr `sortnext`-Index neu berechnet wird.
--- Nur, wenn sie gerade im Fenster steht. Wird gebraucht, wenn sich ihr linker Nachbar
--- aendert (Crests-Spalte an/aus) — die API rechnet die Namen nur beim Einhaengen um.
local function setSpalteNachziehen(voting)
    if not spalteDa(voting, SPALTE_SET) then return end
    voting:RemoveColumn(SPALTE_SET)
    setSpalteEinhaengen(voting)
end

--- Eine eigene Spalte im offenen Fenster an- oder ausschalten (ohne /reload).
--- @param an boolean
--- @param einhaengen function(voting) die Spalte einhaengen
--- @param colName string die entfernte Spalte
--- @return boolean ob es sofort erledigt werden konnte
local function spalteLiveUmschalten(an, einhaengen, colName)
    local voting = votingFenster()
    if not (voting and voting.AddColumn and voting.RemoveColumn) then return false end
    local ok = pcall(function()
        if an then einhaengen(voting) else voting:RemoveColumn(colName) end
    end)
    if ok then
        if colName == SPALTE_CRESTS then pcall(setSpalteNachziehen, voting) end
        -- Neuzeichnen getrennt absichern: schlaegt es fehl, ist die Spalte trotzdem umgestellt.
        pcall(function()
            local rahmen = voting.frame
            if rahmen and rahmen.Update then rahmen:Update() end
        end)
    end
    return ok
end

--- Set-Spalte im offenen Fenster an- oder ausschalten.
function ns.SetSpalteLiveUmschalten(an)
    return spalteLiveUmschalten(an, setSpalteEinhaengen, SPALTE_SET)
end

--- Crests-Spalte im offenen Fenster an- oder ausschalten.
function ns.CrestSpalteLiveUmschalten(an)
    return spalteLiveUmschalten(an, crestSpalteEinhaengen, SPALTE_CRESTS)
end

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

        -- „Items": insgesamt + heute. Nur „heute" wirkt als Faktor.
        voting:AddColumn({
            colName = SPALTE_ITEMS,
            name = "Items",
            width = 118,
            align = "CENTER",
            sortnext = SPALTE,
            comparesort = vergleicheItems,
            DoCellUpdate = ns.UpdateZelleItems,
        }, SPALTE, "after")

        -- „Crests": hat + frei (Mythic). Die anderen Stufen stehen im Tooltip.
        -- Laesst sich einschalten (Kaestchen in den RCL-Einstellungen oder /wup crests).
        -- 🔴 Vorgabe ist AUS: wer sie will, schaltet sie ein.
        local crestsDa = false
        if ns.Einstellung("crestSpalte", false) then
            crestSpalteEinhaengen(voting)
            crestsDa = true
        end

        -- „Set": H S C G L — welche Tier-Teile jemand hat bzw. sicher bekommt.
        -- Laesst sich einschalten (Kaestchen in den RCL-Einstellungen oder /wup set).
        -- 🔴 Vorgabe ist AUS: wer sie will, schaltet sie ein.
        if ns.Einstellung("setSpalte", false) then
            setSpalteEinhaengen(voting, crestsDa)
        end
    end)
    if not ok then
        ns.spaltenFehler = tostring(fehler)
        return false
    end
    eingehaengt = true
    return true
end

-- ---------------------------------------------------------------------------
-- Klick-Option in den RCL-Einstellungen
--
-- RCL meldet seine Seite selbst an:
--   RegisterOptionsTable("RCLootCouncil", …) + AddToBlizOptions("RCLootCouncil", "RCLootCouncil", nil, "settings")
-- Wir melden eine eigene Tabelle an und haengen sie als Unterseite unter „RCLootCouncil" —
-- zu finden unter: Interface > AddOns > RCLootCouncil > WoWUtils Plus
-- ---------------------------------------------------------------------------

local OPTION_TABELLE = {
    type = "group",
    name = "WoWUtils Plus",
    args = {
        hinweis = {
            type = "description",
            name = "Eigene Spalten fuer das Abstimmungsfenster.",
            order = 1,
        },
        setSpalte = {
            type = "toggle",
            name = "Set-Spalte anzeigen",
            desc = "Zeigt eine Spalte mit den Tier-Set-Teilen der Kandidaten "
                   .. "(H = Kopf, S = Schulter, C = Brust, G = Hände, L = Beine). "
                   .. "Die Änderung wirkt sofort.",
            width = "full",
            order = 3,
            get = function() return ns.Einstellung("setSpalte", false) and true or false end,
            set = function(_, wert)
                ns.EinstellungSetzen("setSpalte", wert and true or false)
                if ns.SetSpalteLiveUmschalten and not ns.SetSpalteLiveUmschalten(wert and true or false) then
                    print("|cffffd700WoWUtils Plus:|r Fenster gerade nicht offen — "
                          .. "die Set-Spalte gilt beim nächsten Öffnen.")
                end
            end,
        },
        crestSpalte = {
            type = "toggle",
            name = "Crests-Spalte anzeigen",
            desc = "Zeigt eine Spalte mit den Mythic-Crests der Kandidaten "
                   .. "(in der Tasche + bis zur Obergrenze frei). "
                   .. "Die Änderung wirkt sofort.",
            width = "full",
            order = 2,
            get = function() return ns.Einstellung("crestSpalte", false) and true or false end,
            set = function(_, wert)
                ns.EinstellungSetzen("crestSpalte", wert and true or false)
                if ns.CrestSpalteLiveUmschalten and not ns.CrestSpalteLiveUmschalten(wert and true or false) then
                    print("|cffffd700WoWUtils Plus:|r Fenster gerade nicht offen — "
                          .. "die Crests-Spalte gilt beim nächsten Öffnen.")
                end
            end,
        },
    },
}

--- Ist RCLs eigene Kategorie im Einstellungsfenster schon angemeldet?
--- 🔴 Nur dann kann unser Aufruf mit Elternnamen ueberhaupt klappen.
local function elternKategorieDa(dialog)
    local karte = dialog and dialog.BlizOptionsIDMap
    return (type(karte) == "table" and karte["RCLootCouncil"] ~= nil) or false
end

local function optionAnmelden(letzterVersuch)
    if ns._optionAngemeldet then return true end

    local okD, dialog = pcall(function() return LibStub("AceConfigDialog-3.0", true) end)
    if not okD or not dialog or not dialog.AddToBlizOptions then
        ns.optionFehler = "AceConfigDialog-3.0 fehlt"
        return false
    end

    -- Die eigene Tabelle einmalig anmelden (zweimal wuerde einen Fehler geben).
    -- 🔴 UNTER BEIDEN NAMEN: die Unterseite laeuft unter "WowUtilsPlusRCL", die eigene Seite
    -- unter "WowUtilsPlus". Der Eintrag holt seine Einstellungen ueber genau diesen Namen —
    -- fehlt er, erscheint die Seite, bleibt aber LEER. Genau das war der Fehler.
    if not ns._optionRegistriert then
        local okR, fehlerR = pcall(function()
            LibStub("AceConfig-3.0"):RegisterOptionsTable("WowUtilsPlusRCL", OPTION_TABELLE)
            LibStub("AceConfig-3.0"):RegisterOptionsTable("WowUtilsPlus", OPTION_TABELLE)
        end)
        if not okR then
            ns.optionFehler = "Anmelden der Tabelle: " .. tostring(fehlerR)
            return false
        end
        ns._optionRegistriert = true
    end

    -- 1) Als Unterseite unter RCLootCouncil — mit EIGENEM App-Namen.
    --    🔴 Nicht denselben App-Namen wie unten nehmen: ein fehlgeschlagener Aufruf legt den
    --    Eintrag trotzdem an und blockt den Namen fuer den Rest der Sitzung. Genau daran ist
    --    der Ausweich auf die eigene Seite vorher gescheitert.
    if elternKategorieDa(dialog) and not ns._rclVersucht then
        ns._rclVersucht = true
        local ok, fehler = pcall(dialog.AddToBlizOptions, dialog,
                                 "WowUtilsPlusRCL", "WoWUtils Plus", "RCLootCouncil")
        if ok then
            ns._optionAngemeldet, ns.optionWeg = true, "unter RCLootCouncil"
            return true
        end
        ns.optionFehlerRCL = tostring(fehler)
    end

    -- 2) Eigene Seite — wenn unter RCL nicht ging, oder wenn RCL sich gar nicht meldet
    --    (dann erst beim letzten Versuch, damit es nicht vorher schon doppelt landet).
    local unterRCLGescheitert = (ns._rclVersucht and ns.optionFehlerRCL ~= nil)
    if not ns._eigenVersucht and (unterRCLGescheitert or letzterVersuch) then
        ns._eigenVersucht = true
        local ok, fehler = pcall(dialog.AddToBlizOptions, dialog, "WowUtilsPlus", "WoWUtils Plus")
        if ok then
            ns._optionAngemeldet, ns.optionWeg = true, "eigene Seite"
            return true
        end
        ns.optionFehlerEigen = tostring(fehler)
    end

    if letzterVersuch then
        ns.optionFehler = ("unter RCL: %s | eigene Seite: %s")
                            :format(tostring(ns.optionFehlerRCL), tostring(ns.optionFehlerEigen))
    end
    return false
end

--- Spaeter nochmal versuchen — RCL meldet seine eigene Seite evtl. erst kurz nach uns an.
--- Beim letzten Versuch wird auf die eigene Seite ausgewichen.
local optionVersuche = 0
local function optionNachfassen()
    optionVersuche = optionVersuche + 1
    local letzter = optionVersuche >= 10
    if optionAnmelden(letzter) then return end
    if not letzter and C_Timer and C_Timer.After then
        C_Timer.After(3, optionNachfassen)
    end
end

function mod:OnInitialize()
    -- Klick-Option in den RCL-Einstellungen anmelden (und bei Bedarf nachfassen)
    optionNachfassen()

    -- RCL braucht einen Moment, bis das Abstimmungsfenster-Modul steht
    local versuche = 0
    -- 🔴 `local t` MUSS vor dem Ticker stehen. In `local t = C_Timer.NewTicker(1, function()
    -- ... t:Cancel() end)` ist `t` innerhalb der Funktion noch nicht in Sichtweite — Lua bindet
    -- den Namen dort an ein GLOBALES `t`, das es nicht gibt:
    -- „rclc.lua:442: attempt to index global 't' (a nil value)", bei JEDEM Laden, sobald die
    -- Spalte haengt. Gemeldet von Jonas (BugSack) am 03.10.2026. Nicht wieder zusammenziehen.
    local t
    t = C_Timer.NewTicker(1, function()
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
