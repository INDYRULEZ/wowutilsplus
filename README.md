# WoWUtils Plus

Ein Zusatz-Addon für **World of Warcraft**, das im Abstimmungsfenster von
**RCLootCouncil** eine eigene Spalte mit einem **gewichteten** Sim-Gewinn anzeigt.
Es setzt auf den Daten von [WowUtils](https://wowutils.com) auf und lässt das
Original-Addon unangetastet.

## Was es macht

- **Spalte „Gewichtet"** rechts neben der WowUtils-Spalte im Loot-Council-Fenster
- Angezeigt wird der Sim-Gewinn des Kandidaten für **genau das Item, über das gerade
  abgestimmt wird** — mit derselben Auswahl wie das Original: Schwierigkeit des
  gedroppten Items, bevorzugt der 1-Ziel-Patchwerk-Sim
- Darauf werden eigene Faktoren angewendet:
  - **Rolle:** DPS ×1,00 · Healer ×0,52 · Tank ×1,15
  - **Prioritätsliste:** 1 = kein Abzug · 2 = −10 % · 3 = −20 % · 4 = −30 % · 5 = −40 %
  - **Wunschliste:** Best in Slot ×1,00 · Upgrade ×0,60 (greift nur, wenn jemand das Item
    als BiS bzw. Upgrade führt; andere Wunschlisten-Werte verändern nichts)
- **Sortierbar:** Klick auf die Spaltenüberschrift sortiert numerisch nach dem
  gewichteten Wert (nicht nach dem angezeigten Text)
- **Tooltip** an der Zelle: Rohwert, gewichteter Wert und die angewendeten Faktoren,
  benutzter Sim und Item-Stufe
- Ohne passenden Sim-Eintrag steht `---` — es wird nie geraten

## Voraussetzungen

- `wowutils` und `wowutils_data` (die Daten liefert die WowUtils-Bridge)
- `RCLootCouncil`

Es wird **nichts** am Original-Addon geändert: alle Daten kommen über dessen
öffentliche Schnittstelle `WowUtilsAPI`.

## Installation

1. ZIP aus den [Releases](../../releases) herunterladen
2. Den Ordner `wowutilsplus` nach
   `World of Warcraft/_retail_/Interface/AddOns/` legen
3. Das Spiel neu starten

## Befehle

| Befehl | Wirkung |
|---|---|
| `/wup` | Datenlage — wie viele Charaktere haben Sim-Daten |
| `/wup gewichte` | aktive Gewichtungen und Stand der Prioritätsliste |
| `/wup test` | eigene Wunschliste: roher Gewinn → gewichteter Gewinn + Begründung |
| `/wup rcl` | Diagnose zum Item, das gerade im Abstimmungsfenster steht |

## Prioritätsliste

`prioliste.lua` ordnet jedem Charakter eine Zahl von 1 bis 5 zu und wird mit jeder
Version mitgeliefert. Die Zuordnung ist unabhängig von Groß-/Kleinschreibung und
Schreibweise (Akzente werden ignoriert), damit Namen aus einer externen Liste zu den
Charakteren im Spiel passen. Gilt für den Main **und** die Nebencharaktere einer Person.

## Aufbau

| Datei | Inhalt |
|---|---|
| `core.lua` | Gewichtungen, Rollen-Erkennung, Befehle |
| `rclc.lua` | Spalte im RCLootCouncil-Fenster (offizielle Spalten-API) |
| `prioliste.lua` | Prioritätsliste je Charakter |
| `wowutilsplus.toc` | Addon-Manifest |

## Danksagung

Baut auf den Daten von [WowUtils](https://wowutils.com) und dem Addon
**RCLootCouncil** auf.