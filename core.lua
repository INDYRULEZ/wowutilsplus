--[[ WoWUtils Plus — Zusatz-Auswertung auf Basis der WowUtils-Daten.

Liest die Daten NICHT selbst aus der Bridge-Datei, sondern ueber die offizielle
Schnittstelle des Original-Addons (Global `WowUtilsAPI`, siehe publicAPI.lua).
Damit bleibt ein Update des Originals konfliktfrei.

Erste Ausbaustufe: EIN Gewichtungsfaktor (Heiler), Anzeige im Chat.
Der Grund fuer die Reduzierung wird immer mitgeliefert ("warum").
]]

local addonName, ns = ...   -- ns ist nur unser eigener Namensraum

ns.VERSION = "0.5.0"

-- ---------------------------------------------------------------------------
-- Gewichtungen
-- Rolle -> Faktor + Begruendung. Bewusst als Tabelle, damit weitere Faktoren
-- einfach ergaenzt werden koennen. 1.0 = unveraendert.
-- ---------------------------------------------------------------------------
-- Vorgabe, falls gewichte.lua fehlt. Normalerweise kommt die Tabelle aus
-- gewichte.lua, das die Weboberflaeche erzeugt (laedt vor dieser Datei).
ns.WEIGHTS = ns.WEIGHTS or {
    HEALER  = { factor = 0.52 },
    TANK    = { factor = 1.15 },
    DAMAGER = { factor = 1.0 },
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

--- Zahl ohne Vorzeichen, deutsches Komma — fuer Prozentwerte und Anteile.
--- @param wert number
--- @param einheit string?
--- @return string
function ns.ZahlEinfach(wert, einheit)
    local s = ("%.2f"):format(tonumber(wert) or 0)
    return s:gsub("%.", ",") .. (einheit or "")
end

--- Der Gewinn eines Items in Prozent, so wie die Sim ihn ausgibt: Grundwert / Bezugswert * 100.
--- Nur moeglich, wenn die Sim einen Bezugswert („baseline") mitliefert — das tun die
--- Raidbots-Sims (DPS und Tanks). Bei QE Live (Heiler) fehlt er: dort IST der Wert schon ein
--- Prozentwert, deshalb gibt es hier nichts umzurechnen.
--- 🔴 Zweck (Jonas, 09.10.2026): DPS- und Heiler-Gewinne sollen vergleichbar sein — bei Heilern
--- steht der Prozentwert in der Spalte, bei DPS wird er dahinter angehaengt.
--- @param basis number? Grundwert (absoluter Gewinn)
--- @param baseline number? Bezugswert der Sim
--- @return number? Prozentwert (z. B. 1.65) oder nil, wenn nicht rechenbar
function ns.ProzentGewinn(basis, baseline)
    if type(basis) ~= "number" or type(baseline) ~= "number" then return nil end
    if baseline == 0 then return nil end
    return basis / baseline * 100.0
end

--- Der Zusatz, der hinter einem Wert steht: „ (+1,65 %)".
--- Leer bei Heilern (dort IST der Wert schon Prozent) und wenn kein Bezugswert vorliegt.
--- An EINER Stelle, damit Spalte und Tooltip nie auseinanderlaufen.
--- @param basis number? Grundwert
--- @param baseline number? Bezugswert der Sim
--- @param istProzent boolean? true = der Wert ist schon ein Prozentwert (QE Live)
--- @return string
function ns.GewinnZusatz(basis, baseline, istProzent)
    if istProzent then return "" end
    local pct = ns.ProzentGewinn(basis, baseline)
    if not pct then return "" end
    return " (" .. ns.Zahl(pct, " %") .. ")"
end

--- Ganze Zahl mit Tausenderpunkt, z. B. 199.641.
--- @param wert number
--- @return string
function ns.ZahlTausend(wert)
    local s = ("%d"):format(math.floor((tonumber(wert) or 0) + 0.5))
    local fertig = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    return (fertig:gsub("^%.", ""))
end

--- Anzeigenamen der Rollen — ueberall dieselben Worte wie auf der Weboberflaeche.
ns.ROLLENNAME = { DAMAGER = "DPS", HEALER = "Healer", TANK = "Tank" }

-- Vorgabe, falls gewichte.lua fehlt (siehe oben).
ns.WUNSCH = ns.WUNSCH or { [1] = 1.0, [2] = 0.6 }

--- Leistungs-Faktoren: Average log, First kill log, Movement/Survival.
--- Die Werte je Spieler werden spaeter automatisch berechnet; vorerst neutral.
ns.LEISTUNG = ns.LEISTUNG or { average = 1.0, firstkill = 1.0, movement = 1.0 }

ns.LEISTUNGNAME = {
    average   = "Average log",
    firstkill = "First kill log",
    movement  = "Movement/Survival",
}

--- Leistungswerte je Spieler, aus Warcraft Logs berechnet (gewichte.lua).
--- Schluessel = normalisierter Charaktername, wie bei der Prioritaetsliste.
--- Aufbau: ns.LEISTUNG_SPIELER["name"] = { average = 1.05, firstkill = 0.92, movement = 1.0 }
--- Fehlt eine Angabe, gilt der Wert aus ns.LEISTUNG (Vorgabe 1.0).
ns.LEISTUNG_SPIELER = ns.LEISTUNG_SPIELER or {}
ns.LEISTUNG_REFERENZ = ns.LEISTUNG_REFERENZ or nil
ns.LEISTUNG_SPANNE = ns.LEISTUNG_SPANNE or nil

--- Die Leistungswerte einzeln, je Spieler aufgeloest.
--- Je Wert gilt: Angabe des Charakters schlaegt die allgemeine Vorgabe.
--- @param kandidat string? Charaktername
--- @return table { average, firstkill, movement, details }
function ns.LeistungsWerte(kandidat)
    local jeSpieler
    if kandidat and ns.Normalisiere then
        jeSpieler = ns.LEISTUNG_SPIELER[ns.Normalisiere(kandidat)]
    end
    local werte = {}
    for art, vorgabe in pairs(ns.LEISTUNG) do
        local wert = vorgabe
        if type(jeSpieler) == "table" and jeSpieler[art] ~= nil then
            wert = jeSpieler[art]
        elseif type(jeSpieler) == "number" and art == "average" then
            -- Alte Form: eine einzelne Zahl galt fuer den Average-Wert.
            wert = jeSpieler
        end
        werte[art] = tonumber(wert) or 1.0
    end
    werte.details = (type(jeSpieler) == "table") and jeSpieler or nil
    return werte
end

--- Gesamtfaktor aus den Leistungswerten.
--- 🔴 Additiv seit 06.10.2026 (Jonas): die drei Abzuege werden ADDIERT, nicht multipliziert.
--- 1 - ((1-average) + (1-firstkill) + (1-movement)). Rolle, Prio, Wunschliste, Items und
--- Crests bleiben multiplikativ — dieser Block ist genau EIN Faktor in der Kette.
--- @param kandidat string? Charaktername
--- @return number
function ns.LeistungFaktor(kandidat)
    local w = ns.LeistungsWerte(kandidat)
    local function f(v) if type(v) == "number" then return v end return 1.0 end
    local avg, fk, mo = f(w.average), f(w.firstkill), f(w.movement)
    if avg == 1.0 and fk == 1.0 and mo == 1.0 then return 1.0 end
    return 1.0 - ((1.0 - avg) + (1.0 - fk) + (1.0 - mo))
end

--- Faktor aus der Wunschlisten-Priorität (1 = Best in Slot, 2 = Upgrade).
--- @param prioId number? 1-5
--- @return number
function ns.WunschFaktor(prioId)
    if not prioId or not ns.WUNSCH then return 1.0 end
    return ns.WUNSCH[prioId] or 1.0
end

--- Anzeigename einer Wunschlisten-Prioritaet.
ns.WUNSCHNAME = {
    [1] = "Best in Slot",
    [2] = "Upgrade",
    [3] = "Offspec",
    [4] = "Transmog",
    [5] = "Nicht gewünscht",
}

--- @param role string
--- @return string
function ns.RollenName(role)
    return ns.ROLLENNAME[role] or tostring(role)
end

--- Faktor ohne Vorzeichen, deutsches Komma: "x0,25"
function ns.Faktor(f)
    local s = ("x%.2f"):format(f)
    return (s:gsub("%.", ","))
end

-- ---------------------------------------------------------------------------
-- Prioritaetsliste (aus der LC-Prioliste.ods, siehe prioliste.lua)
-- 1 = unveraendert, 5 = -40 %. Dazwischen gleichmaessig: 2 = -10 %, 3 = -20 %, 4 = -30 %.
-- ---------------------------------------------------------------------------

--- Namen vergleichbar machen: Kleinschreibung, Realm weg, Akzente weg.
--- Damit trifft "Dranash" aus der Liste auch den Char "dránash".
--- @param name string?
--- @return string?
function ns.Normalisiere(name)
    if not name then return nil end
    local s = tostring(name):lower()
    s = s:gsub("%-.*$", "")        -- Realm abtrennen
    s = s:gsub("%s+", "")          -- Leerzeichen weg
    for von, nach in pairs(ns.UMLAUT) do
        s = s:gsub(von, nach)
    end
    return s
end

ns.UMLAUT = {
    ["á"] = "a", ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["ã"] = "a", ["å"] = "a",
    ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
    ["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i",
    ["ó"] = "o", ["ò"] = "o", ["ô"] = "o", ["ö"] = "o", ["õ"] = "o",
    ["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
    ["ç"] = "c", ["ñ"] = "n", ["ß"] = "ss",
}

--- Faktor aus der Prioritaet: 1 -> 1.0, 5 -> 0.6, dazwischen 10-%-Schritte.
--- @param prio number 1-5
--- @return number
function ns.PrioFaktor(prio)
    if not prio then return 1.0 end
    return 1.0 - (prio - 1) * 0.1
end

--- Prioritaet eines Kandidaten (normalisierter Name), nil wenn nicht auf der Liste.
--- @param kandidat string
--- @return number? prio, string? schluessel
function ns.PrioVon(kandidat)
    local s = ns.Normalisiere(kandidat)
    if not s or not ns.PRIO then return nil end
    return ns.PRIO[s], s
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

--- Einen Gewinn gewichten: Rollen-Faktor × Prioritaets-Faktor × Wunschlisten-Faktor.
--- @param wert number Basiswert (absoluter Gewinn ODER Prozentwert)
--- @param role string
--- @param kandidat string? Charaktername (fuer die Prioritaetsliste)
--- @param wunschPrio number? Wunschlisten-Prioritaet 1-5 (1 = BiS, 2 = Upgrade)
--- @return number gewichtet, table info
function ns.Gewichten(wert, role, kandidat, wunschPrio)
    local info = {
        wert = wert, role = role,
        roleFaktor = 1.0, prioFaktor = 1.0, wunschFaktor = 1.0,
        prio = nil, wunsch = nil, gruende = {},
    }
    local w = ns.WEIGHTS[role]
    if w and w.factor ~= 1.0 then
        info.roleFaktor = w.factor
        if w.reason then info.gruende[#info.gruende + 1] = w.reason end
    end
    local prio = ns.PrioVon(kandidat)
    if prio and prio > 1 then
        info.prio = prio
        info.prioFaktor = ns.PrioFaktor(prio)
    end
    if wunschPrio then
        -- Auch bei Faktor 1.00 merken (z. B. Best in Slot), damit der Tooltip zeigt,
        -- was auf der Wunschliste steht — vorher blieb die Zeile bei BiS stumm.
        info.wunsch = wunschPrio
        info.wunschFaktor = ns.WunschFaktor(wunschPrio)
    end
    local leistung = ns.LeistungsWerte(kandidat)
    info.leistung = leistung
    info.leistungFaktor = ns.LeistungFaktor(kandidat)
    -- Items seit Reset + Crests: Zahlen gibt es nur im Spiel. Fehlt die Datenquelle,
    -- bleibt der Faktor neutral 1.00 (siehe loot.lua).
    local itemsFaktor, itemsStand = 1.0, nil
    local crestFaktor, crestStand = 1.0, nil
    if ns.ItemsFaktor then itemsFaktor, itemsStand = ns.ItemsFaktor(kandidat) end
    if ns.CrestFaktor then crestFaktor, crestStand = ns.CrestFaktor(kandidat) end
    info.itemsFaktor, info.itemsStand = itemsFaktor or 1.0, itemsStand
    info.crestFaktor, info.crestStand = crestFaktor or 1.0, crestStand
    -- 🔴 Items und Crests bilden EINEN Faktor und werden ADDIERT (Jonas, 06.10.2026):
    -- 1 - ((1-Items) + (1-Crests)). Beide Stellschrauben der Seite bleiben erhalten, im Tooltip
    -- steht dafür nur eine Zeile.
    info.itemsCrestFaktor = 1.0 - ((1.0 - info.itemsFaktor) + (1.0 - info.crestFaktor))
    info.faktor = info.roleFaktor * info.prioFaktor * info.wunschFaktor * info.leistungFaktor
        * info.itemsCrestFaktor
    info.gewichtet = wert * info.faktor
    info.grund = #info.gruende > 0 and table.concat(info.gruende, " + ") or nil
    return info.gewichtet, info
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
-- Einstellungen (liegen in WowUtilsPlusDB.einstellungen)
-- ---------------------------------------------------------------------------

--- Einstellung lesen. Fehlt sie, gilt die Vorgabe.
function ns.Einstellung(name, vorgabe)
    local db = _G.WowUtilsPlusDB
    local wert = db and db.einstellungen and db.einstellungen[name]
    if wert == nil then return vorgabe end
    return wert
end

--- Einstellung setzen (schreibt in die eigenen SavedVariables).
function ns.EinstellungSetzen(name, wert)
    _G.WowUtilsPlusDB = _G.WowUtilsPlusDB or {}
    WowUtilsPlusDB.einstellungen = WowUtilsPlusDB.einstellungen or {}
    WowUtilsPlusDB.einstellungen[name] = wert
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
    print("  " .. blau("/wup set") .. "         Set-Spalte ein-/ausblenden")
    print("  " .. blau("/wup crests") .. "     Crests-Spalte ein-/ausblenden")
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
        print(("  %-8s %s  %s"):format(ns.RollenName(role), zustand, grau(w.reason or "")))
    end
    print(gelb("Prioritaetsliste"))
    print(("  %d Charaktere zugeordnet%s"):format(ns.PRIO_ANZAHL or 0,
        ns.PRIO_STAND and (" — Stand " .. ns.PRIO_STAND) or ""))
    print(grau("  1 = kein Abzug, 2 = -10 %, 3 = -20 %, 4 = -30 %, 5 = -40 %"))
    local eigen = UnitName("player")
    local prio = ns.PrioVon(eigen)
    print(("  Du (%s): %s"):format(tostring(eigen),
        prio and gruen(("Prio %d → %s"):format(prio, ns.Faktor(ns.PrioFaktor(prio)))) or rot("nicht auf der Liste")))
end

--- Die eigene Wunschliste mit rohen und gewichteten Gewinnen ausgeben.
local function test()
    local daten = WowUtilsAPI and WowUtilsAPI.GetDroptimizers("player")
    if not daten then
        print(rot("Keine eigenen Daten gefunden.") .. " Liegt die Bridge-Datei vor (/wup)?")
        return
    end

    -- Gewinne je Item aus allen Sims des Charakters einsammeln
    local eigenerName = UnitName("player")
    local jeItem = {}
    for specId, sims in pairs(daten.specs or {}) do
        local role = ns.RolleVonSpec(tonumber(specId))
        for _, sim in pairs(sims) do
            for itemId, ergebnisse in pairs(sim.items or {}) do
                for _, e in ipairs(ergebnisse) do
                    local istProzent = e.gain == nil
                    local basis = e.gain or e.gainPercent
                    if basis then
                        local gewichtet, info = ns.Gewichten(basis, role, eigenerName)
                        local alt = jeItem[itemId]
                        if not alt or math.abs(basis) > math.abs(alt.basis) then
                            jeItem[itemId] = {
                                basis = basis, istProzent = istProzent,
                                gewichtet = gewichtet, faktor = info.faktor,
                                grund = info.grund, role = role, ilvl = e.ilvl,
                                prio = info.prio, prioFaktor = info.prioFaktor,
                                roleFaktor = info.roleFaktor,
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
            local teile = {}
            if v.roleFaktor and v.roleFaktor ~= 1.0 then
                teile[#teile + 1] = ("%s %s"):format(ns.RollenName(v.role), ns.Faktor(v.roleFaktor))
            end
            if v.prio then
                teile[#teile + 1] = ("Prio %d %s"):format(v.prio, ns.Faktor(v.prioFaktor))
            end
            text = text .. "  " .. grau("→") .. " " .. gelb(gew) ..
                   "  " .. grau(("(%s)"):format(table.concat(teile, " + ")))
        end
        print(text)
        if v.grund and i <= 3 then
            print("      " .. grau(v.grund))
        end
    end
    print("  " .. grau("(max. 12 Eintraege, sortiert nach rohem Gewinn)"))
end

--- Set-Spalte ein- oder ausschalten: Einstellung merken und sofort umsetzen, wenn moeglich.
--- 🔴 Vorgabe ist AUS — der Befehl schaltet sie also beim ersten Mal EIN.
local function setSpalteUmschalten()
    local an = not ns.Einstellung("setSpalte", false)
    ns.EinstellungSetzen("setSpalte", an)

    local zusatz = ""
    if ns.SetSpalteLiveUmschalten then
        if not ns.SetSpalteLiveUmschalten(an) then
            zusatz = grau("  — Fenster noch nicht offen, gilt beim naechsten Oeffnen")
        end
    else
        zusatz = grau("  — RCLootCouncil ist nicht geladen, gilt beim naechsten Login")
    end
    print(gelb("WoWUtils Plus") .. "  Set-Spalte: " .. (an and gruen("an") or rot("aus")) .. zusatz)
end

--- Crests-Spalte ein- oder ausschalten: Einstellung merken und sofort umsetzen, wenn moeglich.
--- 🔴 Vorgabe ist AUS — der Befehl schaltet sie also beim ersten Mal EIN.
local function crestSpalteUmschalten()
    local an = not ns.Einstellung("crestSpalte", false)
    ns.EinstellungSetzen("crestSpalte", an)

    local zusatz = ""
    if ns.CrestSpalteLiveUmschalten then
        if not ns.CrestSpalteLiveUmschalten(an) then
            zusatz = grau("  — Fenster noch nicht offen, gilt beim naechsten Oeffnen")
        end
    else
        zusatz = grau("  — RCLootCouncil ist nicht geladen, gilt beim naechsten Login")
    end
    print(gelb("WoWUtils Plus") .. "  Crests-Spalte: " .. (an and gruen("an") or rot("aus")) .. zusatz)
end

SLASH_WOWUTILSPLUS1 = "/wup"
SlashCmdList["WOWUTILSPLUS"] = function(eingabe)
    local befehl = (eingabe or ""):lower():match("^%s*(%S*)")
    if befehl == "" or befehl == "help" then hilfe()
    elseif befehl == "test" then test()
    elseif befehl == "gewichte" then gewichte()
    elseif befehl == "set" then setSpalteUmschalten()
    elseif befehl == "crests" then crestSpalteUmschalten()
    elseif befehl == "rcl" and ns.DebugRCL then ns.DebugRCL()
    else datenlage()
    end
end

-- Beim Login einmal kurz melden, damit man sieht dass es geladen ist
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    print(gelb("WoWUtils Plus") .. grau(" geladen — /wup fuer Hilfe"))
end)