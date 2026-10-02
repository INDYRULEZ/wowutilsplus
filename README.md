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
- **Tooltip an der Zelle** zeigt, wie die Zahl zustande kommt — als kleine Tabelle,
  links der Wert, rechts der Faktor:

  ```
  Gewichtet      +1.034,50
     Rolle          DPS             x1,00
     Prio           3               x0,80
     Wunschliste    Best in Slot    x1,00
     Average log    43,00 %         x0,94
     First kill     Platz 10/24     x0,94
     Movement       -20,00 %        x0,80
  ```

- **Sortierbar:** Klick auf die Spaltenüberschrift sortiert numerisch nach dem
  gewichteten Wert (nicht nach dem angezeigten Text)
- Ohne passenden Sim-Eintrag steht `---` — es wird nie geraten

## Die Gewichtung

Die Faktoren werden multipliziert:

**Rolle × Prioritätsliste × Wunschliste × Average log × First kill log × Movement/Survival**

| Faktor | Wirkung |
|---|---|
| **Rolle** | DPS ×1,00 · Healer ×0,52 · Tank ×1,15 |
| **Prioritätsliste** | 1 = kein Abzug · 2 = −10 % · 3 = −20 % · 4 = −30 % · 5 = −40 % |
| **Wunschliste** | Best in Slot ×1,00 · Upgrade ×0,60 (greift nur, wenn jemand das Item als BiS bzw. Upgrade führt) |
| **Average log** | 100er Log = kein Abzug · 0er Log = −10 %, dazwischen linear |
| **First kill log** | Platz 1 = kein Abzug · letzter Platz = −15 %, dazwischen linear |
| **Movement/Survival** | von Hand gepflegt, Abzug in Prozent (Vorgabe: höchstens 20 %) |

Die Leistungswerte (Average log, First kill log) kommen aus **Warcraft Logs** und werden
je Charakter berechnet — gefiltert auf **Kills der eigenen Gilde**, auf die **letzten vier
Wochen** und **nur auf mythische Kills**. Normal- und heroische Kills sind andere
Bedingungen (kürzere Kämpfe, weniger Mechaniken, andere Ausrüstung) und wären kein
sauberer Maßstab.

- **Average log:** Median der Parse-Prozente über alle mythischen Kills im Zeitfenster.
- **First kill log:** die mythischen **Erst-Kills** je Boss. Der Wert wird auf 100 %
  Aktivzeit hochgerechnet, und für jede fehlende 5 % Aktivzeit sinkt er um 1 % (bezogen
  auf den ursprünglichen Wert). Verglichen wird mit dem besten Wert **derselben Rolle** im
  selben Kampf — **Heiler werden an der Heilung gemessen, nicht am Schaden**. Daraus
  ergibt sich die Rangfolge.

Die Zahlen je Charakter stehen in `gewichte.lua` und werden mit jeder Version
mitgeliefert. Sie werden außerhalb des Spiels gepflegt und berechnet.

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

Wer [WowUp](https://wowup.io) nutzt, kann das Repository dort als Quelle eintragen und
bekommt Updates automatisch.

## Befehle

| Befehl | Wirkung |
|---|---|
| `/wup` | Datenlage — wie viele Charaktere haben Sim-Daten |
| `/wup gewichte` | aktive Gewichtungen und Stand der Prioritätsliste |
| `/wup test` | eigene Wunschliste: roher Gewinn → gewichteter Gewinn + Begründung |
| `/wup rcl` | Diagnose zum Item, das gerade im Abstimmungsfenster steht |

## Aufbau

| Datei | Inhalt |
|---|---|
| `core.lua` | Gewichtungen, Rollen-Erkennung, Befehle |
| `rclc.lua` | Spalte im RCLootCouncil-Fenster (offizielle Spalten-API) |
| `prioliste.lua` | Prioritätsliste je Charakter (1–5) |
| `gewichte.lua` | Rollen-, Wunschlisten- und Leistungsfaktoren |
| `wowutilsplus.toc` | Addon-Manifest |

Die Prioritätsliste ordnet jedem Charakter eine Zahl von 1 bis 5 zu. Die Zuordnung ist
unabhängig von Groß-/Kleinschreibung und Schreibweise (Akzente werden ignoriert), damit
Namen aus einer externen Liste zu den Charakteren im Spiel passen. Sie gilt für den Main
**und** die Nebencharaktere einer Person.

Dasselbe gilt für die Leistungswerte: Sie wirken über den Charakternamen, also auch dann,
wenn jemand auf einem Nebencharakter im Raid steht.

## Danksagung

Baut auf den Daten von [WowUtils](https://wowutils.com) und dem Addon
**RCLootCouncil** auf.
