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

## Aktueller Stand

<!-- STAND:ANFANG -->

## Aktueller Stand

*Automatisch erzeugt — Stand: 02.10.2026 11:18*

**Einstellungen:** Zeitfenster 4 Wochen · Abzug bei 0er Log 10 % · Abzug am letzten Erst-Kill-Platz 15 % · Movement höchstens 20 %

**Quelle:** mythischen Kills der eigenen Gilde aus Warcraft Logs (Average log: alle Kills im Zeitfenster, First kill log: die Erst-Kills je Boss).

| Spieler | Rolle | Average log | First kill | Movement | Skill-Abzug |
|---|---|---|---|---|---|
| Balren (Paldros) | DPS | 31,0 % (11 Kills) → 0,93 | Platz 11/24 → 0,93 | – | 0,87 → −13,0 % |
| Beaybewhy | DPS | 0,0 % (1 Kills) → 0,90 | – | – | 0,90 → −10,0 % |
| Bigboysushi | DPS | – | Platz 13/24 → 0,92 | – | 0,92 → −8,0 % |
| Blitzfaust | DPS | 42,0 % (5 Kills) → 0,94 | Platz 9/24 → 0,95 | – | 0,89 → −11,0 % |
| Cep | DPS | 29,5 % (8 Kills) → 0,93 | Platz 7/24 → 0,96 | – | 0,89 → −11,0 % |
| Cheliia | DPS | 37,0 % (9 Kills) → 0,94 | Platz 10/24 → 0,94 | – | 0,88 → −12,0 % |
| Dránash | Tank | 40,0 % (11 Kills) → 0,94 | Platz 21/24 → 0,87 | – | 0,81 → −19,0 % |
| Enshirou | DPS | 22,0 % (9 Kills) → 0,92 | Platz 14/24 → 0,92 | – | 0,84 → −16,0 % |
| Exorzist (cheetah) | Heiler | 53,0 % (11 Kills) → 0,95 | Platz 12/24 → 0,93 | – | 0,88 → −12,0 % |
| Exudes | DPS | 22,0 % (4 Kills) → 0,92 | Platz 3/24 → 0,99 | – | 0,90 → −10,0 % |
| Garshû | DPS | 20,0 % (11 Kills) → 0,92 | Platz 17/24 → 0,90 | – | 0,82 → −18,0 % |
| Gwêni (Snowi) | DPS | 23,0 % (11 Kills) → 0,92 | Platz 8/24 → 0,95 | – | 0,88 → −12,0 % |
| Hyperhardw (Pasipháë) | DPS | 42,0 % (9 Kills) → 0,94 | Platz 15/24 → 0,91 | – | 0,85 → −15,0 % |
| Indydrakes | DPS | 10,0 % (10 Kills) → 0,91 | Platz 20/24 → 0,88 | – | 0,79 → −21,0 % |
| Jekyl (Rone) | DPS | 1,0 % (1 Kills) → 0,90 | Platz 22/24 → 0,86 | – | 0,77 → −23,0 % |
| Merlón | DPS | 52,0 % (11 Kills) → 0,95 | Platz 6/24 → 0,97 | – | 0,92 → −8,0 % |
| Neyzxd (Neyz) | DPS | 68,0 % (1 Kills) → 0,97 | – | – | 0,96 → −4,0 % |
| Notam | DPS | 21,0 % (11 Kills) → 0,92 | Platz 18/24 → 0,89 | – | 0,81 → −19,0 % |
| Ophrys (Juxe) | Heiler | 45,0 % (11 Kills) → 0,94 | Platz 18/24 → 0,89 | – | 0,84 → −16,0 % |
| Palacetamol | Heiler | 95,0 % (1 Kills) → 0,99 | Platz 14/1 → 0,85 | – | 0,84 → −16,0 % |
| Schmeckies | DPS | 40,0 % (1 Kills) → 0,94 | – | – | 0,94 → −6,0 % |
| Setupx (setup) | Tank | 91,0 % (11 Kills) → 0,99 | Platz 1/24 → 1,00 | – | 0,99 → −1,0 % |
| Sikkz | DPS | 61,0 % (11 Kills) → 0,96 | Platz 5/24 → 0,97 | – | 0,93 → −7,0 % |
| Silanhunt (Silan) | DPS | 6,0 % (10 Kills) → 0,91 | Platz 12/24 → 0,93 | – | 0,84 → −16,0 % |
| Thunderdebbo | Heiler | 17,5 % (10 Kills) → 0,92 | Platz 14/24 → 0,92 | – | 0,83 → −17,0 % |
| Tobii (Luc) | Heiler | 99,0 % (9 Kills) → 1,00 | Platz 1/24 → 1,00 | – | 0,99 → −1,0 % |
| Twosocks (Sushi) | DPS | 23,0 % (3 Kills) → 0,92 | Platz 4/24 → 0,98 | – | 0,90 → −10,0 % |
| Vilarie | DPS | 28,0 % (3 Kills) → 0,93 | Platz 19/24 → 0,88 | – | 0,81 → −19,0 % |

<!-- STAND:ENDE -->

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
