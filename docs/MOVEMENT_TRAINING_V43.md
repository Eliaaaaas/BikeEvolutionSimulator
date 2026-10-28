# V4.3 — Laufbandzugang, direkte Steuerung und Bike-Sprung

Die drei in Studio gemeldeten V4.2-Probleme werden zusammen bearbeitet. Keine zusätzliche Dekoration, keine neuen Ökonomie-/Mapsysteme. Der Branch bleibt `feat/phase-2-training-world`; keine Merges und keine produktiven DataStore-Aufrufe.

## Ursachen und Reparaturen

| Befund | Änderung |
| --- | --- |
| Erhöhte Belt-/Deck-Kanten ohne Auffahrrampe; starre Bodenprüfung an drei Punkten; breiter 7,8-Studs-Blockcast konnte Plattformkanten als Hindernis behandeln. | Fünf echte kollidierbare WedgePart-Rampen. Je 9 Studs breit, 11 lang und nur 1,3 hoch: Insel y=8 bis Laufbandhöhe y=9,3. Boden wird unter dem Fahrzeugzentrum mit Höhen-/Normalenprüfung ermittelt. Karosserie- und separate niedrige Chassis-Sweeps prüfen die tatsächliche Fahrrichtung. Flache Rampen und bekannte befahrbare Deck-/Belt-/Plattformkanten werden nicht als Wand behandelt; andere niedrige Hindernisse bleiben blockierend. |
| 100-ms-Eingabepolling, 20-Hz-Serverpositionen und keine lokale Vorhersage; reine Serverreaktion wurde erst nach Netzwerk-Rundlauf sichtbar. | Eingaben mit 30 Hz, Simulation in 60-Hz-Teilschritten; direktere Beschleunigung/Bremse und Lenkung ohne Nachschwingfilter. Eine isolierte lokale Darstellung prognostiziert eigene Eingaben und gleicht sie mit Serverbestätigungen ab. |
| Space war als Bremse belegt; Humanoid-Sprung bewusst gesperrt; keine vertikale Bike-Simulation. | Space und ein eigener Touch-Button lösen einen servervalidierten Bike-Sprung aus. Shift/Touch-Bremse bleiben getrennt. Humanoid-Sprung und normale Sprunganimation bleiben aus; die gemeinsame Fahrzeugeinheit springt über eigene vertikale Simulation. |

## Kollisions- und Trainingsregeln

`BikeSurface` kapselt dieselben Workspace-Abfragen für Server und Vorhersage. `RideSimulation` integriert Bewegung, Schwerkraft, Sprung und Landung. Maximal 1,6 Studs Stufenhöhe und mindestens 0,7 Boden-Normalen-Y schützen gegen unzulässige Steigungen. Die Rampensteigung beträgt etwa 6,7 Grad. Raycasts berücksichtigen kollidierbare Teile und ignorieren eigene Charakter-/Bike-/Darstellungsmodelle. Die niedrige Chassis-Abfrage blockiert unbekannte Wände, auch wenn der obere Karosseriecast darüber hinweggeht. Die Liste bekannter befahrbarer Flächen ist in `BikeSurface` zentral; zukünftige Maps müssen ihre Supportgeometrie entsprechend ergänzen.

Beim Sprung beginnt der Sweep an der bisherigen Höhe und endet an der neuen; die vertikale Bewegung wird nicht doppelt angewendet. Dadurch taucht die Prüfbox bei der Landung nicht versehentlich unter die Bodenoberfläche. Bei einem Kopf-/Wandtreffer stoppt der konservative Sweep; es gibt keine Wandgleit- oder Federungsphysik.

Training prüft jetzt die **autoritative, bodenberührende Fahrzeugposition und beide Radpositionen einschließlich Breitenmarge**, statt nur den Avatar-Root-Abstand. Das ganze Bike muss im erlaubten Bandbereich und höchstens 0,4 Studs von dessen Höhe entfernt sein. Sprungkontakt beendet die serverseitige Berechtigung sofort; UI-Snapshots können erst beim nächsten regulären 0,25-Sekunden-Update reagieren. Nach Landung auf dem Band startet automatische Auswahl wieder. Energy-/Rebirth-Anforderungen, automatische Impulse und validierte Bildschirm-Taps bleiben unverändert. Es gibt keinen E-Prompt und kein zweites Trainingsbike.

Fehlt Boden, fällt das Bike kontrolliert durch Schwerkraft; es wird nicht unsichtbar an der Küste eingefroren. Unterhalb y=-35 wird der Charakter getötet und der normale Respawn verwendet. Dies ist kein belohnter Rennabschluss oder stiller Profilreset.

## Sprung und Eingaben

Zentrale Werte in `Config.Bike`:

- Sprunggeschwindigkeit 28 Studs/s, Schwerkraft 80 Studs/s²: theoretischer Scheitel etwa 4,9 Studs und Flugzeit etwa 0,7 Sekunden auf gleicher Höhe.
- Sprung-Cooldown 0,65 Sekunden und tatsächlicher Bodenkontakt erforderlich.
- Jede neue Space-/Touch-Begin-Aktion erhöht eine monotone JumpId. Eine ID wird auch bei abgewiesenem Luftsprung verbraucht. Halten, Wiederholung eines Pakets oder ein zweiter Druck in der Luft erzeugen keinen zusätzlichen Impuls. Bike-Wechsel in der Luft erhält Vertikalgeschwindigkeit und JumpId.
- Space = Springen, Shift = Bremsen, WASD/Pfeile beziehungsweise nativer Touch-Stick = Fahren/Lenken. Eigener Touch-Sprungbutton unten rechts im reservierten Bedienbereich, Touch-Bremse getrennt links. Menü/Fokus-/Rennsperren bleiben bestehen.
- Normale Humanoid-Fußbewegung und Humanoid-Jump bleiben unterbunden. Fahrer und Sattel folgen weiterhin derselben Rahmenmontage.

## Vorhersage ohne konkurrierende Transformationsautoren

Der Server bleibt alleiniger Besitzer der replizierten Fahrzeugeinheit. Der eigene Client schreibt **keine** CFrames auf das autoritative Bike oder den echten Avatar. Stattdessen zeigt `RidePrediction` genau eine rein lokale Darstellung aus Bike und Avatar; die autoritativen Teile werden nur lokal transparent geschaltet. Andere Clients sehen weiterhin die Servereinheit. Dies ist ein Präsentationsmodell, kein zweites spielbares/ausrüstbares Fahrzeug und kein Trainingsrad.

Beim Klonen werden Scripts, alte IK-Controls und externe IK-Ziele entfernt. Das Darstellungs-Bike stammt aus dem geprüften Fahrzeugasset, nicht aus einem bereits montierten Modell mit externem Fahrer-Weld. Sein neuer Weld bindet ausschließlich den geklonten Fahrer. `Visuals` animiert im Vorhersagemodus dieses Modell und dessen Avatar. Die Kamera folgt dessen Humanoid. Race, Respawn, Wechsel oder GUI-Abbau zerstören/erneuern die Darstellung und restaurieren lokale Transparenz/Kamera; bei fehlenden Bestätigungen wird die Vorhersage nach etwa 0,65 Sekunden beendet.

Die gemeinsame Simulation verwendet feste Teilschritte. `RideReconciliation` entfernt bestätigte Eingaben und spielt unbestätigte Befehle auf dem neuen Serverzustand erneut ab. Epoch/Ack-/Sequenz-Prüfungen verhindern alte Zustände nach Spawn/Bike-Wechsel/Rennen. Der Puffer ist auf 90 Befehle begrenzt. Kleine Darstellungsabweichungen werden sanft korrigiert; explizite Zustandswechsel oder Abstände über 12 Studs werden neu angesetzt. Das ist keine Garantie, dass unter jeder realen Paketverlust-/Streaming-Situation nie eine Korrektur sichtbar wird.

Der Server nimmt nur begrenzte Steuerachsen, Bremse, JumpId, Sequenz und optional Epoch an; niemals Clientpositionen, Geschwindigkeit, verstrichene Simulationszeit oder Rewards. Eine eigene Rate-Begrenzung und maximal acht wartende Eingaben verhindern Vorziehen der Serverzeit durch Spam. Serverbestätigungen kommen mit höchstens 10 Hz. Automatische Rennen verwerfen manuelle Eingaben und verwenden weiterhin die bestehende Rennführung.

## Erhaltene Daten und Spielsysteme

Kein neues persistentes Feld, keine Migration, keine Änderung von Energy/Cash/Rebirth/Pet-Boni, Fahrzeugpreisen oder Race-Rewards. Session-Locks, Autosave und Shutdown-Speicherung bleiben erhalten. Alle automatisierten Profile sind isolierte In-Memory-Fixtures. Keine produktiven Daten wurden geöffnet oder verändert. Nur die Bewegungsparameter Beschleunigung/Bremse/Lenkung, Support-/Sprungzustände und die Präsentation ändern sich.

## Automatisierte Prüfungen

`python3 tools/test.py`: **186 Luau-Tests**, darunter **48 tatsächliche Runtime-Verdrahtungstests**, neun neue reine Simulations-/Vorhersagefälle und die bisherigen Transformations-/Speicher-/Ökonomie-/Pet-/Race-Suiten. Zusätzlich sieben Python-Geometrieprüfungen und die bestehenden deterministischen Asset-/Built-Place-Prüfungen.

Neu geprüft: komplette Anfahrt über die generierte Rampe bis zum automatischen Training, Rampen-/Stufengeometrie, Grounded-/Rad-Footprint, Jump-Physik/Landung und Sweep-Endhöhe, verbrauchter Doppelsprung, Sprung aus Training, native Touch-Begin-Verbindung, ignorierte Renn-Eingaben, Bike-Wechsel in der Luft, begrenzte Serverqueue, tatsächlicher lokaler Präsentationsaufbau ohne CFrame-Schreibzugriff auf die Servereinheit, alter Epoch-Zustand, Wiederaufbau/Transparenz-Cleanup und niedrige Wände gegenüber befahrbaren Decks.

Luau-Kompilierung, Strict-/Roblox-API-Typprüfung und vollständiger Rojo-Build bleiben Pflicht. Die Welt enthält 3.206 verankerte Parts; nur fünf Rampen wurden hinzugefügt. Keine neuen Dekoobjekte.

Zwischenprüfungen fanden erforderliche Typverengungen an Simulationszuständen und beim Queue-Replay. Der Fehlermeldungs-Latch musste bis zum nächsten tatsächlich erfolgreichen Simulationsschritt gehalten werden; Leerticks dürfen ihn nicht zurücksetzen. Ein UI-Regressionstest wartete zunächst nur 0,2 Sekunden auf einen 0,25-Sekunden-Snapshot und wurde mit zusätzlicher Prüfung der sofort unveränderten serverseitigen Energy korrigiert. Die Landungsprüfung sichert ausdrücklich, dass der Sweep seine vertikale Verschiebung nicht doppelt anwendet. Abschließende Resultate und CI-Link werden im Übergabebericht genannt.

## NICHT AUSGEFÜHRT: Roblox Studio und reale Geräte

Diese Cloud verfügt nicht über Roblox Studio. Kein echter Studio-Playtest, echter Workspace-Physiklauf, realer mobiler Touch-/Kamera-/IK-Test oder realer DataStore-Aufruf wurde durchgeführt. Engine-Doubles liefern kontrollierte Kollisionsantworten und führen die echte Verdrahtung/Mathematik aus; sie messen weder echte Framerate noch Roblox-Replikationsverhalten. Die komplette Rampenform ist zusätzlich im tatsächlich generierten Place geprüft.

Manuelle V4.3-Abnahme mit Soll-Ergebnissen:

1. Neuestes V4.3-Artifact/BUILD_INFO prüfen, `.rbxlx` öffnen, Play in nicht persistenter Preview. Genau eine sichtbare Einheit; Diagnose/Output ohne Fehler. Nicht versehentlich V4.2 öffnen.
2. Auf alle fünf Rampen von vorne und schräg fahren, stoppen und rückwärts herunterfahren. Keine unsichtbare Kante; vollständiges Bike steht auf dem Belt. Auto-Energy und Taps funktionieren nur bei erlaubten Energy-/Rebirth-Werten.
3. WASD schnell drücken/loslassen, kleine Lenkkorrekturen und Shift-Bremse bei niedriger/hoher Geschwindigkeit testen. Kein Weiterdrehen im Stand, kein Fußlaufen. Dasselbe mit Touch-Stick/Bremse auf iPhone/iPad Hoch-/Querformat.
4. Space/Touch-Sprung: gemeinsam abheben, auf Sattel bleiben, landen. Halten/mehrfach drücken ergibt keinen Doppelsprung. An Wand/unter Hindernis testen; kein Durchfahren. Vorwärtsfahrt bleibt bei freier Landung erhalten.
5. Vom Belt springen: Training/Bonustaps während des Flugs verweigert. Auf dem Belt landen beziehungsweise daneben fahren: Auswahl kehrt nur bei korrektem Bodenkontakt und erfülltem Zugang zurück.
6. Kamera folgt dem vorhergesagten Fahrer. Original und Darstellung dürfen nicht gleichzeitig doppelt sichtbar sein. Hände/Füße, Frame-Neigung, Mopeds ohne Pedale und ungewöhnliche R15-/R6-Körpermaße separat ansehen.
7. Netzwerkverzögerung/Jitter/Paketverlust im Studio-Emulator aktivieren. Reaktionszeit, Reconciliation-Korrekturen, zeitweise ausbleibende Bestätigungen und Wiederaufnahme messen. Keine Sicherheit aus Client-Vorhersage ableiten; Energy/Cash müssen serverbestätigt bleiben.
8. Easy/Medium/Hard starten/abbrechen/beenden: automatische Führung, keine manuelle Fahrt/Sprünge im Rennen, saubere Rückkehr ohne doppelte Einheit. Rewards und Data-Saving unverändert.
9. Bike-Wechsel am Boden/in der Luft, Tod/Respawn, Menü/Hatch/Pets, GUI-Abbau und mehrere Clients testen. Keine alten Ghosts, IK-Ziele, Transparenzzustände oder Kameraverbindungen zurücklassen.
10. Niedrige Wände, Deckkanten, Rampenübergänge, Geländeabbrüche und echte Performance messen. Persistenz nur in einer separaten Test-Experience prüfen; niemals produktive Profile für Abnahme verändern.

Reale Kollisions-/IK-/Touch-/Netzwerk- und Performance-Abnahme bleibt offen. Der Build ist zur erneuten manuellen Prüfung vorbereitet, nicht bereits als spielbar abgenommen.

## Vollständiger Build

`python3 tools/package_v4.py --version V4.3` erzeugt **BikeEvolutionSimulator-V4.3.zip** mit vollständiger `.rbxlx`, BUILD_INFO mit Commit/UTC und SHA256SUMS. XML-Abschluss, ZIP-CRC und Place-Hash werden verifiziert. Actions lädt **BikeEvolutionSimulator-V4.3** zusätzlich zu den bisherigen Artifacts hoch und schlägt bei fehlenden Dateien fehl. Keine Merges, kein Release-Publish und keine Veröffentlichung auf Roblox.
