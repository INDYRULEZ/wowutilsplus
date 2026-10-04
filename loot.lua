--[[ WoWUtils Plus — die zwei Zusatz-Faktoren: Items heute und Crests.

Hier stehen NUR die Rechenkurven. Woher die Zahlen kommen, entscheidet die
Datenquelle (`ns.ItemsStand` / `ns.CrestStand`, gefuellt aus der RCL-Historie
und der WowUtils-Waehrung). Fehlt die Quelle, bleibt der Faktor neutral 1.00 —
es wird nie ein Ersatzwert geraten.

Die Stellschrauben kommen aus gewichte.lua (Weboberflaeche):
  ns.ITEMS_HEUTE_ABZUG — Abzug je Item, das der Spieler heute erhalten hat
  ns.ITEMS_UNTEN       — Untergrenze des Items-Faktors
  ns.CREST_MIN         — Faktor bei 0 Crests
  ns.CREST_SCHWELLE    — ab so vielen Crests ist der Faktor 1.00
]]

local addonName, ns = ...

-- Vorgabe, falls gewichte.lua fehlt oder aelter ist (dann steht dort nichts).
ns.ITEMS_HEUTE_ABZUG = ns.ITEMS_HEUTE_ABZUG or 0.15
ns.ITEMS_UNTEN       = ns.ITEMS_UNTEN or 0.70
ns.CREST_MIN         = ns.CREST_MIN or 0.80
ns.CREST_SCHWELLE    = ns.CREST_SCHWELLE or 80

--- Reine Kurve: Abzug je Item, das der Spieler **seit dem letzten Weekly-Reset**
--- erhalten hat. Der Faktor faellt nie unter ITEMS_UNTEN. Ohne (oder mit 0) Items neutral.
--- @param anzahl number? Anzahl Items seit dem Reset
--- @return number
function ns.ItemsFaktorKurve(anzahl)
    anzahl = tonumber(anzahl)
    if not anzahl or anzahl <= 0 then return 1.0 end
    local unter = tonumber(ns.ITEMS_UNTEN) or 0.70
    local abzug = tonumber(ns.ITEMS_HEUTE_ABZUG) or 0.15
    return math.max(unter, 1.0 - abzug * anzahl)
end

--- Reine Kurve: Crests. Eingang ist `hat + diese Woche noch frei`.
--- CREST_MIN bei 0, linear bis 1.00 ab CREST_SCHWELLE. Ohne Angabe neutral.
--- @param wert number?
--- @return number
function ns.CrestWertFaktor(wert)
    wert = tonumber(wert)
    if not wert then return 1.0 end
    local minimum = tonumber(ns.CREST_MIN) or 0.80
    local schwelle = tonumber(ns.CREST_SCHWELLE) or 80
    if schwelle <= 0 then return 1.0 end
    local anteil = wert / schwelle
    if anteil < 0 then anteil = 0 elseif anteil > 1 then anteil = 1 end
    return minimum + (1.0 - minimum) * anteil
end

--- Faktor + Zahlen fuer die Spalte „Items".
--- @param kandidat string?
--- @return number faktor, table? stand { gesamt = n, seitReset = n, seitResetListe = { … } }
function ns.ItemsFaktor(kandidat)
    local stand = ns.ItemsStand and ns.ItemsStand(kandidat)
    if type(stand) ~= "table" then return 1.0, nil end
    return ns.ItemsFaktorKurve(stand.seitReset), stand
end

--- Faktor + Zahlen fuer die Spalte „Crests". Eingang = hat + frei.
--- @param kandidat string?
--- @return number faktor, table? stand { hat, frei, stufen }
function ns.CrestFaktor(kandidat)
    local stand = ns.CrestStand and ns.CrestStand(kandidat)
    if type(stand) ~= "table" then return 1.0, nil end
    local wert = (tonumber(stand.hat) or 0) + (tonumber(stand.frei) or 0)
    return ns.CrestWertFaktor(wert), stand
end
