# Repository instructions

Bei allen HUD-/UI-Änderungen den verbindlichen Vertrag in
[docs/VISUAL_UPGRADE_V2.md](docs/VISUAL_UPGRADE_V2.md) beachten.

Permanente Energy-/Cash-/Rebirth-Anzeigen stehen ausschließlich unten rechts als
freistehende Icons plus Zahlen ohne Hintergrundboxen, Kacheln oder Rahmen.
Keine PALM-BAY-Kopfzeile, Energy-/Cash-Menükacheln, Sidebar-Hintergrundbox oder scrollende Hauptnavigation. Rebirth bleibt über die linke Sidebar zugänglich. Keine physische Rebirth-Station
oder zugehörige Prompt-/Generator-Abhängigkeit wieder einführen.

Zusätzlich [docs/UI_TRAINING_OVERHAUL_V3.md](docs/UI_TRAINING_OVERHAUL_V3.md) beachten: Training durch Betreten und Bildschirm-Taps, kein Trainingskasten/-button und kein Trainings-E-Prompt.

UI-Regressionen über `python3 tools/test.py` prüfen. Engine-Doubles und erfolgreiche
Rojo-Builds sind keine Roblox-Studio-Abnahme; nicht ausgeführte Studio-Tests klar
kennzeichnen.

V4 hat Vorrang vor historischen V3-Anweisungen: [docs/VISUAL_OVERHAUL_V4.md](docs/VISUAL_OVERHAUL_V4.md).
Keine aktive Trainings-BillboardGui oder TrainingGain-Attributbindung wieder einführen.
Die sieben Sidebar-Menüs heißen Garage, Pets, Race, Worlds, Rebirths, Shop, Settings.
Neue ZIP-Ausgabe heißt BikeEvolutionSimulator-V4; der bestehende Studio-Artifact bleibt erhalten.

V4.1 hat Vorrang: [docs/PERMANENT_BIKE_V41.md](docs/PERMANENT_BIKE_V41.md).
Spieler bleiben in allen normalen Zuständen auf genau einem serverseitig montierten Bike.
Keine Fußsteuerung, keine separaten Trainingsräder und kein Garage-E-Prompt wieder einführen.
Rennen verwenden dasselbe Spieler-Modell; danach wird ausschließlich die manuelle Steuerung restauriert.
Garage öffnet einmal pro Einfahrt in den Halbkreis; neue Ausgabe BikeEvolutionSimulator-V4.1.

V4.2 hat Vorrang: [docs/RIDER_TRANSFORM_V42.md](docs/RIDER_TRANSFORM_V42.md).
Nur die verankerte Fahrzeugwurzel besitzt die gemeinsame Transformation; keine CFrame-Bewegung
auf der unverankerten Fahrerwurzel und keine abgeleitete Bewegungsposition aus Avatar-Offsets.
Explizite Gelenk-C0/C1, PivotOffset und Sattel-/R15-Bindmaße berücksichtigen.
PlayerModule-Eingabesammlung bleibt aktiv; der normale Move-Dispatcher bleibt unterbunden.
Neue Ausgabe BikeEvolutionSimulator-V4.2. Transformationsregressionen dürfen keine Identitätsrotationen vortäuschen.

V4.3 hat Vorrang: [docs/MOVEMENT_TRAINING_V43.md](docs/MOVEMENT_TRAINING_V43.md).
Space/Touch lösen einen servervalidierten Bike-Sprung aus; Shift bleibt Bremse. Avatar-Jump bleibt gesperrt.
Rampen, vollständiger bodenberührender Bike-Footprint und bestehende Zugangsregeln bestimmen Training.
Vorhersage darf nur die isolierte lokale Darstellung bewegen; repliziertes Bike/Avatar bleiben servergeführt.
Neue Ausgabe BikeEvolutionSimulator-V4.3; keine weitere Dekoration im Bewegungsfix.

V4.4 hat Vorrang: [docs/OVERHAUL_V44.md](docs/OVERHAUL_V44.md).
Keine großen Rampen: fünf eingelassene Belt-Oberseiten bei y=8.05. Training benötigt weiterhin Bodenkontakt/Footprint und dieselben Zugangsgates.
Nur RaceCamera besitzt CameraSubject/CameraType; Vorhersage bei Camera−2, Kameraziel bei Camera−1, native Inselkamera danach.
Sidebar bleibt vertikal mittig mit sieben Buttons; Ressourcen ausschließlich rechts unten ohne Boxen, grafische UI-Geometrie statt Unicode.
Schema 3 vor Änderungen in docs/V44_DATA_MIGRATION.md dokumentieren; alte Werte nie zurücksetzen. Premium-IDs 0 bleiben deaktiviert; keine echten Produkte erstellen.
Auto-Navigation bleibt servergeführt, nutzt Kollisionen und erzeugt keine Teleports oder Tap-Impulse. Neue Ausgabe BikeEvolutionSimulator-V4.4.
