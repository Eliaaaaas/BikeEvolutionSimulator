# Repository instructions

Bei allen HUD-/UI-Änderungen den verbindlichen Vertrag in
[docs/VISUAL_UPGRADE_V2.md](docs/VISUAL_UPGRADE_V2.md) beachten.

Permanente Energy-/Cash-/Rebirth-Anzeigen stehen ausschließlich unten rechts als
freistehende Icons plus Zahlen ohne Hintergrundboxen, Kacheln oder Rahmen.
Rebirth bleibt über die linke Sidebar zugänglich. Keine physische Rebirth-Station
oder zugehörige Prompt-/Generator-Abhängigkeit wieder einführen.

UI-Regressionen über `python3 tools/test.py` prüfen. Engine-Doubles und erfolgreiche
Rojo-Builds sind keine Roblox-Studio-Abnahme; nicht ausgeführte Studio-Tests klar
kennzeichnen.
