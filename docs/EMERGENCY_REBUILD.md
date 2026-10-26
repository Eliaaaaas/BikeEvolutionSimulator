# World 1 Emergency Rebuild — keine Studio-Abnahme

Der vorherige Build ist aufgrund des Spielerfeedbacks **nicht abgenommen**. Dieser Stand behebt konkrete Fehler und bereitet einen erneuten Test vor. Roblox Studio ist in der Cloud-Umgebung nicht ausführbar. Alle untenstehenden Studio-Fälle sind **NICHT AUSGEFÜHRT**. Ein grüner CI-Lauf ist kein Spielbarkeitsnachweis.

## Befunde und Grenzen der Ursachenanalyse

Es liegt kein Studio-Output/Stacktrace des fehlgeschlagenen Spieler-Tests vor. Die folgenden Defekte sind durch Quellcode und reproduzierbare Engine-Doubles belegt. Eine eindeutige Zuordnung jedes Spieler-Symptoms zu einem Studio-Fehler ist ohne erneuten Playtest nicht möglich.

| Befund im vorherigen Stand | Konkrete Folge | Reparatur / Nachweis |
| --- | --- | --- |
| `UI.new()` gab kein `Gui` zurück. `Visuals`, `PetFollowers` und `IslandEffects` verwenden `ui.Gui.Parent`. | Asynchrone Schleifen greifen auf `nil.Parent` zu; Fahrzeug-/Charakteranimationen und Begleiter fallen aus. Bestätigte Ursache ausgefallener visueller Systeme, kein Beweis für alle Mechanikfehler. | `Gui=gui` als verbindliches UI-API-Feld; echter UI-Aufbau samt Client-Bootstrap im Integrationstest. |
| `GetDataStore()` in `newBackend()` lag außerhalb des geschützten Load-Aufrufs. | Bei unveröffentlichtem Place kann die Initialisierung vor `backend:load()` abbrechen, `loading` bleibt erhöht und der Client wartet ohne Erklärung. | Backend-Erstellung per `pcall`, sauberer Status und Shutdown-Zähler; expliziter Studio-Vorschaumodus ohne DataStore-Aufruf; separater Regressionstest. |
| Nur Fahrzeuge in ReplicatedStorage; außerhalb eines Rennens keine Welt-Klone. | Beim Betrachten der Insel ist kein Bike vorhanden. Das allein beweist keinen fehlgeschlagenen Renn-Klon. | Zehn verankerte, nicht fahrbare Ausstellungsmodelle in `Workspace.World1.GarageShowroom`, bereits in der gebauten Datei. Garage-Viewport wird anhand echter Modellgrenzen zentriert. |
| ProximityPrompt-Callbacks verwarfen das Ergebnis von `handle()`. Prompt-Reichweite war größer als die rechteckige Trainingszone. | Ein sichtbarer Prompt konnte außerhalb der erlaubten Zone abgewiesen werden, ohne eine Fehlermeldung zu zeigen. | Fehler-Feedback über dasselbe Server-Client-System; serverseitiges Betreten wählt einen erlaubten Belt automatisch aus. Ein ausdrückliches Stop bleibt bis zum Verlassen/erneuten Betreten wirksam. Abstand, Cooldowns und Besitzprüfung bleiben erhalten. |
| Client-Effekte wurden vor der vollständigen Kommunikationsverdrahtung gestartet; Bootstrap hatte keine sichtbaren Stufen/Fehler. | Ein Effekt-/Dependency-Fehler oder unbegrenztes Warten konnte wie ein komplett funktionsloses Spiel wirken. | Minimaler unabhängiger Diagnose-Bootstrap, Stufen und Weltvertrag; Remotes/UI zuerst, optionale Effekte anschließend isoliert. |
| `RaceCourse` maß nur X/Z und interpolierte keine Höhe; generierte Route war ein fast geschlossener Ovalbogen. | Kein abwechslungsreicher Kurs; ein bloßer Austausch durch Höhenpunkte hätte ungenaue Distanz/Führung erzeugt. | Offene S-Route, 3D-Bogenlänge und Höheninterpolation, Steigung in Server-Führung, sichtbare Brückenabschnitte und separate Rennkamera. |

Das Rojo-Mapping des bisherigen Scripts und LocalScripts war korrekt. Im gebauten XML wurden keine deaktivierten Bootstrap-Scripts festgestellt. Für angeblich fehlende Remote-Klassen oder fehlende Fahrzeugquellen gibt es ebenfalls keinen Beleg; die Integration wird nun ausdrücklich geprüft, statt diese Ursachen zu erfinden.

## Diagnose und sichere Testdaten

- Der unveränderte normale Spielserver verwendet weiterhin Store `BikeEvolution_Player_v1`, Schema v2, Profilvalidierung, Session-Locks, Autosave und Leave-/Shutdown-Recovery.
- **Studio-Standard:** Workspace-Attribut `StudioPreviewData=true`. Ausschließlich `RunService:IsStudio()` aktiviert den expliziten In-Memory-Store. Kein Lesen/Schreiben eines Roblox-DataStores. Der gut sichtbare Banner lautet **STUDIO PREVIEW • NICHT DAUERHAFT**. Daten überleben Rejoin innerhalb desselben laufenden Testservers, aber weder Stop/Play noch Serverneustart. Dies ist ausdrücklich kein Test dauerhafter Speicherung.
- Für echte Studio-Speicherprüfungen `StudioPreviewData=false` setzen, die Datei in einer separaten Test-Experience veröffentlichen und API Services dort aktivieren. Studio verwendet dann zwingend den getrennten Store **BikeEvolution_StudioTest_v2**, niemals den normalen Store. Auch dieser Modus bleibt im Banner sichtbar.
- Auf veröffentlichten Servern wird das Studio-Preview-Attribut ignoriert. Eine separate veröffentlichte Test-Experience hat aufgrund ihrer eigenen Universe-ID ohnehin eigene DataStores. Niemals die produktive Experience für die manuelle Prüfung verwenden.
- In Studio zeigt der Diagnose-Banner Serverzustand/-Stufe, Clientstatus und Initialisierungsfehler. Auf einem privaten **Testserver** kann am Server-Script das boolesche Attribut `DiagnosticsEnabled=true` gesetzt werden. Der Server muss ein echter privat besessener Server sein. Öffentliche Server zeigen keine internen Fehlerdetails.
- Der Diagnosemodus hat keine Grant-, Teleport-, Kauf-, Lock-Bypass- oder Reward-Remotes. Alle wirtschaftlichen Aktionen verwenden dieselben validierten Controller. Er ist niemals ein automatischer Ersatz für einen ausgefallenen Live-DataStore.
- Keine Schemaänderung, keine Profilmigration und keine produktiven Profile während dieses Auftrags. Reale Crash-/Budget-Grenzen der bestehenden Architektur bleiben bestehen.

## Automatisierte Integration: was tatsächlich geprüft wird

`tools/test.py` baut zuerst die echte `.rbxlx`. `tools/runtime_tests.py` erzeugt daraus die Welt-/Modellhierarchie für vereinfachte Engine-Doubles. Die Tests führen unveränderte Implementierungen von Server-Bootstrap, Client-Bootstrap, ClientApp, UI/Icons, RemoteService, GameplayService, PlayerDataService, RaceService/BikeRig und den Regelcontrollern aus. Lediglich Modulauflösung und Engine-Services werden injiziert. Audio und optionale Darstellungs-Loops werden im Verdrahtungstest ersetzt; sie sind kein getesteter Teil der Engine-Simulation.

Geprüft werden tatsächliche UI-Button-Callbacks → Action-Remote → Servervalidierung → Profiltransaktion → Snapshot/Feedback → UI, tatsächliche Prompt-Callbacks, serverseitige Betretenerkennung, fünf Bot-Klone, Ende/Auszahlung/Cleanup, Garage-Viewport aller zehn Fahrzeuge, Kauf/Equip, Hatch/Pet-Equip/Boni sowie Speichern/erneutes Laden im isolierten Vorschau-Store. Der Ablauf verdient Cash durch wiederholte echte servergesteuerte Simulationsrennen; es existiert kein Debug-Geldremote.

`tests/place_integration_test.py` prüft das gebaute XML: aktive Script-Klassen und Parenting, auflösbare `require(script...)`-Pfade, vorhandene World-/Trainings-/Station-Komponenten, zehn sichtbare Ausstellungsfahrzeuge, begrenzte Insel-Partzahl und die offene 800-Studs-S-Route einschließlich Höhenprofil.

**Nicht nachgewiesen:** Roblox-Rendering, echte Replikationsreihenfolge, Kamera/Motor6D/IK/Viewport-Beleuchtung, Touch, Studio-Prompts, echte DataStore-Aufrufe, Frameraten. Dafür ist die folgende Abnahme zwingend.

## Roblox-Studio-Abnahme — alle Fälle NICHT AUSGEFÜHRT

Vorbereitung: neuestes Artifact entpacken; Datei in Studio öffnen; Output und Developer Console offen halten. Zuerst `StudioPreviewData=true`; danach getrennte Speicherprüfung mit `false`. Keine früher veröffentlichte Produktionsdatei verwenden. Für jeden Fall tatsächliches Ergebnis, Screenshot/Output und Gerät protokollieren.

| ID | Handlung | Erwartetes Ergebnis | Status |
| --- | --- | --- | --- |
| B1 | Neue Datei im Edit-Modus öffnen | Zehn Bikes/Mopeds im Garage-Showroom, fünf Neon-Belts, drei Eier und offene S-Strecke; Rebirth nur in der Sidebar vorhanden. | NICHT AUSGEFÜHRT |
| B2 | Play in unveröffentlichter Datei, Preview=true | Spawn in der Mitte; deutlich markierter nicht dauerhafter Modus; Server Ready und Clientdaten bereit; keine DataStore-Fehler/Kicks. | NICHT AUSGEFÜHRT |
| B3 | Im Edit-Modus Zone von Belt 1 umbenennen, dann Play | Diagnose nennt fehlenden vollständigen Pfad; Server Failed statt stiller leerer UI. Danach Änderung rückgängig machen. | NICHT AUSGEFÜHRT |
| B4 | Öffentlichen Testserver starten | Kein Preview-Store trotz Workspace-Attribut; kein interner Diagnose-Stacktrace für normale Spieler. | NICHT AUSGEFÜHRT |
| T1 | Auf Belt 1 laufen, ohne E/Tap | Nach Auswahl automatischer Impuls ungefähr jede Sekunde; Status TRAINING AKTIV; Energy steigt. | NICHT AUSGEFÜHRT |
| T2 | Training-Button klicken/tippen und stark spammen | Zusätzliche erlaubte Impulse, maximal fünf/Sekunde; kein ungebremster Gewinn. | NICHT AUSGEFÜHRT |
| T3 | Von Belt weggehen; gesperrten Belt 5 versuchen | Weggehen beendet Training; gesperrtes Schild zeigt aktuelle Anforderungen; keine Energy für gesperrten Belt. | NICHT AUSGEFÜHRT |
| T4 | Belts 2–5 mit aktuellen Voraussetzungen betreten | Basis 2/4/8/16, Welt UND Energy ODER Rebirth; sichtbare Belt-/Charakteranimation. | NICHT AUSGEFÜHRT |
| R1 | Rebirth links in der Sidebar öffnen, abbrechen, erneut bestätigen bei genügend Energy | Abbrechen unverändert; Bestätigen Energy=0, Rebirths+1, ×1.5; Cash/Pets/Fahrzeuge unverändert, höherer Belt ggf. gesperrt. | NICHT AUSGEFÜHRT |
| V1 | Garage über Station und Sidebar öffnen, alle zehn wählen | Modell vollständig in beleuchteter, rotierender Vorschau; unterschiedliche Formen, Preise, Besitz, aktives Fahrzeug. | NICHT AUSGEFÜHRT |
| C1 | Race-Zone → Easy starten | Drei Sekunden Countdown; Fahrer sitzt sichtbar auf gewähltem Bike; fünf sichtbare Bots; automatische Fahrt, S-Kurven und Höhenwechsel ohne manuelle Steuerung. | NICHT AUSGEFÜHRT |
| C2 | Ganze Route beobachten | Strecke befahrbar, Brücken ohne Lücken; Räder/Pedale/Lenkung, Rennkamera ohne Clipping; Moped hat keine Pedalbewegung. | NICHT AUSGEFÜHRT |
| C3 | Ziel erreichen; Medium und Hard wiederholen | Tatsächliche Platzierung; einmalige tier-/platzabhängige Cash-Gutschrift; Energy unverändert; sichere Rückkehr und normale Laufkamera. | NICHT AUSGEFÜHRT |
| C4 | Während Rennen sterben/abbrechen/disconnecten | Alle temporären Fahrzeuge entfernt; kein unberechtigtes Cash; Kontrollen/Kamera zurück, Rejoin möglich. | NICHT AUSGEFÜHRT |
| V2 | Genug Cash verdienen; Fahrzeug 2 kaufen und ausrüsten | Genau ein Cash-Abzug; Besitz bleibt; nächstes Rennen zeigt City Bike mit Fahrer. Danach Fahrrad und Moped testen. | NICHT AUSGEFÜHRT |
| P1 | Jedes der drei Eier öffnen | Vier Arten/Chancen pro Ei; richtiger Preis; genau ein serverbestimmtes Pet; bei fehlendem Cash kein Abzug/Pet. | NICHT AUSGEFÜHRT |
| P2 | Drei Pets ausrüsten; viertes versuchen; eines ablegen | Drei sichtbare Begleiter; Index/Slots stimmen; viertes abgewiesen; Boni erhöhen echte Training-/Renngewinne. | NICHT AUSGEFÜHRT |
| S1 | Preview verlassen und im selben laufenden Testserver erneut verbinden | Sitzungsfortschritt bleibt; nach Stop/Play klar erwarteter Preview-Neustart. Kein Anspruch auf dauerhafte Speicherung. | NICHT AUSGEFÜHRT |
| S2 | Separate Test-Experience, Preview=false, API-Zugriff, Autosave/Leave/Rejoin | Isolierter Studio-Teststore; Energy/Cash/Rebirths, Auswahl/Besitz, Pets/Equip/Index über Serverneustart erhalten. | NICHT AUSGEFÜHRT |
| S3 | API-Zugriff deaktivieren, Preview=false | Verständlicher Fehler/Kick; niemals Ersatz-Defaults über vorhandene Profile schreiben. | NICHT AUSGEFÜHRT |
| M1 | iPhone/iPad Hoch-/Querformat, PC | Alle Aktionen bedienbar; Sidebar/Safe Areas frei; Fenster scrollen; Fahrer/Modelle sichtbar; Kamera wiederhergestellt. | NICHT AUSGEFÜHRT |
| M2 | Animationen/Popups/Sound ausschalten | Optionale Effekte ruhen; echte Gains/Race-Führung bleiben korrekt; keine verwaisten Effekte nach Respawn. | NICHT AUSGEFÜHRT |
| M3 | Zwei Clients/Netzwerklatenz/mehrere Rennen | Unabhängige Sitzungen/Rewards; keine doppelten Auszahlungen, fremde Solo-Bots ausgeblendet; keine Snapshot-Rücksprünge. | NICHT AUSGEFÜHRT |

Erst nach protokollierten Ergebnissen dieser Fälle kann World 1 manuell abgenommen werden. Bei Fehlern bitte insbesondere rote Output-Zeile, Server-/Client-Ansicht, Bannerzustand und Test-ID festhalten.


Visual Upgrade V2 ersetzt die frühere Ressourcenplatzierung und entfernt den physischen Rebirth-Stand. Verbindliche aktuelle Vorgaben und zusätzliche manuelle Tests: [VISUAL_UPGRADE_V2.md](VISUAL_UPGRADE_V2.md). Rebirth-Regeln und Speicherarchitektur bleiben unverändert.
