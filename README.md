# WoWUtils Plus

Eigenes Zusatz-Addon für WoW, das auf den Daten von **WowUtils** aufsetzt und
eigene Zahlen draufrechnet. Ziel: eigene Gewichtungen (Tank/Heiler/…) mit
Begründung, ohne das Original-Addon zu verändern.

## Warum ein eigenes Addon statt eines Forks?

Das Original (`github.com/wowutils/addon`, GPL-3.0) wird weiterentwickelt. Wenn
wir dessen Code patchen, gibt es bei jedem Update Konflikte. Stattdessen:

- Original bleibt unverändert (Updates laufen normal weiter)
- Wir lesen die Daten über die **offizielle Schnittstelle** des Originals:
  das Global `WowUtilsAPI` (siehe `publicAPI.lua` im Original)
  - `WowUtilsAPI.GetDroptimizers(unit)` → Sim-Ergebnisse
  - `WowUtilsAPI.GetWishlist(unit)` → Wunschliste mit Prioritäts-Label
  - `WowUtilsAPI.GetCharacterData(unit)` → Stammdaten
- Unser Addon hat einen eigenen Namen (`wowutilsplus`) — deshalb kann der
  Addon-Manager (WowUp) das Original aktualisieren, ohne uns zu überschreiben.

## Datenlage (aus der Bridge-Datei, geprüft am 01.10.2026)

Die Bridge schreibt alles nach
`…/Interface/AddOns/wowutils_data/data.lua` (35 Charaktere, 650 KB).

Zwei Sim-Quellen mit **unterschiedlichen Feldern**:

| Quelle | Feld | Inhalt |
|---|---|---|
| Raidbots | `gain` | absoluter Gewinn (z. B. `+1970`) |
| QE Live | `gainPercent` | **nur Prozentwert** |

Das ist der Grund, warum manche Leute (z. B. Heiler mit QE-Live-Sims) nur
Prozentwerte zeigen: Es ist eine Frage der **Sim-Quelle**, nicht der Rolle.

Weitere Felder je Sim-Ergebnis: `equipmentSlot`, `ilvl`, `difficultyId`,
`encounterId`, `sourceItem` (Tier-Token/Catalyst). Je Sim: `specId`,
`simType`, `simmedAt`, `baseline` (nur Raidbots).

Wunschliste je Charakter: `priority` (Anzeigelabel) + `priorityId` (1–5):
`1 = Best in Slot`, `2 = Upgrade`, `3 = Offspec`, `4 = Transmog`, `5 = Do not want`.

## Rollen-Erkennung

Das Original liefert **Klasse** und **specId** — aber keine Rolle.
Die Rolle holen wir direkt aus dem Spiel:

```lua
local role = select(5, GetSpecializationInfoByID(specId))  -- TANK / HEALER / DAMAGER
```

## Gewichtungen

Aktuell **ein** aktiver Faktor (Testphase), Tabelle in `core.lua`:

```lua
ns.WEIGHTS = {
    HEALER  = { factor = 0.5,  reason = "Heilung bringt weniger direkten Kill-Beitrag als Schaden" },
    TANK    = { factor = 1.0,  reason = "noch nicht aktiv" },
    DAMAGER = { factor = 1.0,  reason = "unveraendert" },
}
```

Weitere Faktoren (Jonas hat 4–5 im Kopf) kommen als zusätzliche Einträge dazu.
Jede Reduzierung wird im Text **mit Begründung** angezeigt.

## Testen

```bash
./deploy.sh          # kopiert nach …/Interface/AddOns/wowutilsplus
```

Im Spiel: `/reload`, dann

- `/wup` → Datenlage (wie viele Charaktere haben Sim-Daten)
- `/wup gewichte` → aktive Gewichtungen
- `/wup test` → eigene Wunschliste: roher Gewinn → gewichteter Gewinn + Grund

## Syntax prüfen (ohne Spiel)

WoW nutzt Lua 5.1. Prüfer liegt in `/tmp/luacheck-dir`:

```bash
cd /tmp/luacheck-dir && node check.js /home/heimlaptop/dev/wowutilsplus/core.lua
```

## Nächste Schritte

1. Test im Spiel (`/wup test`) — kommt die Gewichtung sichtbar an?
2. Weitere Faktoren ergänzen
3. Anzeige in den Tooltip / das Loot-Council-Fenster des Originals hängen
   (statt Chat-Ausgabe)
4. Erst dann: eigenes GitHub-Repo (Fork braucht gültiges Token — das in `.env` ist abgelaufen)