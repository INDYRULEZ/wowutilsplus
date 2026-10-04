--[[ WoWUtils Plus — woher die Zahlen fuer die Spalten „Items" und „Crests" kommen.

Items:  RCLootCouncil fuehrt die Loot-Historie selbst (`RCL:GetHistoryDB()`), je Spieler
        eine Liste mit `date` (YYYY/MM/DD), `time` und `lootWon`. Es zaehlt nur der
        **Kalendertag** (Serverzeit) — nicht „seit dem Reset" und nicht „seit Raidbeginn".
Crests: WowUtils teilt die Waehrungen der Gilde (`WowUtilsAPI.GetCurrency`). Die
        **Obergrenze** steht nur im eigenen Spiel (`C_CurrencyInfo`) und gilt fuer alle gleich.

🔴 Der Aufruf braucht **`Name-Realm`** — ein nackter Name liefert nichts, solange der
Spieler nicht in der eigenen Gruppe steht. Genau diese Form liefert RCL als Kandidatenname.

🔴 Es wird nichts geraten: fehlt eine Quelle, bleibt der Faktor neutral (siehe loot.lua)
und die Spalte zeigt `---`.
]]

local addonName, ns = ...

--- Die vier Creststufen. Nur die hoechste (3446) wirkt als Faktor.
ns.CRESTSTUFEN = {
    { id = 3443, name = "Veteran" },
    { id = 3444, name = "Champion" },
    { id = 3445, name = "Hero" },
    { id = 3446, name = "Mythic" },
}

-- Kurzzeitiger Merker: eine Tabellenzeile wird mehrfach gezeichnet (drei Spalten),
-- jede Zeichnung darf die Historie nicht erneut durchlaufen.
local function kurzMerken(schluessel, funktion, kandidat)
    ns._merker = ns._merker or {}
    local k = schluessel .. "|" .. tostring(kandidat)
    local jetzt = GetTime and GetTime() or 0
    local alt = ns._merker[k]
    if alt and (jetzt - alt.zeit) < 2 then return alt.wert end
    local wert = funktion(kandidat)
    ns._merker[k] = { zeit = jetzt, wert = wert }
    return wert
end

-- ---------------------------------------------------------------------------
-- Items (RCLootCouncil-Historie)
-- ---------------------------------------------------------------------------

--- Die Vergabe-Liste eines Kandidaten. nil, wenn nichts vorliegt.
local function historie(kandidat)
    local RCL = ns.RCL
    if not (RCL and RCL.GetHistoryDB) or not kandidat then return nil end
    local ok, db = pcall(RCL.GetHistoryDB, RCL)
    if not ok or type(db) ~= "table" then return nil end
    local liste = db[kandidat]
    if type(liste) ~= "table" and ns.Normalisiere then
        -- Notnagel: ueber den normalisierten Namen suchen (Gross/Klein, Akzente, Realm).
        local gesucht = ns.Normalisiere(kandidat)
        for name, l in pairs(db) do
            if ns.Normalisiere(name) == gesucht then
                liste = l
                break
            end
        end
    end
    if type(liste) ~= "table" then return nil end
    return liste
end

local function itemsStandRoh(kandidat)
    local liste = historie(kandidat)
    if not liste then return nil end
    local heute = date("%Y/%m/%d")
    local gesamt, anzahl, links = 0, 0, {}
    for _, e in ipairs(liste) do
        gesamt = gesamt + 1
        if tostring(e.date) == heute then
            anzahl = anzahl + 1
            if e.lootWon then links[#links + 1] = e.lootWon end
        end
    end
    return { gesamt = gesamt, heute = anzahl, heuteListe = links }
end

--- Items insgesamt und heute (Kalendertag) fuer einen Kandidaten.
--- @param kandidat string "Name-Realm"
--- @return table? { gesamt = n, heute = n, heuteListe = { links } }
function ns.ItemsStand(kandidat)
    return kurzMerken("items", itemsStandRoh, kandidat)
end

-- ---------------------------------------------------------------------------
-- Crests (WowUtils-Waehrung + eigene Obergrenze)
-- ---------------------------------------------------------------------------

local function grenzenRoh()
    if ns._crestGrenzen then return ns._crestGrenzen end
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
    local grenzen, gefunden = {}, false
    for _, stufe in ipairs(ns.CRESTSTUFEN) do
        local ok, ci = pcall(C_CurrencyInfo.GetCurrencyInfo, stufe.id)
        if ok and type(ci) == "table" and tonumber(ci.maxQuantity) then
            grenzen[stufe.id] = tonumber(ci.maxQuantity)
            if grenzen[stufe.id] > 0 then gefunden = true end
        end
    end
    if not gefunden then return nil end
    ns._crestGrenzen = grenzen
    return grenzen
end

--- Obergrenze je Creststufe, gelesen vom EIGENEN Charakter (gilt fuer die ganze Season).
--- @return table? { [id] = grenze }
function ns.CrestGrenzen()
    return grenzenRoh()
end

local function crestStandRoh(kandidat)
    if not (WowUtilsAPI and WowUtilsAPI.GetCurrency) or not kandidat then return nil end
    local ok, w = pcall(WowUtilsAPI.GetCurrency, kandidat)
    if (not ok or type(w) ~= "table") and type(kandidat) == "string" then
        -- Zweiter Versuch ohne Realm: greift, wenn der Spieler in der eigenen Gruppe steht.
        local name = kandidat:match("^([^%-]+)")
        if name and name ~= kandidat then ok, w = pcall(WowUtilsAPI.GetCurrency, name) end
    end
    if not ok or type(w) ~= "table" then return nil end
    local grenzen = ns.CrestGrenzen()
    local stufen, mythic = {}, nil
    for _, stufe in ipairs(ns.CRESTSTUFEN) do
        local e = w[stufe.id]
        if type(e) == "table" then
            local hat = tonumber(e.current) or 0
            local verdient = tonumber(e.totalEarned) or 0
            local grenze = grenzen and grenzen[stufe.id] or nil
            local frei = grenze and math.max(0, grenze - verdient) or nil
            local s = { id = stufe.id, name = stufe.name, hat = hat, verdient = verdient,
                        grenze = grenze, frei = frei }
            stufen[#stufen + 1] = s
            if stufe.id == 3446 then mythic = s end
        end
    end
    if not mythic then return nil end
    return { hat = mythic.hat, frei = mythic.frei, mythic = mythic, stufen = stufen }
end

--- Crest-Zahlen eines Kandidaten. Faktor-Stufe ist Mythic (3446), Eingang = hat + frei.
--- @param kandidat string "Name-Realm"
--- @return table? { hat, frei, mythic, stufen = { {id, name, hat, verdient, grenze, frei}, … } }
function ns.CrestStand(kandidat)
    return kurzMerken("crests", crestStandRoh, kandidat)
end