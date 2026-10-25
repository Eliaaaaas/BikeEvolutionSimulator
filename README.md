# Bike Evolution Simulator — Phase 2.1: Palm Bay & Mountainbike

Spielbare Trainingsschleife mit tropischer Insel, fünf Laufbändern, bestätigten Rebirths, animierter linker Sidebar und servergesteuertem Mountainbike-Test-Rennen auf einer 800-Studs-Strecke. Garage zeigt das kostenlose Startbike als 3D-Vorschau. Pets, Worlds und Upgrades bleiben ausdrücklich noch nicht spielbare Vorschauen; der Testmodus enthält keine Bots oder Cash-Belohnungen.

Phase 2 basiert auf `feat/phase-1-luau-foundation` und liegt in `feat/phase-2-training-world`. Phase 1 wird dafür nicht gemergt. Der Phase-2-Draft-PR richtet sich gegen den Phase-1-Branch, damit die Änderungen getrennt geprüft werden können.

## Fertige Datei in Roblox Studio öffnen

1. Unter [Actions → Validate Luau foundation](https://github.com/Eliaaaaas/BikeEvolutionSimulator/actions/workflows/validate.yml) einen **erfolgreichen Lauf für `feat/phase-2-training-world`** auswählen.
2. Unter **Artifacts** `BikeEvolutionSimulator-Studio` herunterladen (GitHub-Anmeldung nötig), ZIP entpacken.
3. `BikeEvolutionSimulator.rbxlx` in Roblox Studio über **File → Open from File…** öffnen. Dafür sind keine lokalen Rojo-/Luau-Werkzeuge erforderlich.
4. Die Datei in einer **separaten Test-Experience** veröffentlichen. Unter Game Settings → Security **Enable Studio Access to API Services** aktivieren. Keine produktive Experience verwenden: Studio-Zugriff kann deren echte Daten verändern.
5. Play starten. Wenn DataStore nicht erreichbar oder ein Profil noch durch einen anderen Server gesperrt ist, wird der Spieler sicherheitshalber getrennt. Es gibt keinen flüchtigen Fallback, der bestehende Daten überschreibt.

Der Workflow behält sämtliche Tests und den Rojo-Build bei. Danach lädt `actions/upload-artifact@v4` `build/BikeEvolutionSimulator.rbxlx` hoch; `if-no-files-found: error` lässt den Workflow bei fehlender Datei fehlschlagen.

## Spielen und in Studio testen

- Spawn ist in der Inselmitte. Mit WASD/Joystick zur Trainingsreihe an der hinteren Felswand gehen. Die Grasoberfläche liegt überall auf Höhe 8 Studs.
- Auf Laufband 1 stellen und den Roblox-Prompt **Trainieren** per E bzw. Tap auswählen. Das HUD zeigt die aktive Auswahl und den tatsächlichen Gewinn. Ohne weitere Eingabe gibt es einen Impuls pro Sekunde.
- Der große **Training**-Button gibt bei jedem gültigen Klick/Tap einen zusätzlichen Impuls. Maximal fünf Klickimpulse/Sekunde sind erlaubt (0,2 Sekunden Cooldown). Ein aktiviertes Laufband bleibt erforderlich; ein beliebiger Bildschirmtap außerhalb des Buttons trainiert nicht.
- Nach +1 Energy ist Laufband 2 zugänglich. Die ersten fünf normalen Stärken sind +1, +2, +4, +8, +16 vor Rebirth-Bonus. Es gibt keinen Kauf. Die Anzeigen an den Laufbändern nennen die aktuellen Energy-/Rebirth-Anforderungen.
- Weglaufen oder Tod stoppt die Auswahl. Nach Respawn oder erneutem Beitritt muss ein Laufband neu ausgewählt werden; Energy/Cash/Rebirths bleiben im Profil erhalten.
- **Rebirths** in der Sidebar öffnet die Vorschau mit aktuellem/nächstem Multiplikator und Fortschritt (anfangs benötigt: 1000 Energy). Abbrechen darf nichts ändern. Bestätigen setzt Energy auf 0 und erhöht Rebirths um 1: Multiplikator ×1 → ×1,5 → ×2 → ×2,5. Ein höheres Laufband kann dadurch wieder gesperrt werden.
- Nach einem erfolgreichen Save verlassen und erneut beitreten. Energy, Cash und Rebirths müssen erhalten bleiben. Bei einem abrupten Serverstopp können noch ungespeicherte Änderungen verloren gehen.
- **Garage** öffnet die rotierende Mountainbike-Vorschau; **Race** öffnet den funktionierenden Testmodus. **Pets/Worlds/Upgrades** sind klar bezeichnete Vorschauen ohne Käufe oder Belohnungen.

**Manuelle Abnahme, noch nicht ausgeführt:** Play/Mehrspieler in Roblox Studio; Script Analysis im Studio-Projekt; Device Emulator auf iPhone/iPad in Hoch-/Querformat (Joystick, Jump, Tap, Safe Areas); reale ProximityPrompts, Character-Physik, Respawn und HUD; echte DataStore-/Throttling-/Shutdown-/Mehrserver-Integration. CLI-Tests und Roblox-API-Typprüfung ersetzen diese Laufzeitprüfungen nicht. Für eine schnelle Rebirth-Prüfung kann ausschließlich in der separaten Test-Experience ein Server-Debugger-Haltepunkt in der Trainingstransaktion verwendet werden; es existiert kein unsicherer Debug-Schreibremote.

## Lokale Entwicklung

Voraussetzungen für die getesteten CLI-Schritte: Linux x86_64, Python 3, curl und Git. `bootstrap.py` installiert **Luau 0.744**, **Rojo 7.4.4** und **luau-lsp 1.70.1** samt Roblox-Typdefinitionen vom selben Tag nach `.tools/`. Alle Downloads stammen aus den jeweiligen offiziellen GitHub-Releases/Quellrepositorys; HTTPS-Verifikation bleibt aktiv. Keine API-Schlüssel erforderlich.

```sh
git clone https://github.com/Eliaaaaas/BikeEvolutionSimulator.git
cd BikeEvolutionSimulator
git switch feat/phase-2-training-world
python3 tools/bootstrap.py
python3 tools/test.py
mkdir -p build
.tools/rojo build default.project.json --output build/BikeEvolutionSimulator.rbxlx
# Optional: mit Rojo Studio Plugin 7.4.4 in einer separaten Test-Experience synchronisieren
.tools/rojo serve default.project.json
```

Auf Windows/macOS kann direkt das CI-Artifact geöffnet werden. Für Quellcodeentwicklung dort die entsprechenden offiziellen Tool-Releases installieren; `aftman.toml` pinnt Rojo. Das Bootstrap-Skript ist für Linux x86_64 ausgelegt. Der Build enthält die Insel bereits als Studio-Objekte; sie wird nicht erst beim Spielstart aus einem externen Modell geladen.

## Struktur

| Pfad | Aufgabe |
| --- | --- |
| `default.project.json` | Client/Server/Shared, Workspace mit World1, tropisches Licht |
| `src/world/World1.rbxmx` | Vollständige editierbare Insel aus eingebauten Roblox-Parts |
| `tools/build_world.py` | Deterministischer Generator der Map; nach Änderungen ausführen und Asset committen |
| `src/shared/Config.luau` | Regeln, Grenzen, vorläufiges Balancing und Netzwerk-Cooldowns |
| `src/shared/Catalog.luau`, `CatalogMetadata.luau` | 8 Welten, 40 Fahrzeuge, 40 Laufbänder, 24 Eier, 96 Pet-Arten und offene Inhalte |
| `src/shared/Numbers.luau`, `Rules.luau` | Sichere Zahlenarithmetik, Rebirths und Laufband-/Kauf-/Fusionsregeln |
| `src/shared/TrainingController.luau`, `RateLimiter.luau` | Testbare serverseitig instanziierte Trainingslogik und gemeinsame Spam-Grenze |
| `src/server/GameplayService.luau` | Live-Charakter-/Abstandsprüfungen, Prompts und automatischer Takt |
| `src/server/PlayerDataService.luau` | Serverseitiger Profilbesitz und validierte Copy/Commit-Transaktionen |
| `src/server/Persistence.luau`, `SavePolicy.luau` | UpdateAsync, Locks, Autosave, Disconnect-/Shutdown-Recovery |
| `src/server/RemoteService.luau`, `src/shared/Protocol.luau` | Begrenzte, validierte Intent-Remotes und eigene Snapshots |
| `src/client/UI.luau`, `init.client.luau` | Mobile Oberfläche, Vorschauen, Rebirth-Bestätigung, serverbasierte Anzeigen |
| `tests/` | Bestehende Phase-1-Tests sowie Training-, Lifecycle-, Sicherheits- und Map-Prüfungen |

## Insel und Inhalte

World1 hat eine unregelmäßige, etwa 180 × 180 Studs große Gras-/Sandkontur mit komplett gleicher Grasoberhöhe. Palmen, Felsen, Wasserfall-Geometrie und Wasser umgeben die begehbare Fläche. Trainingsreihe hinten, Race-Zone vorne, Garage/Eggs/World-Portal seitlich. Ein 20 Studs breiter Platz in der Trainingsmitte ist ausdrücklich für spätere Premium-Laufbänder reserviert und noch nicht nutzbar. Es werden keine kostenpflichtigen oder externen Mesh-/Textur-/Modellassets benötigt. Wasser und Wasserfälle sind dekorative Parts, keine Schwimmsimulation oder animierten Flüssigkeiten.

Die Map bleibt über `src/world/World1.rbxmx` im Studio editierbar. Für reproduzierbare Änderungen den Generator anpassen und `python3 tools/build_world.py` ausführen. Die Tests prüfen die generierte Quelldatei sowie flache Höhe, Inselgröße, Spawn, fünf Trainingszonen, Vorschau-Orte und Premium-Abstand.

## Regeln und noch offenes Balancing

- Laufband `i`: Basisimpuls `2^(i-1)`. Benutzung kostet kein Cash. Jeder Impuls erfordert **Weltbesitz UND (aktuelle Energy ≥ EnergyRequirement ODER Rebirths ≥ RebirthRequirement)**. Die Berechtigung wird nicht dauerhaft gespeichert.
- Laufband 1: Anforderungen 0/0. Noch nicht festgelegte Basisanforderungen sind provisorisch in Config: Laufband 2 = 1 Energy/1 Rebirth; danach Faktoren 4 und 3. Phase 2 nutzt ausschließlich IDs 1–5 in Welt 1; der Katalog hält weiterhin 40 Laufbänder mit 5 pro Welt vor.
- Training: `Basisimpuls × (1 + Rebirths × 0,5)`. Automatische Impulse und manuelle Klicks haben unabhängige Cooldowns. Keine Offline-/Nachholbelohnungen; bei längeren Serverframes gibt es keine Belohnungsbursts.
- Rebirth benötigt aktuell `1000 × (Rebirths + 1)` Energy. Diese Schwelle ist weiterhin vorläufig, zentral konfiguriert. UI-Bestätigung ist eine Bedienabsicherung; die tatsächliche Berechtigung entscheidet immer der Server.
- Cash wird in dieser Phase weder erzeugt noch ausgegeben. Vorhandene Guthaben bleiben erhalten. Weitere Welten bleiben ausschließlich mit Cash freischaltbar; Bikes unabhängig von Welten kaufbar, sobald die späteren Kaufsysteme existieren.
- Fahrzeugklassen: IDs 1–6 Fahrräder, 7–15 Mopeds, 16–27 Motorräder, 28–34 Supersportler, 35–40 Rennmaschinen. 24 Eier, 96 Pet-Arten, 3 Equip-Slots; Fusion 5 identische normale Pets → Golden, 3 identische Golden-Pets → Rainbow. Dies bleibt getestete Infrastruktur, ohne neue Pet-Spielsysteme.
- Individuelle Namen, Raritäten, Multiplikatoren und Design-Metadaten werden pro stabiler ID in `CatalogMetadata` gepflegt. Unbekannte Felder bleiben `false`/`Pending`. Bestehende Preise, IDs und Zuordnungen wurden nicht durch neue Fantasiewerte ersetzt.

## Sicherheit und Persistenz

Client-Aktionen enthalten nur Version und Intent (`Select`, `Click`, `Stop`, `Rebirth`, `StartRace`, `AbortRace`), bei Auswahl eine ID 1–5. Zusätzliche Felder (Energy, UserId, Position, Betrag usw.) werden abgelehnt. Die echte Identität liefert Roblox. Ein gemeinsamer Token-Bucket begrenzt Prompts und RemoteEvents auf 12 Burst-Anfragen und 8 neue Tokens/Sekunde; zusätzlich gelten aktionsbezogene Cooldowns. Negative Rückmeldungen sind begrenzt; Spam wird ohne Antwort fallen gelassen. `GetSnapshot` bleibt auf eine Anfrage/Sekunde begrenzt. Schreibversuche an den Server→Client-Events haben keinen Handler.

Der Server prüft ein lebendes Charaktermodell, die ausgewählte Trainingszone, horizontale Belt-Grenzen plus 1 Stud Toleranz und höchstens 6 Studs Höhenabweichung. Weglaufen, Tod und verlorener Zugang stoppen die Auswahl. Keine vom Client angegebenen Mengen, Zeiten oder Weltrechte werden übernommen. Roblox-Charakterbewegung ist teilweise clientgesteuert: dies ist kein vollständiges Anti-Teleport-/Anti-Cheat-System, die Belohnungsrate bleibt aber auch bei Positionsmanipulation serverseitig begrenzt.

Die serverseitige `change`-API prüft Lease, Player-Zugehörigkeit, Closing-/Saving-Status, erstellt eine isolierte Kopie, validiert das Resultat und übernimmt es atomar. Ungültige/fehlgeschlagene Transaktionen haben keine Teilwirkung. Trainingsaktionen können während eines laufenden Saves kurzfristig mit `Saving` abgelehnt werden; es gibt dann keine nachträgliche Belohnung. Vor Disconnect wird der Profilzustand für weitere Änderungen gesperrt. Shared-Module sind öffentlich lesbar; nur die serverseitige Instanz mit echtem Datenservice hat Autorität.

**Keine Bestandsmigration:** Store `BikeEvolution_Player_v1`, Schlüssel `Player_<UserId>` und Schema v1 bleiben unverändert. Energy/Cash/Rebirths und vorhandene Inventare werden regulär weitergeladen; es gibt keinen Rejoin-Reset. Session-Locks, UpdateAsync, Autosave alle 60 Sekunden, Lease von 180 Sekunden und bis zu 3 Backend-Versuche mit 2/4 Sekunden Pause bleiben erhalten. Höhere/unbekannte oder beschädigte Schemas werden nicht durch Defaults ersetzt.

Vorübergehende Autosave-Ausfälle behalten den In-Memory-Stand für weitere Versuche. Disconnect-Recovery wiederholt bis zur Lease-/Shutdown-Grenze. Beim Shutdown beträgt das Startfenster 24 Sekunden, der äußere Wait maximal 25 Sekunden. Alte Sitzungen dürfen nach Lease-Übernahme keine neueren Daten überschreiben. WriteId-Belege erkennen verlorene Release-Bestätigungen auch über Retry-Batches. `[BikeData]`-Logs enthalten Schlüssel/Versuch/Fehler, keine Profilinhalte.

**Verbleibende Risiken:** Bei hartem Serverabsturz kann BindToClose ausbleiben. Änderungen seit dem letzten bestätigten Save können verloren gehen; laufende DataStore-Aufrufe lassen sich nicht abbrechen. Dauerhafte Plattformausfälle verhindern eine garantierte Speicherung. Nach fehlgeschlagener Freigabe kann Rejoin bis zum Lease-Ablauf blockiert sein. Für Live-Betrieb fehlen Lasttests und ein Admin-/Backup-Recovery-Werkzeug. Während der Entwicklung wurden ausschließlich In-Memory-Teststores verwendet, keine produktiven Daten gelesen oder geändert.

## Zahlen und Prüfstand

`Numbers` definiert zentral Energy/Cash bis 1e300 und ganzzahlige Rebirths bis 9007199254740991 (`2^53−1`). Config, Profilvalidierung und Rebirth-Regeln verwenden dieselben Grenzen. Addition/Multiplikation sättigen endlich; NaN/Unendlich sind ungültig. Oberhalb `2^53` sind Energy/Cash als IEEE-754-Doubles nicht mehr auf jede einzelne Einheit genau. Rebirth-Zähler bleiben exakt inkrementierbar; am Maximum ist kein weiterer Rebirth erlaubt.

Der Test-Runner führt alle bisherigen Tests weiter und ergänzt Training, Klick-Cooldowns, Belt-Abstände, Payload-Manipulation, Spam-Budget, Rebirth-Zugangsverlust und Persistenz nach Training/Rebirth/erneutem Beitritt. **74 Luau-Tests bestehen** (35 Regeln/Persistenz, 9 Profil-Lifecycle, 12 Training/Sicherheit, 14 Phase-2.1-Regeln, 4 echte RaceService-/BikeRig-Adaptertests mit Engine-Doubles), zusätzlich deterministische Map- und XML-Strukturprüfungen. Alle Produktionsdateien werden mit Luau kompiliert. Reine Module werden im Strict-Modus geprüft; **luau-lsp analysiert zusätzlich den gesamten Client-/Servercode mit Rojo-Sourcemap und gepinnten Roblox-API-Typen**. Gefundene Syntax-/Typfehler wurden behoben; der abschließende Lauf und der Rojo-Build sind erfolgreich.

LSPs Hinweis zur fehlenden Dateiwatch-Registrierung betrifft nur den CLI-Modus, nicht die Analyse. Nicht verifiziert sind die oben aufgeführten Studio-/Geräte-/Live-Integrationsprüfungen. Insbesondere ist „Build erfolgreich“ kein Nachweis eines durchgeführten Studio-Playtests.


## Sidebar, Trainingseffekte und Einstellungen testen

1. Links die farbigen Energy-/Cash-/Rebirths- und Navigationsbuttons prüfen. Auf Smartphones startet die Sidebar kompakt; ☰ klappt sie auf. Auf kleinen Bildschirmen scrollt die Liste bei voller Touch-Zielgröße, statt alle Buttons winzig zu skalieren. Safe Areas und Platz für Joystick/Jump werden berücksichtigt. Auf PC Hover, Klick-Aufleuchten und aktive Kontur prüfen.
2. **Energy** öffnet aktuelles Laufband, tatsächlichen Impuls, nächstes Laufband, fehlende Energy, alternative Rebirth-Anforderung und Fortschrittsbalken. Zugang erfordert weiterhin die jeweilige Welt; die fünf aktuellen Laufbänder gehören zu Welt 1.
3. Auf einem Laufband trainieren. Nur nach einer **serverbestätigten Änderung** erscheinen Energy-Zahlen. Der Anzeige-Formatter nutzt K/M/B/T/Qa/… und danach wissenschaftliche Notation (z. B. 1.5K, 250K, 1M). Gespeicherte Zahlen werden nicht umformatiert. Höchstens sechs Popups leben gleichzeitig.
4. **Rebirths**: aktuelle Rebirths, ×1 → ×1,5 usw., benötigte Energy und Balken prüfen. Bestätigen oder abbrechen. Nach bestätigtem Rebirth erscheint kurz der neue Multiplikator; wiederholte Feedback-IDs lösen keinen zweiten Effekt aus.
5. **Settings**: Animationen, Energy-Popups und Sounds jeweils aus-/einschalten, Lautstärke verändern und Sidebar umschalten. Änderungen wirken sofort; sie werden ausschließlich in dieser Sitzung gehalten, nicht ins Profil geschrieben. Animationen aus stoppt auch Garage-Rotation und prozedurale Avatar-/Bike-Effekte; die autoritative Rennfahrt läuft weiter.
6. Training verlassen und erneut aufnehmen: prozedurale Laufbewegung startet/endet weich, ohne Animation-Asset und ohne zusätzliche Belohnung. R15- und R6-Avatare getrennt prüfen.

## Mountainbike-Test-Rennen starten

1. **Garage** zeigt Mountainbike, ID 1, kostenloses und ausgerüstetes Startbike. Das eigentliche 3D-Modell liegt schon in der Place unter `ReplicatedStorage/Vehicles/Mountainbike`: offener Rahmen, zwei Räder mit Profilsegmenten/Felgen/Speichen, Gabel, Lenker mit Griffen, Sattel, Kurbeln und Pedale. Kein kostenpflichtiges Modell und kein VehicleSeat.
2. Zur Race-Zone vorne bei `(0, 8, 63)` gehen. **Race → Mountainbike-Test starten** oder den ProximityPrompt verwenden. Start aus der Ferne muss abgelehnt werden. Die Brücke verbindet Insel und externe Strecke; Start-/Ziellinien und Streckenmarkierungen sind in Studio sichtbar.
3. Bike wird bereitgestellt, Fahrer positioniert, drei Sekunden Countdown. Danach automatische Beschleunigung und Führung entlang der etwa 800 Studs langen Kurve. **Keine Gas-/Brems-/Lenksteuerung.** Die provisional konfigurierte Geschwindigkeit beträgt `24 + min(28, log10(1+Energy)*4)` Studs/Sekunde, also 24–52, ausschließlich vom Server aus dem Profil beim Start berechnet.
4. Räder und Pedale müssen geschwindigkeitsabhängig laufen und im Countdown stillstehen. Lenker und Rahmen neigen sich dezent in Kurven. R15 nutzt prozedurale Hand-/Fuß-IK; R6 eine einfachere Gelenkpose. Eine gemeinsame lokale Animationsverbindung ist nur bei nahen aktiven Avataren/Bikes oder geöffneter Garage aktiv. Entfernte Avatare über 230 Studs werden visuell ausgelassen.
5. Vor dem Ziel bremst das Bike ab und hält kurz an; danach verschwindet es, Spieler steht bei `(0,12,50)` wieder auf der Insel, WalkSpeed/AutoRotate/PlatformStand/Anchored werden auf die vorherigen Werte gesetzt. **Energy und Cash sind unverändert**; es gibt keine Bots und keine Belohnung. Während des Rennens werden Training und Rebirth abgelehnt.
6. **Race → Rennen abbrechen**, Charaktertod, Respawn/Disconnect und zwei gleichzeitige Spieler separat prüfen. Mehrfachstart derselben Person ist gesperrt, erneuter Start hat 2 Sekunden Cooldown. Fehler/Timeout führen zur Rücksetzung; bei Tod wird nicht versucht, den toten Charakter zu teleportieren. Laufende Rennen/ausgewählte Trainingsgeräte sind sitzungsbezogen, nicht Teil des DataStores.

## Neue Module und Asset-Pflege (2.1)

| Pfad | Aufgabe |
| --- | --- |
| `src/shared/Format.luau`, `Presentation.luau`, `ClientState.luau` | Anzeigeformat, Fortschritt/Rebirth-Vorschau, reine sitzungsbezogene Settings-/Dedup-Regeln |
| `src/client/Icons.luau`, `UI.luau` | Eigene Part-/Text-Widget-Icons ohne externe Bilder, animierte Sidebar, Dialoge und Garage-Viewport |
| `src/client/Audio.luau`, `Effects.luau` | Begrenzte Sound-/Popup-Pools; Effekte nur aus bestätigten Serverereignissen |
| `src/client/AvatarPose.luau`, `Visuals.luau` | Prozedurale Avatar-IK/Gelenkpose, Wheels/Pedals/Steering/Lean, gemeinsame bedarfsgesteuerte lokale Schleife |
| `src/models/Mountainbike.rbxmx`, `src/shared/BikeRig.luau` | Vollständige Bike-Geometrie und fünf Motorgruppen mit verschweißten Teilen |
| `src/world/TestCourse.rbxmx`, `CourseData.luau`, `RaceCourse.luau` | Statische Strecke und identische generierte Führungspunkte, binäre Distanzsuche |
| `src/shared/RaceController.luau`, `src/server/RaceService.luau` | Testbare Rennzustände und echte serverseitige Bewegungs-/Rücksetzungsadapter |
| `tools/build_race_assets.py` | Deterministischer Generator von Bike, Strecke und CourseData; `--check` prüft Drift |
| `tests/phase21.spec.luau`, `race_lifecycle.spec.luau`, `race_assets_test.py` | Neue Anzeige-/Renn-/Adapter- und Assetprüfungen |

Nach Änderungen am Asset-Generator `python3 tools/build_race_assets.py` ausführen und alle drei erzeugten Dateien committen. Rennstatus, visuelle Winkel, temporäre Bikes und Settings verwenden **kein neues DataStore-Schema**. Startfahrzeug 1 war bereits in jedem gültigen Profil vorhanden; nur sein explizit vorgegebener Katalogname Mountainbike wurde ergänzt.

## Audioquellen und überprüfte Grenzen

Sounds verwenden ausschließlich die mit Roblox ausgelieferten lokalen Ressourcen `rbxasset://sounds/volume_slider.ogg`, `action_jump.mp3`, `action_jump_land.mp3` und `action_get_up.mp3`. Dateinamen wurden im Client-Manifest [Roblox-Client-Tracker, Revision a020070](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/a020070e2758a71b5d61cf692eee3704a5793011/rbxManifest.txt) nachgewiesen. Es werden keine Audio-IDs erfunden und keine Audiodateien weiterverteilt. Cues haben unterschiedliche Lautstärke-/Pitch-Einstellungen und eine begrenzte Lebensdauer. Die tatsächliche Wiedergabe auf Desktop/iOS muss in Studio/Client geprüft werden; das Manifest ist kein Hörtest.

**Automatisiert geprüft:** alle bisherigen Tests, Formatierung, Settings/Sidebar-Zustandsdaten, Fortschritts-/Rebirth-Vorschau, erlaubtes Startbike, Kurslänge und Führung, Rennstart/Ziel/Abbruch/Timeout/Mehrfachstart, parallele Zustände, unveränderte Währungen und dedupliziertes Belohnungsfeedback. Die echten BikeRig-/RaceService-Funktionen laufen zusätzlich mit Engine-Doubles und prüfen Motoraufbau, Rücktransport, Steuerungswiederherstellung und Aufräumen sogar bei entferntem RootPart (dann wird ein sicherer Charakter-Respawn angefordert). Diese Doubles bilden CFrame-Translation ab, keine Roblox-Physik oder IK. Syntax, Pure-Luau- und Roblox-API-Typprüfung sowie Rojo-Build bestehen. Während der Implementierung gefundene Syntax-/Optionalwertfehler wurden korrigiert.

**Noch nicht in Roblox Studio getestet:** tatsächliche Spielbarkeit/Rendering, iPhone-/iPad-/Windows-Layout und CoreGui, Audio, R15-IK- und R6-Körperhaltung, Sitz-/Hand-/Fußkontakt bei verschiedenen Avatargrößen, Default-Animate-Übergänge, reale Motor6D-Replikation/Netzwerklatenz, Kamera, Mehrspielerlast und echte DataStore-Integration. Vollständige Studio-Abnahme ist vor Merge nötig. Die Fahrt ist absichtlich servergesteuerte Kinematik, keine physikalische Fahrrad-/Kollisionssimulation. R6 hat keine getrennten Knie/Ellenbogen; dessen Bewegung ist stilisiert und erreicht nicht die R15-IK-Genauigkeit. Ungewöhnliche R15-Körperproportionen benötigen gegebenenfalls Pose-Tuning. Es existiert kein vollständiges Anti-Teleport-System; Rennwährungen bleiben aber unverändert und Trainingsraten begrenzt.
