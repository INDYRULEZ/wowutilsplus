# WoWUtils Plus

Ein Zusatz-Addon für **World of Warcraft**, das im Abstimmungsfenster von
**RCLootCouncil** drei eigene Spalten anzeigt: den **gewichteten** Sim-Gewinn,
die erhaltenen **Items** und die **Crests**.
Es setzt auf den Daten von [WowUtils](https://wowutils.com) auf und lässt das
Original-Addon unangetastet.

## Was es macht

- **Spalte „Gewichtet"** rechts neben der WowUtils-Spalte im Loot-Council-Fenster
- Angezeigt wird der Sim-Gewinn des Kandidaten für **genau das Item, über das gerade
  abgestimmt wird** — mit derselben Auswahl wie das Original: Schwierigkeit des
  gedroppten Items, bevorzugt der 1-Ziel-Patchwerk-Sim
- **Tooltip an der Zelle** zeigt, wie die Zahl zustande kommt — Grundwert oben, darunter
  Schritt für Schritt links der Faktor und rechts der Betrag, der in diesem Schritt
  weggeht, unten das Ergebnis:

  ```
  Grundwert aus WowUtils             +510,00
  x1,00  Rolle: DPS                   +0,00
  x0,90  Prio: 2                     -51,00
  x1,00  Wunschliste: Best in Slot    +0,00
  x0,94  Average log: 42,50 %        -27,54
  x0,95  First kill: Platz 8/22      -21,57
  x0,92  Movement: -8,00 %           -32,79
  Gewichtet                          +377,10
  ```

  Die Beträge laufen mit und summieren sich genau zum Ergebnis.

- **Sortierbar:** Klick auf die Spaltenüberschrift sortiert numerisch nach dem
  gewichteten Wert (nicht nach dem angezeigten Text)
- **Zwei weitere Spalten:** **„Items"** (insgesamt · seit Reset) und **„Crests"** (Mythic: in der
  Tasche + frei). Der Tooltip der Items-Spalte listet die seit dem Wochen-Reset erhaltenen
  Teile, der der Crest-Spalte die Stufen **Hero und Mythic**
- Ohne passenden Sim-Eintrag steht `---` — es wird nie geraten

## Die Gewichtung

Die Faktoren werden multipliziert:

**Rolle × Prioritätsliste × Wunschliste × Average log × First kill log × Movement/Survival × Items seit Reset × Crests**

| Faktor | Wirkung |
|---|---|
| **Rolle** | DPS ×1,00 · Healer ×0,52 · Tank ×1,15 |
| **Prioritätsliste** | 1 = kein Abzug · 2 = −10 % · 3 = −20 % · 4 = −30 % · 5 = −40 % |
| **Wunschliste** | Best in Slot ×1,00 · Upgrade ×0,60 (greift nur, wenn jemand das Item als BiS bzw. Upgrade führt) |
| **Average log** | 100er Log = kein Abzug · 0er Log = −10 %, dazwischen linear |
| **First kill log** | Platz 1 = kein Abzug · letzter Platz = −15 %, dazwischen linear |
| **Movement/Survival** | von Hand gepflegt, Abzug in Prozent (Vorgabe: höchstens 20 %) |
| **Items seit Reset** | Abzug je Item, das der Spieler **seit dem letzten Wochen-Reset** erhalten hat (Vorgabe 15 %), Untergrenze ×0,70. Die Gesamtzahl wird nur angezeigt |
| **Crests** | Mythic-Crests, Eingang = „in der Tasche + bis zur Obergrenze frei": 0 → ×0,80, ab 80 → ×1,00, dazwischen linear (Vorgaben) |

Die Leistungswerte (Average log, First kill log) kommen aus **Warcraft Logs** und werden
je Charakter berechnet — gefiltert auf **Kills der eigenen Gilde**, **nur auf mythische
Kills** und **ohne Tanks**. Normal- und heroische Kills sind andere Bedingungen (kürzere
Kämpfe, weniger Mechaniken, andere Ausrüstung) und wären kein sauberer Maßstab.

- **Average log:** Median der Parse-Prozente über die **letzten 10 mythischen Kills**
  (einstellbar). Einzelne Bosse lassen sich von der Wertung ausnehmen.
- **First kill log:** die mythischen **Erst-Kills** je Boss. Der Wert wird auf 100 %
  Aktivzeit hochgerechnet, und für jede fehlende 5 % Aktivzeit sinkt er um 1 % (bezogen
  auf den ursprünglichen Wert). Verglichen wird mit dem besten Wert **derselben Rolle** im
  selben Kampf — **Heiler werden an der Heilung gemessen, nicht am Schaden**. Daraus
  ergibt sich die Rangfolge.

Die Zahlen je Charakter stehen in `gewichte.lua` und werden mit jeder Version
mitgeliefert. Sie werden außerhalb des Spiels gepflegt und berechnet.

<!-- STAND:ANFANG -->

## Aktueller Stand

*Automatisch erzeugt — Stand: 04.10.2026 15:50*

**Einstellungen:** die letzten 10 mythischen Kills · Abzug bei 0er Log 15 % · Abzug am letzten Erst-Kill-Platz 20 % · Movement höchstens 20 % · ohne Tanks · Bosse wie Nek'zali zählen nicht mit.

**Items & Crests:** Items seit dem Wochen-Reset — 10 % Abzug je Teil, Untergrenze ×0,70 · Crests ×0,90 bei 0, ×1,00 ab 80 (als Faktor zählt nur Mythic).

**Quelle:** mythischen Kills der eigenen Gilde aus Warcraft Logs (Average log: alle Kills im Zeitfenster, First kill log: die Erst-Kills je Boss).

| Spieler | Rolle | Average log | First kill | Movement | Skill-Abzug |
|---|---|---|---|---|---|
| Balren (Paldros) | DPS | 30,0 % (10 Kills) → 0,90 | Platz 10/22 → 0,91 | −5,0 % | 0,77 → −23,0 % |
| Bigboysushi | DPS | – | Platz 12/22 → 0,90 | – | 0,89 → −11,0 % |
| Blitzfaust | DPS | 41,0 % (6 Kills) → 0,91 | Platz 8/22 → 0,93 | −8,0 % | 0,78 → −22,0 % |
| Cep | DPS | 29,0 % (5 Kills) → 0,89 | Platz 6/22 → 0,95 | −2,0 % | 0,83 → −17,0 % |
| Cheliia | DPS | 47,5 % (10 Kills) → 0,92 | Platz 9/22 → 0,92 | −2,0 % | 0,83 → −17,0 % |
| dranash | Tank | – | – | −10,0 % | 0,90 → −10,0 % |
| Enshirou | DPS | 15,0 % (8 Kills) → 0,87 | Platz 13/22 → 0,89 | −8,0 % | 0,71 → −29,0 % |
| Exorzist (cheetah) | Heiler | 27,0 % (10 Kills) → 0,89 | Platz 9/22 → 0,92 | −5,0 % | 0,78 → −22,0 % |
| Exudes | DPS | – | Platz 2/22 → 0,99 | −4,0 % | 0,95 → −5,0 % |
| Garshû | DPS | 22,0 % (10 Kills) → 0,88 | Platz 16/22 → 0,86 | −3,0 % | 0,73 → −27,0 % |
| Gwêni (Snowi) | DPS | 9,0 % (7 Kills) → 0,86 | Platz 7/22 → 0,94 | −10,0 % | 0,73 → −27,0 % |
| Hyperhardw (Pasipháë) | DPS | 36,5 % (10 Kills) → 0,91 | Platz 14/22 → 0,88 | −5,0 % | 0,75 → −25,0 % |
| Indydrakes | DPS | 28,5 % (10 Kills) → 0,89 | Platz 19/22 → 0,83 | −1,0 % | 0,73 → −27,0 % |
| Jekyl (Rone) | DPS | – | Platz 20/22 → 0,82 | −10,0 % | 0,73 → −27,0 % |
| Merlón | DPS | 55,5 % (10 Kills) → 0,93 | Platz 5/22 → 0,96 | −7,0 % | 0,83 → −17,0 % |
| Neyzxd (Neyz) | DPS | 66,0 % (3 Kills) → 0,95 | – | −10,0 % | 0,85 → −15,0 % |
| Notam | DPS | 6,0 % (10 Kills) → 0,86 | Platz 17/22 → 0,85 | −10,0 % | 0,65 → −35,0 % |
| Ophrys (Juxe) | Heiler | 44,0 % (10 Kills) → 0,92 | Platz 16/22 → 0,86 | −7,0 % | 0,73 → −27,0 % |
| palaball | Heiler | – | Platz 18/22 → 0,84 | −3,0 % | 0,81 → −19,0 % |
| Palacetamol | Heiler | 81,0 % (5 Kills) → 0,97 | Platz 14/22 → 0,88 | – | 0,85 → −15,0 % |
| Schmeckies | DPS | 40,0 % (5 Kills) → 0,91 | – | −10,0 % | 0,81 → −19,0 % |
| setupx | Tank | – | – | −10,0 % | 0,90 → −10,0 % |
| Sikkz | DPS | 59,0 % (10 Kills) → 0,94 | Platz 4/22 → 0,97 | −0,0 % | 0,91 → −9,0 % |
| Silanhunt (Silan) | DPS | 6,0 % (9 Kills) → 0,86 | Platz 11/22 → 0,90 | −1,0 % | 0,76 → −24,0 % |
| Thunderdebbo | Heiler | 6,0 % (5 Kills) → 0,86 | Platz 14/22 → 0,88 | −8,0 % | 0,69 → −31,0 % |
| Tobii (Luc) | Heiler | 99,0 % (10 Kills) → 1,00 | Platz 1/22 → 1,00 | −0,0 % | 0,99 → −1,0 % |
| Twosocks (Sushi) | DPS | 38,0 % (7 Kills) → 0,91 | Platz 3/22 → 0,98 | −2,0 % | 0,87 → −13,0 % |
| Vilarie | DPS | 62,0 % (5 Kills) → 0,94 | Platz 18/22 → 0,84 | −2,0 % | 0,77 → −23,0 % |

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
| `rclc.lua` | die drei Spalten im RCLootCouncil-Fenster (offizielle Spalten-API) |
| `prioliste.lua` | Prioritätsliste je Charakter (1–5) |
| `gewichte.lua` | Rollen-, Wunschlisten- und Leistungsfaktoren |
| `loot.lua` | Rechenkurven für „Items seit Reset" und „Crests" |
| `daten.lua` | Datenquellen: RCLootCouncil-Loot-Historie und WowUtils-Währungen |
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
