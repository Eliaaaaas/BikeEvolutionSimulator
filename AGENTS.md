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
