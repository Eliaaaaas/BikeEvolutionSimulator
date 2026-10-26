# V4.1 — Permanentes Fahrrad-/Moped-System

Diese verbindliche Erweiterung ersetzt sämtliche älteren Regeln, nach denen Spieler außerhalb eines Rennens laufen oder beim Training ein zweites Fahrrad erhalten. Branch und Draft PR #2 bleiben erhalten. Keine Merges, kein Roblox-Publish und keine produktiven DataStore-Aufrufe.

## Ein Modell für alle Zustände

`MountedBikeService` erzeugt und verwaltet genau ein Spieler-Bike in `Workspace.PlayerBikes`. `ActiveVehicle` und Besitz stammen aus dem bestehenden Profil. Ein Modellwechsel wird vollständig vorbereitet, bevor das vorherige Modell entfernt wird; der Avatar wird dabei nicht zum Fußgänger. `PermanentRiderMount` bindet das Bike an den verankerten HumanoidRootPart. Fußbewegung, AutoRotate und Sprung sind gesperrt. Serverseitige Sitzpose und deaktivierte Standard-Laufanimation bleiben auch ohne optionale Client-Effekte bestehen. Nachgeladene Körperteile/Motoren werden über DescendantAdded ebenfalls berücksichtigt.

Beim noch nicht abgeschlossenen Profil-Load dient das kostenlose Startbike ausschließlich als Ladeschutz. Eingaben bleiben bis zur Profilbereitschaft gesperrt; danach wird sofort das tatsächlich ausgerüstete Fahrzeug übernommen. Dieser vorläufige Zustand schreibt keinen Fahrzeugwert ins Profil zurück. Respawn verwendet erneut das persistierte aktive Bike. Tod und CharacterRemoving räumen alte Modelle/Verbindungen auf; sie sind keine normalen Fahrzustände.

`Visuals` verwendet das permanente Modell und die vorhandene gemeinsame Wheel-/Steering-/Crank-Architektur. Die Erzeugung von `LocalTrainingCycles` und separaten Trainingsrädern wurde entfernt. R15-Hände/Füße folgen Lenker/Pedalen beziehungsweise Fußrasten über lokale IK; R6 erhält die bestehende approximierte Motorpose. Die notwendige Sitzpose bleibt bei ausgeschalteten Animationen aktiv. Am ungeprüften Avatar-Kontakt für ungewöhnliche R15-Skalierungen und R6-Proportionen bestehen weiterhin manuelle Abnahmepunkte.

## Manuelle Inselsteuerung und Sicherheit

`BikeInput` liest die standardmäßigen Roblox-PlayerModule-Eingabevektoren. Dadurch werden WASD/Pfeiltasten und der native mobile Thumbstick verwendet: vorwärts/rückwärts, lenken. Leertaste/Shift sowie ein eigener Touch-Button bremsen; Rückwärtsfahrt ist auf 35 % begrenzt. Menüs, Textfelder, Fokusverlust, noch fehlendes Profil und Rennen senden neutralen Bremszustand. Beim GUI-Abbau werden Bremseingabe und Verbindungen aufgeräumt.

Der neue `Drive`-Remote akzeptiert ausschließlich Version, monotone Sequence, Throttle/Steer in [-1,1] und Brake. NaN/Infinity, zusätzliche Felder, Wiederholungen, fremde Identität, Positionen und Geschwindigkeiten werden verworfen. Ein eigener Token-Bucket (20 Burst/15 pro Sekunde) schützt die Steuerung, ohne Trainings-/Ökonomie-Limits zu beanspruchen. Der Client sendet höchstens regulär 10 Zustände pro Sekunde; er übermittelt weder Belohnungen noch Positionsfortschritt. Fehlende gültige Eingaben bremsen nach 0,45 Sekunden automatisch.

`BikeMotion` integriert Beschleunigung/Bremsen/Lenken mit Serverzeit und begrenzten Zeitschritten. Zentrale neue Mobilitätswerte liegen in `Config.Bike`: 18 Studs/s × bestehender Fahrzeugfaktor, maximal 30 Studs/s. Das ist ausschließlich Inselmobilität; die bisherigen Renn- und Energy-Formeln bleiben unverändert. Der Server aktualisiert mit 20 Hz. Es gibt keine clientseitig autorisierten Teleports oder physikalische Network-Ownership des Fahrers.

Drei Bodenstrahlen prüfen Mitte sowie Vorder-/Hinterrad-Unterstützung; fehlender Boden oder ein Höhensprung über 1,6 Studs stoppt die Bewegung. Ein konservativer 7,8 × 5,8 × 7,8-Studs-Blockcast prüft die Karosserie/Fahrerfreiheit über der Bodenfläche, sodass zugängliche Laufbanddecks befahren werden können. Charakter-/eigene Bike-Teile werden ausgeschlossen. Diese Kinematik ist keine Rad-/Federungsphysik und simuliert keine gegenseitigen Fahrrad-Crashs. Reale Blockcast-/Raycast-Ergebnisse und Fahrkomfort sind noch in Studio zu prüfen.

Ein Fehler in einer Bewegungsabfrage bleibt nicht unbemerkt: `BikeState`/`BikeError` erscheinen in der bestehenden Diagnoseanzeige, Fehlerprotokolle werden bis zur Erholung begrenzt. Das Modell bleibt währenddessen montiert. In normalen Servern wird nur die allgemeine Fehlermeldung angezeigt; Details bleiben dem Diagnosemodus vorbehalten.

## Training und Rennen

Laufbandzugang bleibt Welt UND (aktuelle Energy ODER Rebirths), mit unveränderten Stärken und Boni. Betreten startet automatische Impulse; gültige Bildschirm-Taps ergänzen sie. Nur das vorhandene Bike erhält beim Training die Pedal-/Fahranimation. Verlassen beendet die Trainingsauswahl, nicht die Montage. Mopeds behalten Fußrasten und erhalten keine Pedalrotation.

`RaceService` übernimmt exakt das existierende Modell über den Mounted-Service. Fünf Bots behalten separate Rennmodelle. Während Countdown/Rennen sind manuelle Drive-Eingaben unwirksam. Der Server führt dasselbe Bike über die bisherige 800-Studs-Strecke. Der visuelle Raddistanz-Zähler bleibt über den Übergang erhalten. Nach Finish/Abbruch wird die manuelle Steuerung zurückgegeben und derselbe Fahrer samt Bike zur Insel bewegt. Es gibt keine GettingUp-/Absteigphase und kein Löschen des Spieler-Bikes beim regulären Rennende. Technischer Verlust des RootParts veranlasst weiterhin einen kontrollierten Respawn.

Energieverbrauch, Bot-Tempi, Platzierungen, Reward-Receipt und Cash-Auszahlung wurden nicht geändert. Disconnect/Shutdown räumen die Bots auf; ein nicht abgeschlossenes Rennen erhält keinen Reward.

## Geschlossene Garage mit automatischem Halbkreis

Der bestehende Garage-Bereich enthält nun Rück-/Seitenwände, Dach, eine geschlossene Glasfront mit Sockel und die zehn sichtbaren Ausstellungsmodelle. Der bunte Halbkreis liegt davor zur Inselmitte hin (+X). Seine unsichtbare `EntryZone` ist die maßgebliche Geometrie; der Server prüft die tatsächliche Halbkreisform und Höhe alle 0,2 Sekunden. Ein Eintritt öffnet Garage genau einmal. Manuelles Schließen führt nicht zum Wiederöffnen, solange der Bereich nicht verlassen und neu befahren wird. Es existiert kein Garage-E-Prompt. Der linke Garage-Button bleibt erhalten. Fahrzeugkäufe/Ausrüsten werden unverändert serverseitig validiert.

## Daten und Schema

Keine Schemaänderung/Migration. `ActiveVehicle`, Besitz, Energy/Cash/Rebirths, Pets und ihre Boni verwenden die bestehenden Felder. Montage, Bewegungsinputs und Race-/Trainingszustände sind flüchtig. Session-Locks, Autosave, kontrollierte Save-Retries und BindToClose-Verfahren bleiben unverändert. Alle Prüfungen verwenden Engine-Doubles beziehungsweise isolierte In-Memory-Stores; keine produktiven Daten wurden gelesen oder verändert.

## Prüfungen und Zwischenfehler

`python3 tools/test.py`: **157 Luau-Tests**, darunter fünf neue reine Bewegungs-/Remote-/Halbkreisprüfungen und **32 tatsächliche Runtime-Verdrahtungstests**. Elf zusätzliche Runtime-Fälle prüfen Spawn, Fahrzeugwechsel/Respawn, PlayerModule-Vektoren/Bremsen/Menüs, Kollision/Boden/Höhenstufen, Timeout/Replay, Garage-Latch, Training/Taps, unveränderte Modellidentität beim Rennen, Hatch/Pets bei deaktivierten Animationen, sichtbare Fehler/Erholung und Disconnect ohne Auszahlung. Fünf bestehende Race-Adapterfälle wurden an die neue permanente Montage angepasst, einschließlich technischem Root-Verlust und Shutdown.

Bestehende sechs V4-Geometrieprüfungen, alle bisherigen Luau-Suiten, deterministische Generatoren, tatsächliche Built-Place-Integration, Syntax-/Strict-/Roblox-Typprüfungen und Rojo-Build bleiben erhalten. Die Schilderprüfung verwendet jetzt die lokale Beschriftungsachse, damit auch die zur Inselmitte gedrehte Garage geprüft wird. Built-Place-Checks prüfen neue Module, geschlossene Wände und EntryZone; die Insel enthält 3.201 verankerte Parts.

Zwischenprüfungen fanden zwei konkrete Fehler: Das rohe Fahrzeug-Content verwendet `Speed` statt des Katalogfelds `SpeedMultiplier`; dies wurde im neuen Inselcontroller korrigiert. Der dynamisch von Roblox gelieferte PlayerModule ist im Rojo-Sourcemap nicht enthalten; sein gezielter dynamischer Loader ist nun typisiert, während alle eigenen Dateien weiterhin vollständig analysiert werden. Eine ergänzte Disconnect-Prüfung verwendete zunächst eine abbrechende UpdateAsync-Abfrage im Teststore; deren erwartete nil-Antwort wurde durch eine reine Rückgabe des vorhandenen Fixture-Datensatzes ersetzt. Auch der gespeicherte Cash-/Receipt-Zustand ist damit geprüft. Abschließende Ergebnisse und CI-Link stehen im PR. Kein Studio-Test wird durch Engine-Doubles ersetzt oder als ausgeführt behauptet.

## NICHT AUSGEFÜHRT: echte Roblox-Studio-Abnahme

Hier ist Roblox Studio nicht verfügbar. Es gab keine echte Renderer-/Physik-/Native-Touch-/Kamera-/IK-Abnahme, keine Netzwerk-Latenz-/Lastmessung und keine realen DataStore-Prüfungen. Tests liefern kontrollierte Kollisionsantworten; sie führen nicht die Roblox-Blockcast-Engine aus. Die aktuelle Steuerung verwendet Serverkinematik ohne lokale Bewegungsprognose; Fahrgefühl unter realer Latenz und Framerate muss vor Abnahme gemessen werden.

1. **Spawn und Rejoin:** Build als nicht persistente Studio-Preview starten. Erwartet: unmittelbar montiertes Bike, nach Profilbereitschaft aktives Fahrzeug, kein Laufen/Stehen. In separatem persistentem Testmodus mit anderem aktivem Bike erneut beitreten: genau dieses Modell wird wiederhergestellt.
2. **Alle zehn Fahrzeuge:** Über Garage kaufen/ausrüsten. Erwartet: Modellwechsel ohne bleibendes Absteigen; Fahrrad-/Moped-Proportionen, Sattel-/Hand-/Fußkontakt und Kamera passen. R15-Skalierungen/R6 gesondert prüfen.
3. **Insel:** WASD/Pfeile, Space/Shift, Touch-Stick und Touch-Bremse ausprobieren; beschleunigen, lenken, bremsen, rückwärts fahren. Erwartet: sitzend auch im Stand; keine Fußbewegung/Standard-Laufanimation. Kamera lässt Bike erkennen. Küste, Gebäude, Felsen, Bandkanten und schmale Passagen auf echte Kollisionsprobleme prüfen.
4. **Training:** Alle fünf erlaubten Bänder befahren. Erwartet: dasselbe Bike; automatische Gewinne/Taps und unveränderte Boni; kein zweites Trainingsrad und keine BillboardGui. Verlassen stoppt nur das Training. Mopeds ohne Pedalbewegung.
5. **Garage:** Halbkreis befahren; automatische Öffnung, kein E. Schließen und darin stehen bleiben: kein Wiederöffnen. Heraus-/hineinfahren: genau eine neue Öffnung. Sidebar funktioniert auch außerhalb der Zone.
6. **Menüs/Hatch/Pets/Rebirth:** Alle Menüs öffnen und Eier hatchen, Best Equip/Unequip All sowie Rebirth testen. Erwartet: Fahrer bleibt montiert; offene Menüs bremsen. Energy/Cash/Rebirth-/Pet-Regeln bleiben unverändert.
7. **Rennen:** Easy/Medium/Hard starten. Erwartet: identisches Spieler-Bike, fünf Bots, automatische Führung statt manueller Eingaben, einmalige Auszahlung, ohne Absteigen zur Insel zurück. Danach manuell weiterfahren. Abbruch/Tod/Root-Verlust separat prüfen.
8. **Respawn/Disconnect:** Reset/Tod während Insel/Training/Rennen. Erwartet: altes Modell/Bots verschwinden; neues aktives Bike nach Respawn, keine verwaisten Modelle. Disconnect zahlt kein unfertiges Rennen aus.
9. **Einstellungen/Geräte:** Animationen/Pop-ups aus; Sitzpose bleibt. iPhone/iPad Hoch-/Querformat: sieben Menüpunkte und Bremse ohne Überdeckung, Ressourcen nur unten rechts. Reale Netzwerkverzögerung und mehrere Fahrer/Pets/Bots messen.
10. **Sicherheit/Speichern:** Nur in separater Test-Experience speichern/rejoin/Shutdown prüfen. Keine Änderungen an Produktionsprofilen. Diagnosen/Output auf Fehler kontrollieren; gültige Fortschritte, aktive Fahrzeuge und Pet-Slots bleiben erhalten.

## Vollständiger Build

`python3 tools/package_v4.py --version V4.1` erzeugt `build/BikeEvolutionSimulator-V4.1.zip` mit vollständiger `BikeEvolutionSimulator.rbxlx`, BUILD_INFO und SHA256SUMS. XML-Abschluss, ZIP-CRC und Place-Hash werden geprüft. Actions lädt **BikeEvolutionSimulator-V4.1** zusätzlich zu den bisherigen Studio-/V4-Artifacts hoch und schlägt bei fehlenden Dateien fehl. Der genaue Commit/Workflow-Link wird im Draft PR #2 dokumentiert.
