# WoWUtils Plus

Ein Zusatz-Addon für **World of Warcraft**, das im Abstimmungsfenster von
**RCLootCouncil** vier eigene Spalten anzeigt: den **gewichteten** Sim-Gewinn,
die erhaltenen **Items**, die **Crests** und die **Tier-Set-Teile**.
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
  Grundwert aus WowUtils             +510,00 (+0,26 %)
  x1,00  Rolle: DPS                   +0,00
  x0,90  Prio: 2                     -51,00
  x1,00  Wunschliste: Best in Slot    +0,00
  x0,94  Average log: 42,50 %        -27,54
  x0,95  First kill: Platz 8/22      -22,95
  x0,92  Movement: -8,00 %           -36,72
  x0,73  Items 2 · seit Reset 2 · Crests 10 + 10   -102,24
  Gewichtet                          +269,55
  ```

  Die Beträge laufen mit und summieren sich genau zum Ergebnis. Zwei Blöcke werden dabei
  **addiert**: die drei Leistungs-Abzüge (Average log, First kill, Movement) und die beiden
  Posten Items und Crests — beide rechnen jeweils auf demselben Stand.

- **Gewinn in Prozent hinter dem Wert:** Bei **DPS und Tanks** steht hinter dem gewichteten Wert
  der Item-Gewinn in Prozent — `+510,00 (+1,65 %)`. Grund: die Sims liefern dort einen
  **absoluten** Gewinn und den **Bezugswert** mit, also lässt sich der Prozentwert ausrechnen
  (Gewinn ÷ Bezugswert). Bei **Heilern** ist der Wert selbst schon ein Prozentwert — dort steht
  nichts dahinter, sonst wäre es doppelt. So lassen sich DPS- und Heiler-Gewinne vergleichen.
  🔴 Fehlt der Bezugswert (Sim liefert keinen), bleibt es beim reinen Wert — es wird nichts
  geschätzt. Sortiert wird weiter nach dem **gewichteten Wert**, nicht nach dem Prozentwert
- **Sortierbar:** Klick auf die Spaltenüberschrift sortiert numerisch nach dem
  gewichteten Wert (nicht nach dem angezeigten Text)
- **Vier weitere Spalten:** **„Items"** (insgesamt · seit Reset), **„Crests"** (Mythic: in der
  Tasche + frei), **„Set"** und **„Roll"**. Der Tooltip der Items-Spalte listet die seit dem Wochen-Reset
  erhaltenen Teile, der der Crest-Spalte die Stufen **Hero und Mythic**. RCL protokolliert eine
  Vergabe gelegentlich **doppelt** (gleicher Itemlink, gleicher Tag, andere Eintrags-ID) — ein
  Itemlink pro Tag zählt deshalb nur **einmal**
- **Spalte „Roll":** zeigt, ob der Kandidat **dieses** Item in seiner WowUtils-Wunschliste mit einem
  Roll-Hinweis markiert hat — **„Bonus-Roll"** bzw. **„Roll"**. 🔴 Die Markierung ist **Freitext**,
  kein eigenes Feld: üblich sind Notizen wie „bonus roll" oder „roll". Gesucht wird deshalb mit
  **Wortgrenze**, damit ein Satz wie „…bei coiled altar rollen" **nicht** fälschlich als Roll zählt.
  Der Tooltip der Zelle zeigt die **vollständige Notiz** des Spielers (dort steht auch alles
  andere, was er sich zum Item notiert hat). Immer sichtbar, steht ganz rechts
- **Crests- und Set-Spalte** sind standardmäßig ausgeblendet und lassen sich einschalten
  (Kästchen in den Addon-Einstellungen oder `/wup crests` bzw. `/wup set`). Siehe unten.
- **Spalte „Set":** ein Buchstabe je Tier-Slot in fester Reihenfolge — **H** Kopf,
  **S** Schulter, **C** Brust, **G** Hände, **L** Beine. **Standardmäßig ausgeblendet**,
  einschaltbar über die Addon-Einstellungen. Siehe unten.
- Ohne passenden Sim-Eintrag steht `---` — es wird nie geraten

## Die Gewichtung

Zwei Blöcke werden **addiert**, alles andere multipliziert:

**Rolle × Prioritätsliste × Wunschliste × (1 − (Average-Abzug + First-kill-Abzug + Movement-Abzug)) × (1 − (Items-Abzug + Crests-Abzug))**

- **Leistung:** Average log, First kill log und Movement rechnen alle drei auf demselben Stand —
  dem Wert nach Rolle, Prio und Wunschliste — und werden **addiert**. Wer dort −10 % Average,
  −15 % First kill und −8 % Movement hat, verliert also **33 %**; beim Multiplizieren wären es
  30 % gewesen.
- **Items und Crests** bilden zusammen **einen** Faktor: auch hier werden die beiden Abzüge
  addiert. Beide Stellschrauben der Seite bleiben erhalten, im Tooltip steht dafür **eine** Zeile.

Rolle, Prioritätsliste und Wunschliste bleiben multiplikativ.

**Bereiche abschaltbar:** Auf der Webseite lässt sich jeder der drei Bereiche **Wunschliste**,
**Warcraft Logs** und **Items & Crests** mit einem Kästchen („Nicht mitrechnen“) ganz aus der
Rechnung nehmen. Übertragen wird dann kein Schalter, sondern einfach der **neutrale Wert** (Faktor
1,00): die Wunschlisten-Faktoren stehen dann auf 1,00/1,00, der Items-Abzug auf 0 und der
Crests-Mindestfaktor auf 1,00, und für die Leistung kommen **keine Spielerwerte** an. Das Addon
muss die Kästchen deshalb nicht kennen — es sieht nur Zahlen ohne Wirkung, und im Tooltip fehlen
die zugehörigen Zeilen.

| Faktor | Wirkung |
|---|---|
| **Rolle** | DPS ×1,00 · Healer ×0,52 · Tank ×0,90 |
| **Prioritätsliste** | 1 = kein Abzug · 2 = −10 % · 3 = −20 % · 4 = −30 % · 5 = −40 % |
| **Wunschliste** | Best in Slot ×1,00 · Upgrade ×0,60 (greift nur, wenn jemand das Item als BiS bzw. Upgrade führt) |
| **Average log** | 100er Log = kein Abzug · 0er Log = −10 %, dazwischen linear |
| **First kill log** | Platz 1 = kein Abzug · letzter Platz = −15 %, dazwischen linear |
| **Movement/Survival** | von Hand gepflegt, Abzug in Prozent (Vorgabe: höchstens 20 %) |
| **Items seit Reset** | Abzug je Item, das der Spieler **seit dem letzten Wochen-Reset** erhalten hat (Vorgabe 15 %), Untergrenze ×0,70. Die Gesamtzahl wird nur angezeigt. Bildet mit den Crests **einen** Faktor, die Abzüge addieren sich. 🔴 Ein Itemlink pro Tag zählt **einmal** — RCL protokolliert dieselbe Vergabe manchmal doppelt |
| **Crests** | Mythic-Crests, Eingang = „in der Tasche + bis zur Obergrenze frei": 0 → ×0,80, ab 80 → ×1,00, dazwischen linear (Vorgaben). Bildet mit den Items **einen** Faktor |

Die Leistungswerte (Average log, First kill log) kommen aus **Warcraft Logs** und werden
je Charakter berechnet — gefiltert auf **Kills der eigenen Gilde**, **nur auf mythische
Kills** und **ohne Tanks**. Normal- und heroische Kills sind andere Bedingungen (kürzere
Kämpfe, weniger Mechaniken, andere Ausrüstung) und wären kein sauberer Maßstab.

- **Average log:** Median der Parse-Prozente über die **letzten 10 mythischen Kills**
  (einstellbar). Einzelne Bosse lassen sich von der Wertung ausnehmen.
- **First kill log:** die mythischen **Erst-Kills** je Boss. Der Wert wird auf 100 %
  Aktivzeit hochgerechnet (Faktor F = 100/Aktivzeit), danach sinkt er um 5,5 % je
  Hochrechen-Schritt (F − 1) — höchstens bis auf den rohen Wert. Grund: die ersten 40 s
  laufen gemessen rund 1,7× heiß (Bloodlust, Trinkets, Trank, große Cooldowns); wer früh
  stirbt, würde sonst zu großzügig hochgerechnet. Verglichen wird mit dem besten Wert
  **derselben Rolle** im selben Kampf — **Heiler werden an der Heilung gemessen, nicht am
  Schaden**. Daraus ergibt sich die Rangfolge.
- **Fehlt ein Wert** — typisch bei neuen Mitgliedern, die noch keine Logs mit der Gilde haben —
  zählt für diesen Teil der **Kader-Median**: also „durchschnittlich", nicht „einwandfrei". Wer
  noch gar keine Werte hat, wird genauso gerechnet. Vorher zählte ein fehlender Wert als „kein
  Abzug", wodurch Neue über dem halben Kader standen. **Tanks sind ausgenommen** — bei ihnen
  bleibt ein fehlender Teil ohne Abzug.

Die Zahlen je Charakter stehen in `gewichte.lua` und werden mit jeder Version
mitgeliefert. Sie werden außerhalb des Spiels gepflegt und berechnet.

## Spalten ein- und ausblenden

Zwei der vier eigenen Spalten sind **standardmäßig ausgeblendet** und lassen sich einschalten —
beim Start **und** im Betrieb, ohne Neuladen. Beides wird gespeichert und gilt auch nach dem
nächsten Login:

- **Set-Spalte** — Optionen → Addons → RCLootCouncil → **WoWUtils Plus** →
  Kästchen **„Set-Spalte anzeigen"**, oder `/wup set`
- **Crests-Spalte** — Kästchen **„Crests-Spalte anzeigen"**, oder `/wup crests`

Die Spalten „Gewichtet" und „Items" bleiben immer sichtbar.

## Die Set-Spalte

Sie beantwortet eine Frage: **wer hat welches Tier-Set-Teil schon?** Damit lässt sich ein
gedroppter Token fair verteilen, statt ihn jemandem zu geben, der das Teil längst trägt.

```
H S C G L  4/5
```

Feste Reihenfolge: **H** Kopf · **S** Schulter · **C** Brust · **G** Hände · **L** Beine.
Die Zahl dahinter zählt, wie viele der fünf Slots bekannt sind.

| Farbe | Bedeutung |
|---|---|
| **grün** | hat das Teil — angezogen oder aus einem Token bzw. der Truhe |
| **gelb** | liegt in seiner Truhe, noch nicht abgeholt |
| **grau** | nichts bekannt |
| **rot** | der Slot, um den es gerade geht, ist bei ihm schon belegt |

Der Tooltip listet alle fünf Slots einzeln auf und nennt das Ziel — also den Slot, zu dem
das Item im Fenster gehört. Rot erscheint nur, wenn das Teil **wirklich** sein ist: ein
Stück, das noch ungenutzt in der Truhe liegt, ist ein Hinweis, kein Ausschluss.

**Woher die Angaben kommen:**

- **Angezogen** — direkt aus dem Spiel gelesen. Erkannt wird ein Tier-Teil an seinen
  **Set-Boni**: hat ein Teil Set-Boni, aber nicht für alle Klassen, ist es ein Tier-Teil.
  Das Spiel rückt fremde Ausrüstung nur heraus, wenn man die Person **untersucht** — das
  erledigt das Addon im Hintergrund selbst, eine Person nach der anderen. Bei anderen
  füllt sich die Spalte deshalb mit ein bis zwei Sekunden Verzögerung.
- **Token** — RCLootCouncil führt eine eigene Tabelle, welcher Token zu welchem Slot
  gehört. Sie wird nur gelesen, nicht gepflegt.
- **Truhe** — aus den Truhendaten der Gilde. WowUtils hält immer nur die laufende Woche,
  deshalb schreibt das Addon abgeholte Teile in die eigenen Speicherdaten mit; sie
  überleben so den Mittwochs-Reset.

**Was es nicht kann:** fremde Ausrüstung gibt das Spiel nur heraus, wenn die Person in
derselben Gruppe **und in Reichweite** ist (rund 28 Meter) und das Untersuchen gelingt.
Wer zu weit weg steht oder wenn der Server die Anfrage drosselt, bleibt dort leer — es
wird nichts geraten. Sichtbar ist immer nur die **eigene** Rüstungsart, denn Tier-Teile
sind klassen- bzw. rüstungsgebunden.

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
