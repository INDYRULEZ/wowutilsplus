--[[ WoWUtils Plus — Tier-Set-Verteilung (Grundlage).

Was hier passiert:
  * **Token erkennen.** RCLootCouncil fuehrt eine globale Tabelle `RCTokenTable`
    (Token-Item-ID -> Ausruestungsslot, z.B. "HeadSlot"). Sie wird von RCL mit jedem
    Patch gepflegt — wir lesen sie nur, wir pflegen nichts.
  * **Wer hat schon einen Token bekommen.** Die RCL-Loot-Historie merkt sich je Vergabe
    `tierToken = true`. Aus dem Item wird der Slot.
  * **Vault.** Ueber `WowUtilsAPI.GetVault(Name-Realm)` liegen die Truhen der Gilde vor,
    je Eintrag mit Item und `picked` (abgeholt oder nicht).
  * **Merker.** WowUtils haelt die Truhe nur fuer die laufende Woche. Abgeholte Teile
    schreiben wir in unsere eigenen SavedVariables, damit die Info den Reset ueberlebt.

🔴 Es wird nichts geraten: was wir nicht wissen, bleibt leer.
]]

local addonName, ns = ...

-- ---------------------------------------------------------------------------
-- Die fuenf Tier-Slots
-- ---------------------------------------------------------------------------

--- Reihenfolge wie in der Spalte: H S C G L
ns.SET_SLOTS = {
    { key = "kopf",     brief = "H", name = "Kopf",     rcl = "HeadSlot" },
    { key = "schulter", brief = "S", name = "Schulter", rcl = "ShoulderSlot" },
    { key = "brust",   brief = "C", name = "Brust",    rcl = "ChestSlot" },
    { key = "haende",  brief = "G", name = "Hände",    rcl = "HandsSlot" },
    { key = "beine",   brief = "L", name = "Beine",    rcl = "LegsSlot" },
}

--- Ausruestungsslot-Nummer -> unser Slot-Schluessel.
--- 5 und 20 sind beides Brust (5 = Brust, 20 = Robe).
local INV_ZU_SLOT = {
    [1] = "kopf", [3] = "schulter", [5] = "brust", [20] = "brust",
    [7] = "beine", [10] = "haende",
}

local RCL_ZU_SLOT = {}
for _, s in ipairs(ns.SET_SLOTS) do RCL_ZU_SLOT[s.rcl] = s.key end

function ns.SlotName(key)
    for _, s in ipairs(ns.SET_SLOTS) do if s.key == key then return s.name end end
    return tostring(key)
end

-- ---------------------------------------------------------------------------
-- Token-Erkennung (ueber RCLs eigene Tabelle)
-- ---------------------------------------------------------------------------

--- Slot-Schluessel eines Tokens, oder nil wenn das Item kein Token ist.
--- @param itemId number?
--- @return string? slotKey
local function tokenSlot(itemId)
    if not itemId then return nil end
    local tabelle = _G.RCTokenTable
    if type(tabelle) ~= "table" then return nil end
    local rcl = tabelle[tonumber(itemId)]
    if not rcl then return nil end
    return RCL_ZU_SLOT[rcl]        -- nil bei "MultiSlots"/"Trinket"/alten Slots
end
ns.TokenSlot = tokenSlot

--- Ist das aktuelle Item im Fenster ein Tier-Token, und welcher Slot?
--- @return string? slotKey, number? itemId
function ns.TokenImFenster()
    local item = ns.ItemImFenster and ns.ItemImFenster()
    if not item then return nil end
    local itemId = item.itemID
    if not itemId and item.link and C_Item and C_Item.GetItemInfoInstant then
        itemId = C_Item.GetItemInfoInstant(item.link)
    end
    return tokenSlot(itemId), itemId
end

-- ---------------------------------------------------------------------------
-- Merker: abgeholte Vault-Teile ueber den Reset hinaus behalten
-- ---------------------------------------------------------------------------

local function merker()
    WowUtilsPlusDB = WowUtilsPlusDB or {}
    WowUtilsPlusDB.sets = WowUtilsPlusDB.sets or {}
    return WowUtilsPlusDB.sets
end

--- Einen abgeholten Vault-Eintrag dauerhaft notieren (nur wenn noch nicht da).
local function merken(schluessel, slot, s)
    if not (schluessel and slot and s and s.itemId) then return end
    local m = merker()
    m[schluessel] = m[schluessel] or {}
    if m[schluessel][slot] and m[schluessel][slot].itemId == s.itemId then return end
    m[schluessel][slot] = {
        itemId = s.itemId,
        link = s.itemLink,
        name = s.itemLink and s.itemLink:match("%[(.-)%]") or nil,
        stufe = s.itemLevel,
        seit = (s.picked and time()) or nil,
    }
end

-- ---------------------------------------------------------------------------
-- Vault
-- ---------------------------------------------------------------------------

--- Der Stand der Truhe eines Kandidaten, je Tier-Slot.
--- @param kandidat string "Name-Realm"
--- @return table? { [slotKey] = { itemId, link, name, stufe, abgeholt } }
function ns.VaultStand(kandidat)
    if not (WowUtilsAPI and WowUtilsAPI.GetVault and kandidat) then return nil end
    local ok, vault = pcall(WowUtilsAPI.GetVault, kandidat)
    if not ok or type(vault) ~= "table" then return nil end
    local stand, gefunden = {}, false
    for _, e in pairs(vault) do
        local slot = INV_ZU_SLOT[tonumber(e.itemLocationId) or -1]
        if slot and e.itemId and tonumber(e.itemId) > 2 then
            gefunden = true
            stand[slot] = {
                itemId = e.itemId,
                link = e.itemLink,
                name = e.itemLink and e.itemLink:match("%[(.-)%]") or nil,
                stufe = e.itemLevel,
                abgeholt = e.picked and true or false,
            }
            if e.picked then merken(kandidat, slot, e) end
        end
    end
    return gefunden and stand or nil
end

--- Was wir aus der Truhe dauerhaft mitgeschrieben haben (auch alte Wochen).
--- @return table { [slotKey] = { itemId, name, stufe, seit } }
function ns.VaultMerker(kandidat)
    local m = merker()
    return m[kandidat]
end

-- ---------------------------------------------------------------------------
-- Token aus der RCL-Loot-Historie
-- ---------------------------------------------------------------------------

--- Alle Tier-Token, die ein Kandidat laut Historie bekommen hat.
--- @param kandidat string "Name-Realm"
--- @return table? { [slotKey] = { name, datum, link } }
function ns.TokenAusHistorie(kandidat)
    local RCL = ns.RCL
    if not (RCL and RCL.GetHistoryDB) or not kandidat then return nil end
    local ok, db = pcall(RCL.GetHistoryDB, RCL)
    if not ok or type(db) ~= "table" then return nil end
    local liste = db[kandidat]
    if type(liste) ~= "table" then return nil end
    local stand, gefunden = {}, false
    for _, e in ipairs(liste) do
        -- 🔴 Nicht auf RCLs Merker `tierToken` allein verlassen: aeltere Eintraege (oder von
        -- einem Client mit aelterer RCL-Fassung uebernommen) haben ihn nicht. Das Item selbst
        -- gegen RCTokenTable zu pruefen ist die verlaesslichere Quelle.
        if e.lootWon then
            local itemId = C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(e.lootWon)
            local slot = tokenSlot(itemId)
            if slot then
                gefunden = true
                -- der neueste Eintrag gewinnt (Historie ist chronologisch)
                stand[slot] = {
                    name = e.lootWon:match("%[(.-)%]"),
                    datum = e.date,
                    link = e.lootWon,
                }
            end
        end
    end
    return gefunden and stand or nil
end

-- ---------------------------------------------------------------------------
-- Tier-Erkennung: gehoert ein Item zu einem Klassen-Tier-Set?
--
-- 🔴 Der Weg wurde im Spiel gemessen (04.10.2026), nicht geraten:
--     C_Item.GetSetBonusesForSpecializationByItemID(specID, itemID)
--     — Argument-Reihenfolge ist specID ZUERST.
--     Gemessen an einem Evoker-Tier-Teil: Treffer bei genau den drei Evoker-Specs.
--     An einem DK-Tier-Teil: Treffer bei genau der einen DK-Spec.
--     An einem klassenlosen Set („Bite of Zul'jan"): Treffer bei ALLEN Specs.
-- ---------------------------------------------------------------------------

--- Alle Spezialisierungen aller Klassen — aus dem Spiel, nicht fest verdrahtet.
local function alleSpez()
    local liste = {}
    if not (GetNumSpecializationsForClassID and GetSpecializationInfoForClassID) then
        return liste
    end
    for klasse = 1, 13 do
        local anzahl = GetNumSpecializationsForClassID(klasse) or 0
        for i = 1, anzahl do
            local id = GetSpecializationInfoForClassID(klasse, i)
            if id then liste[#liste + 1] = id end
        end
    end
    return liste
end

local function specListe()
    if not ns.specCache then ns.specCache = alleSpez() end
    return ns.specCache
end

ns.tierCache = {}

--- Ist das Item ein Tier-Teil?  nil = nicht feststellbar.
--- Zwei Bedingungen: es MUSS Set-Boni geben, und es darf NICHT fuer alle Specs welche
--- geben — sonst ist es ein klassenloses Set.
function ns.IstTierTeil(itemId)
    itemId = tonumber(itemId)
    if not itemId or not (C_Item and C_Item.GetSetBonusesForSpecializationByItemID) then
        return nil
    end
    local gemerkt = ns.tierCache[itemId]
    if gemerkt ~= nil then return gemerkt end

    local liste = specListe()
    if #liste == 0 then return nil end

    local treffer = 0
    for _, spec in ipairs(liste) do
        -- 🔴 Nicht `select("#", …)` zaehlen: liefert die Funktion ein einzelnes `nil`,
        -- zaehlt das als 1 Rueckgabe und waere ein falscher Treffer. Den Wert selbst pruefen.
        local ok, bonis = pcall(C_Item.GetSetBonusesForSpecializationByItemID, spec, itemId)
        if ok and bonis ~= nil then
            treffer = treffer + 1
            if treffer >= #liste then break end
        end
    end

    local ist = (treffer > 0 and treffer < #liste)
    ns.tierCache[itemId] = ist
    return ist
end

-- ---------------------------------------------------------------------------
-- Angezogene Tier-Teile
-- ---------------------------------------------------------------------------

--- Ausruestungsslots im Spiel. Bestaetigt per GetInventorySlotInfo (04.10.2026).
local UNIT_SLOTS = { kopf = 1, schulter = 3, brust = 5, haende = 10, beine = 7 }

--- Unit-Kennung zu einem Kandidatennamen ("Name-Realm") finden.
function ns.UnitFuerName(name)
    if not name then return nil end
    local kurz = name:match("^([^%-]+)") or name
    if UnitName and UnitName("player") == kurz then return "player" end
    if IsInRaid and IsInRaid() and GetNumGroupMembers then
        for i = 1, GetNumGroupMembers() do
            local u = "raid" .. i
            if UnitName(u) == kurz then return u end
        end
    elseif IsInGroup and IsInGroup() and GetNumGroupMembers then
        for i = 1, GetNumGroupMembers() - 1 do
            local u = "party" .. i
            if UnitName(u) == kurz then return u end
        end
    end
    return nil
end

--- Angezogene Tier-Teile eines Kandidaten. nil = nichts gefunden (oder nicht pruefbar).
--- 🔴 Funktioniert nur fuer Leute in der Gruppe/im Raid — ausserhalb steht nichts da,
--- statt etwas Falsches.
function ns.Angezogen(kandidat)
    local unit = ns.UnitFuerName(kandidat)
    if not unit or not GetInventoryItemLink then return nil end
    local stand, gefunden = {}, false
    for _, s in ipairs(ns.SET_SLOTS) do
        local link = GetInventoryItemLink(unit, UNIT_SLOTS[s.key])
        if link then
            local itemId = C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(link)
            if ns.IstTierTeil(itemId) then
                gefunden = true
                stand[s.key] = { zustand = "angezogen", itemId = itemId, link = link,
                                 name = link:match("%[(.-)%]") }
            end
        end
    end
    return gefunden and stand or nil
end

-- ---------------------------------------------------------------------------
-- Zusammenfassung fuer die Spalte
-- ---------------------------------------------------------------------------

--- Was wissen wir zu den fuenf Slots eines Kandidaten?
--- @param kandidat string "Name-Realm"
--- @return table { [slotKey] = { zustand = "token"|"vault"|"merker", … } }, number anzahl
function ns.SetStand(kandidat)
    local stand, anzahl = {}, 0

    -- Angezogen hat Vorrang: was er traegt, weiss er sicher.
    local angezogen = ns.Angezogen(kandidat)
    if angezogen then
        for slot, d in pairs(angezogen) do stand[slot] = d end
    end

    local token = ns.TokenAusHistorie(kandidat)
    if token then
        for slot, d in pairs(token) do
            if not stand[slot] then
                stand[slot] = { zustand = "token", name = d.name, datum = d.datum, link = d.link }
            end
        end
    end
    local vault = ns.VaultStand(kandidat)
    if vault then
        for slot, d in pairs(vault) do
            if not stand[slot] then
                stand[slot] = { zustand = d.abgeholt and "vault" or "vault-offen",
                                name = d.name, link = d.link, stufe = d.stufe }
            end
        end
    end
    local gemerkt = ns.VaultMerker(kandidat)
    if gemerkt then
        for slot, d in pairs(gemerkt) do
            stand[slot] = stand[slot] or { zustand = "vault", name = d.name, link = d.link,
                                           stufe = d.stufe }
        end
    end
    for _ in pairs(stand) do anzahl = anzahl + 1 end
    return stand, anzahl
end