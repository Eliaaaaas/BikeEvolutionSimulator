# Visual Upgrade V2 — verbindlicher HUD-Vertrag

Diese Vorgaben gelten für alle weiteren HUD-/UI-Arbeiten an diesem Repository.

- Permanente Energy-, Cash- und Rebirth-Zähler ausschließlich unten rechts: jeweils freistehendes Icon und gut lesbare Zahl daneben. Keine gemeinsame Hintergrundbox, keine Kacheln, keine sichtbaren umgebenden Rahmen. Transparente, rahmenlose Layout-Frames sind erlaubt; sie zeichnen keinen Hintergrund.
- Energy: Blitz. Cash: erkennbare Münze statt Dollarzeichen. Rebirth: klassischer kreisförmiger Rebirth-Pfeil. Dezente Textkonturen sind erlaubt. Der Münzrand ist Teil des Symbols und kein Rahmen um eine Ressourcenanzeige.
- Werte ausschließlich aus serverbestätigten Snapshots; keine optimistischen Cash-/Energy-/Rebirth-Änderungen im Client. Bestehende Zahlenformatierung inklusive K/M/B/T und größerer Größen beibehalten.
- Nur ein permanentes Ressourcen-HUD. Die Sidebar zeigt statische Menünamen/Icons, niemals zusätzliche Ressourcenstände. Situative Voraussetzungen, Multiplikatoren und Vorschauen in geöffneten Menüs bleiben erlaubt.
- Untere rechte Verankerung innerhalb `CoreUISafeInsets`. Auf Touch-Geräten kompakte Schrift/Icongrößen; zusätzlich Platz für Roblox-Touch-Steuerung lassen. Hochformat: oberhalb der Sprungtaste. Sehr niedriges Querformat: links neben der Sprungtaste. Training und situativer Status liegen oberhalb des Ressourcenbereichs und dürfen ihn nicht überdecken.
- Rebirth bleibt als linkes Sidebar-Menü erreichbar: aktuelle/nächste Multiplikatoren, Voraussetzung, Fortschritt, Abbrechen und Bestätigung. Serverseitige Rebirth-Regeln und Daten dürfen für HUD-Arbeiten nicht verändert werden.
- Kein physischer Rebirth-Stand, kein Rebirth-Orb, kein zugehöriger ProximityPrompt. Auch Generator, Runtime-Vertrag, Dokumentation und Build dürfen keine Abhängigkeit von einer solchen Station erhalten.

## Umsetzung und Regressionen

`UI.luau` erzeugt einen transparenten `ResourceHUD` mit drei transparenten Reihen. `Icons.resource()` zeichnet Blitz, Münze und Kreis-Pfeil ohne externe Bild-Assets. `UI.update()` bindet ausschließlich die bestätigten Snapshot-Werte. Beim Ein-/Ausklappen der Sidebar bleiben diese Anzeigen an derselben Stelle; die Sidebar-Texte bleiben statisch.

`tests/runtime_integration.spec.luau` prüft mit der echten UI-/Client-/Remote-Verdrahtung gegen Engine-Doubles: bestätigte Live-Werte/Formatierung, fehlende Hintergründe/Rahmen, keine Sidebar-Duplikate, Touch-Layouts und den vollständigen Rebirth-Menüablauf über echte Button-Callbacks. `world_test.py` und `place_integration_test.py` verhindern die Rückkehr einer physischen Rebirth-Station in Quelle und gebautem Place.

## Manuelle Abnahme: NICHT AUSGEFÜHRT

Roblox Studio ist hier nicht verfügbar. Auf iPhone/iPad/PC prüfen:

1. Unten rechts genau drei freistehende Symbole mit Zahlen; kein Hintergrund und keine Kacheln/Rahmen. Kontrast über Gras, Wasser und Rennstrecke prüfen.
2. Training, Rennen/Cash und Rebirth auslösen: bestätigte Werte aktualisieren sich; Sidebar bleibt frei von Ressourcenständen.
3. Sidebar ein-/ausklappen und Gerät drehen: HUD bleibt kompakt im unteren rechten Bereich, ohne Safe-Area-/Sprungtasten-Konflikt.
4. Rebirth links öffnen: Voraussetzung, Multiplikator-Vorschau, Fortschritt, Abbrechen und Bestätigen prüfen. Abbrechen ändert nichts; bestätigter Rebirth folgt den unveränderten Regeln.
5. Insel im Edit- und Play-Modus prüfen: kein Rebirth-Stand und kein verwaister Prompt; Server startet ohne entsprechende Weltabhängigkeit.
