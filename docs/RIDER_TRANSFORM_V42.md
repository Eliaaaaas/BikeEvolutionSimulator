# V4.2 — Fahrer und Bike als gemeinsame Fahrzeugeinheit

> [V4.3](MOVEMENT_TRAINING_V43.md) ergänzt Rampenzugang, isolierte lokale Vorhersage und einen eigenen Bike-Sprung. Die Avatar-Sprungsperre bleibt; Space ist jetzt Bike-Sprung statt Bremse. Historische Aussagen zur fehlenden Vorhersage sind damit überholt.

Der V4.1-Build ist nach tatsächlichem Studio-Feedback **nicht abgenommen**: normales Laufen und ein unabhängig um den Fahrer drehendes Bike. Dieser Auftrag repariert die Bewegungsintegration; keine zusätzliche Dekoration oder Wirtschaftssysteme. Branch und Draft PR #2 bleiben erhalten.

## Konkrete Ursachen im Code

| Befund in V4.1 | Reparatur in V4.2 |
| --- | --- |
| `BikeInput` las `GetMoveVector()`, unterband aber den normalen ControlModule-Dispatcher `moveFunction` nicht. Der Standardpfad konnte gleichzeitig `Player:Move`/Humanoid-Bewegung beauftragen. | Native Eingabesammlung bleibt an; der Move-Dispatcher wird während der Bike-Steuerung ersetzt und beim Abbau restauriert. Humanoid-MoveDirection wird neutralisiert, Sprungzustand server- und clientseitig deaktiviert. `controls:Disable()` wird bewusst nicht verwendet, da dadurch auch der Touch-Stick keine Eingaben mehr liefert. |
| `MountedBikeService.move` setzte nacheinander die CFrames zweier miteinander verschweißter Teile: Bike-Root **und** verankerten HumanoidRootPart. Die bewegte Fahrzeugposition wurde anschließend wieder aus der Avatarwurzel abgeleitet. Damit gab es zwei Transformationsautoren innerhalb derselben verbundenen Assembly und eine Rückkopplung über den Avatar-Offset. | Ausschließlich die Bike-Wurzel ist verankert und wird positioniert. Der Fahrer ist unverankert und folgt einem expliziten Gelenk am Fahrzeugrahmen. Die nächste Bewegung wird ausschließlich aus dem autoritativen Fahrzeug-CFrame integriert. |
| Die Sitzrelation war ein festes `CFrame.new(0,4.8,.9)` mit implizit erfasster WeldConstraint-Relation; Sattelgeometrie, R15-Beckengröße und Model-PivotOffset wurden nicht berücksichtigt. | Explizite Weld-C0/C1, Satteloberseite und tatsächliche Avatar-Bindmaße bestimmen die Montage. Initiales Model-Pivoting berücksichtigt den Root-zu-Model-Pivot. Nachgeladene oder skalierte Körperteile aktualisieren die Sitzrelation. |
| Das Bewegungsmodell integrierte die Gierbewegung auch bei Speed=0. Fahrer und Sattel konnten dadurch bei gehaltenem Lenkinput im Stand eine Kreisbewegung erzeugen. | Drehen des gesamten Fahrzeugs hängt von der Geschwindigkeit ab; reiner Lenkinput im Stand verändert Fahrzeug- und Sitzposition nicht. |
| Die Engine-Doubles behandelten `CFrame.Angles` als Identität, Multiplikation als Addition und simulierten keine Gelenkfortpflanzung. Grüne V4.1-Tests konnten Rotation/Pivotfehler deshalb nicht erkennen. | Vollständige 3D-Matrizen, Inverse, LookAt und explizite Weld-/Motor6D-Relationen im Testadapter. Regressionen verwenden gedrehte Koordinatensysteme und versetzte Pivots. |

Diese Befunde sind am bisherigen Quellcode nachweisbar. Es wurde **kein** neuer Studio-Trace erzeugt und keine konkrete Roblox-Physikreihenfolge als live reproduziert behauptet. Welche Engine-/Replikationseffekte den beobachteten Fehler im alten Build verstärkten, kann ohne Studio-Aufzeichnung nicht abschließend quantifiziert werden. Die widersprüchliche Transformationsarchitektur und der parallele Bewegungspfad sind jetzt entfernt.

## Gemeinsame Transformation

`record.Frame` ist die einzige serverseitige Welttransformation des Fahrzeugs. Die manuelle Inselsteuerung und die automatische Rennführung verwenden denselben `move`-Pfad:

```
BikeRoot.CFrame = VehicleWorld
FrameWorld      = VehicleWorld * FrameMotor.C0 * Transform * FrameMotor.C1:Inverse()
RiderWorld      = FrameWorld * PermanentRiderMount.C0 * PermanentRiderMount.C1:Inverse()
```

Der Fahrer wird nicht separat teleportiert oder gedreht. `PermanentRiderMount` ist ein expliziter Weld vom Fahrzeugrahmen zur HumanoidRootPart; sein C1 bleibt Identität. Der Rahmen darf lokal visuell neigen, weil Sattel und Fahrer dieselbe Rahmenbewegung erben. `Visuals` animiert ausschließlich die bekannten Rad-/Kurbel-/Lenk-/Rahmenmotoren und schreibt keine Fahrzeugwurzel-CFrames. Rennen schreiben den Fahrzeug-CFrame über denselben Mounted-Service. Es gibt kein zweites Trainingsmodell.

`RiderMount.place` setzt das initiale Model-Pivot auf `DesiredRootWorld * RootToModelPivot`, damit ein nichtleerer PrimaryPart-PivotOffset nicht zum falschen Ursprung führt. `BikeRig` erstellt auch für die sichtbare Fahrzeuggeometrie explizite Weld-Offsets statt impliziter WeldConstraint-Erfassung beim Reparenting.

Die Montage wird aus Sattelposition/-oberseite, Beckendimension und dem statischen RootJoint-C0/C1 bestimmt. Animierte Weltpositionen des Beckens gehen nicht in die Sitzberechnung ein. Root-/Torso-Größenänderungen und nachgeladene Körperteile markieren die Sitzgeometrie zur Neuberechnung. Auch der Karosserie-/Fahrer-Blockcast berücksichtigt nun die benötigte Avatarhöhe.

## Humanoid, Eingaben und Kamera

- Nur BikeRoot ist verankert. HumanoidRootPart bleibt unverankert und über das Sitzgelenk verbunden. Kein zweiter Positionsautor.
- WalkSpeed=0, AutoRotate aus, PlatformStand/Sit aktiv, normale Animate-Logik aus. Lauftracks werden beim Montieren gestoppt, später gestartete Tracks über Animator überwacht. Sprungzustand ist gesperrt; der lokale Move-Dispatcher neutralisiert auch MoveDirection/Jump.
- Tastatur und nativer mobiler Thumbstick liefern weiterhin Eingabevektoren an den bisherigen strikt validierten Drive-Remote. Menüs, Fokusverlust, Timeouts und Rennen blockieren manuelle Befehle wie bisher. Der Dispatcher wird nach Respawn nochmals sichergestellt; beim Abbau werden Hook und Eingabeverbindungen restauriert.
- Die Kamera folgt im Inselmodus dem aktuellen montierten Humanoid. Die vorhandene Rennkamera übernimmt automatisch und gibt danach denselben aktuellen Fahrer wieder frei. Respawn und GUI-Abbau räumen die Kameraverbindungen auf.
- R15-IK bleibt für Hände/Pedale/Fußrasten erhalten. Die Basispose neutralisiert alte Animationstransforms auch in den von IK kontrollierten Gelenken. Beim Effekt-Culling wird zur sitzenden Serverpose zurückgeblendet. R6 bleibt eine approximierte Gelenkpose; genaue Körperkontakte sind manuell zu prüfen.

## Erhaltene Regeln und Daten

Keine Änderungen an Energy-/Cash-/Rebirth-Formeln, Pet-Boni/Slots, Fahrzeugkäufen, Race-Bots/Rewards, Session-Locks, Autosave oder Profilschema. Der alte pauschale RiderHeight-Konfigurationswert entfällt zugunsten geometrischer Sitzberechnung; er war kein persistentes Feld. Spawn/Respawn, Fahrzeugwechsel, Training und Rennen behalten genau ein Spieler-Bike. Garage bleibt ein geschlossenes Gebäude mit einmaliger Halbkreis-Öffnung ohne E-Prompt.

Keine produktiven DataStores gelesen oder verändert. Alle automatisierten Profile sind isolierte In-Memory-Fixtures. Keine Merges oder Roblox-Veröffentlichung.

## Automatisierte Prüfungen

`python3 tools/test.py`: **168 Luau-Tests**, einschließlich 39 Runtime-Verdrahtungstests und vier neuer grundlegender Transformationsprüfungen. Die sieben neuen Runtime-Regressionen führen den tatsächlichen Montage-/Eingabe-/Visuals-/Kameracode aus:

1. Gemeinsame Pose bei vollen Gier-/Nick-/Rollwinkeln; explizit keine CFrame-Schreibzugriffe auf die Fahrerwurzel.
2. Nichtleerer, gedrehter PrimaryPart-PivotOffset erhält den gewünschten Bike-Ursprung und die Sattelrelation.
3. PlayerModule-Move wird unterbunden, während der Touch-Eingabevektor weiter Bewegung auslöst; Cleanup restauriert den Dispatcher.
4. Tatsächliche Wheel-/Lenk-/Rahmenanimation verändert den Fahrzeugursprung nicht; Fahrer bleibt am Rahmen gebunden.
5. Unterschiedliche R15-Beckendimensionen und RootJoint-Offsets in X/Y/Z halten den Beckenkontakt auf dem Sattel, auch nach Größenänderung.
6. Lenkinput im Stand lässt Fahrzeug- und Sitzposition unverändert.
7. Tatsächlicher Kameracode bindet den aktuellen Humanoid, übernimmt im Rennen und kehrt in den Inselmodus zurück.

Alle früheren Suiten bleiben erhalten. Anchor-Erwartungen wurden an die neue verbindliche Architektur angepasst; vertrauenswürdige serverseitige Fixture-Teleports bewegen jetzt das Fahrzeug statt die Fahrerwurzel. Spawn, Bike-Wechsel, Respawn, Training, Taps, Rennen, Mobile-Vektoren, Fehler/Disconnect und Datenspeicherung bleiben geprüft.

Der Testadapter nutzt echte 3D-Mathematik und explizite Gelenkgleichungen. Dekorative Blattgeometrie wird bei Bedarf aus ihrer Weld-Relation berechnet; das ist keine Roblox-Physiksimulation, kein Animator-/IK-Solver und kein Renderer. Er liefert weiterhin kontrollierte Kollisionsantworten. Die alten Identitätsrotationen sind vollständig entfernt.

Zusätzlich: Luau-Syntax/Strict-/Roblox-API-Typprüfung, sechs bestehende V4-Geometrieprüfungen, deterministische Welt-/Fahrzeug-/Pet-Generatoren, vollständiger Rojo-Build und Prüfung der tatsächlich eingebetteten Server-/Clientmodule. Neue Built-Place-Assertions sichern den einzelnen Fahrzeugtransformationsautor und den unterbundenen Move-Dispatcher.

Zwischenprüfungen fanden die oben behobene Drehung im Stand sowie notwendige Typverengungen für optionale Torso-Teile und das als Attribut gespeicherte CFrame. Die abschließenden Ergebnisse und der Workflow-Link stehen im PR. Keine nicht ausgeführte Studio-Prüfung wird als bestanden ausgegeben.

## NICHT AUSGEFÜHRT — genaue Studio-Abnahme

In dieser Umgebung steht Roblox Studio nicht zur Verfügung. Die folgende Liste ist ausdrücklich **NICHT AUSGEFÜHRT**:

| Manuelle Prüfung | Erwartung |
| --- | --- |
| Neuen V4.2-Place öffnen, Play, Diagnose/Output | Ein Bike pro Spieler; keine Montage-/ControlModule-/Assetfehler. Alte V4.1-Datei nicht erneut verwenden. |
| Spawn/Stand auf R15, unterschiedliche Körperhöhen/-breiten | Becken auf Sattel, Hände am Lenker, Füße auf Pedalen/Fußrasten; kein Stehen/Laufen/Springen. |
| WASD/Touch: geradeaus, volle Kurve, Bremsen, Rückwärtsfahrt | Bike und Fahrer bilden eine Einheit. Kein Orbit um einen stehenden Avatar. Lenkinput im Stillstand verschiebt nichts. |
| Reale Geometrie/Kollision/Netzwerkverzögerung | Keine Wand-/Bodenkollisionen, kein Durchfallen. Fahrgefühl unter realer Latenz und 20-Hz-Serverführung prüfen; weiterhin keine lokale Bewegungsprognose. |
| Alle zehn Bikes wechseln, R15 nachskalieren, Respawn | Genau ein korrekt montiertes neues/ausgerüstetes Modell, stabile Sattelrelation, keine dauerhaft verwaisten Modelle. |
| Fünf Laufbänder befahren, automatisch trainieren und tippen | Energy und Boni unverändert, gleiches Bike; Verlassen beendet nur Training. Pedale/Füße bzw. Moped-Fußrasten passen. |
| Easy/Medium/Hard und Abbruch/Finish/Tod | Dieselbe Einheit fährt automatisch; fünf Bots, unveränderte Rewards. Danach manuelle Inselsteuerung und Kamera, ohne Absteigen. |
| Kamera und Touch auf iPhone/iPad Hoch-/Querformat | Kamera folgt Fahrer/Bike, native Thumbstick-Steuerung und Bremse reagieren. Keine doppelte Standardbewegung oder UI-Überdeckung. |
| Animationen aus/an, Menü/Hatch/Pets/Garage | Sitz bleibt bestehen, keine Lauf-/Sprungtracks, keine unabhängige Rahmendrehung. Garage-Öffnung bleibt einmal je Eintritt. |
| Zwei Clients, Streaming, Kamera-Reset, GUI-Neustart | Andere Spieler sehen dieselbe montierte Einheit. Keine konkurrierenden Kamera-/Bewegungsverbindungen oder sichtbaren Replikationssprünge. |

Exakte IK-Kontakte, reale Weld-/Humanoid-Interaktion, Touch-Verhalten, Kameraübergänge und Framerate können erst nach diesen Playtests abgenommen werden. R6-Kontakt und ungewöhnliche Avatar-Proportionen benötigen gesonderte Sichtprüfung. Persistenz ausschließlich in separater Test-Experience testen.

## Build

`python3 tools/package_v4.py --version V4.2` erstellt **BikeEvolutionSimulator-V4.2.zip** mit vollständiger `.rbxlx`, BUILD_INFO mit Commit/UTC und SHA256SUMS. XML-Abschluss, ZIP-CRC und Place-Prüfsumme werden verifiziert. Actions lädt das neue **BikeEvolutionSimulator-V4.2** zusätzlich zu den bestehenden Artifacts hoch. Fehlende Dateien lassen den Workflow fehlschlagen. Kein öffentliches Release und kein Roblox-Publish.
