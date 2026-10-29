# V4.5 — Schilder, Laufbänder, Eck-HUD und Auto-Train-Teleport

Arbeitsbranch `feat/phase-2-training-world`, bestehender Draft PR #2. Dieser gemeinsame Build ersetzt die widersprechenden V4.4-Regeln zur Auto-Train-Navigation und zu großen Touch-HUD-Abständen. Kein Merge, kein Roblox-Publish, keine produktiven DataStore-Aufrufe. Das Spiel benötigt weiterhin eine echte manuelle Studio-Abnahme.

## 1. Wiederverwendbarer SignBuilder

Die alte Schildfunktion ist entfernt. `tools/sign_builder.py` enthält den kanonischen **SignBuilder**, den Insel- und Streckengenerator gemeinsam verwenden. Die Ergebnisse sind vollständig editierbare Roblox-Parts/SurfaceGuis im Place; beim Spielstart werden keine doppelten Schilder darüber gebaut.

Konkrete Ursache im bisherigen Generator: `PixelsPerStud` war zwar gesetzt, **`SizingMode` fehlte**. Die feste Standard-Zeichenfläche hatte ein anderes Seitenverhältnis als die langen Schilder. `TextScaled` passte den Text an diese Zeichenfläche statt an eine maßstäbliche Schildfläche an. Die bisherigen geometrischen Textmargen-Tests erkannten diesen Fehler nicht. Das ist eine konkrete Generatorursache; die tatsächliche Darstellung im Roblox-Renderer konnte hier nicht nachgestellt werden.

Neu:

- Dunkle matte Textflächen, abgerundete mehrschichtige Rahmen und abgestimmte Akzente. Nur dünne `EdgeInlay`-Parts sind Neon; keine leuchtende Hintergrundfläche oder Neon-Icons.
- Jede Textfläche trägt ihre eigene SurfaceGui mit **explizitem Adornee**, `SizingMode=PixelsPerStud`, 96 Pixels/Stud, LightInfluence=0, Brightness=1 und normaler Verdeckung (`AlwaysOnTop=false`). Keine unsichtbare, hinter einer anderen Ebene versteckte Textträgerfläche.
- +Z-Fläche verwendet Roblox `Back=2`, −Z-Fläche `Front=5`. Icons stehen auf beiden Ansichtsseiten links; die Rückseitenanordnung wird gespiegelt. Die BIKE-SHOP-Vorderseite wird mitsamt GUI/Icons nach +X zur Insel gedreht und liegt vor Glasfront/Dachkante.
- Große weiße skalierte Schrift mit dunkler Kontur, definierte Innenränder, ZIndex=2, kein Wrapping oder Clipping. Die natürliche Glyphenmessung wird nicht durch erfundene `TextBounds`-/`TextFits`-Werte ersetzt.
- BIKE SHOP: Dunkelblau/Gold/Bike; TRAINING: Dunkeltürkis/Orange/Blitz; RACE: Dunkelrot/Gold/Flagge; EGGS: Dunkelviolett/Pink/Ei; WORLDS: Dunkelblau/Türkis/Portal; VIP: dunkler Grund/Gold/Krone. Alle Icons bestehen aus selbst erzeugter Geometrie mit anliegender Medaillonbasis.

`src/client/SignReadability.luau` prüft im Studio-/privaten Diagnosemodus echte `TextBounds` und `TextFits`, sobald Messwerte vorhanden sind. Noch nicht gerenderte Flächen werden ausdrücklich als **pending** gezählt, nicht als erfolgreich vermessen. `BikeRuntime.SignDiagnostics`/`SignError` und Output zeigen den Status. Die Diagnose ist eine Momentaufnahme; weit entfernte/gestreamte Schilder sind zusätzlich manuell zu prüfen. Das Diagnoseband liegt unter den Auto-Schaltern, damit es diese nicht verdeckt.

## 2. Rechteckige Fahrrad-Trainingslaufbänder

Alte Neon-Ovale, PowerArms, EnergyFins, PowerCores und Orbitteile sind aus Generator **und** zugehöriger Effektlogik entfernt.

Fünf gleich ausgerichtete eingelassene Geräte: rechteckiges Deck, dunkler Fabric-Gurt (8×12 Studs, Oberseite y=8.05 bei Insel y=8), sichtbare Metallrollen vorne/hinten, symmetrische Seitenrahmen, Endverbinder, Gehäuse und Befestigungen. Türkis/Blau/Grün/Orange/Violett erscheinen ausschließlich als kleine Seitenakzente. Der Gurt hat dezente bewegte Quernähte statt einer vollflächigen Neontextur. Keine großen Rampen, schiefen Stangen, Geräteüberschneidungen oder Ersatzplatten. Der Premium-Mittelbereich bleibt frei.

Nur Deck/Gurt tragen die Fahrfläche; dekorative Seiten-/Rollenteile blockieren die Auffahrt nicht. Die Zone hat weiterhin den vollständigen Bike-Footprint und Bodenkontakt als Voraussetzung. Auto-Impulse, gültige Taps, Rebirth-/Energy-/World-Gates und drei Pet-Slots bleiben unverändert. Kein E-Prompt und keine permanente Trainings-BillboardGui.

## 3. Ressourcen direkt in der unteren rechten Ecke

Der bisherige Ressourcenbereich erbte die 8px-Root-Paddingfläche und verwendete auf Touch zusätzlich 130px unten bzw. 138px rechts. Diese zusätzlichen Verschiebungen sind entfernt.

Ein eigener vollständig transparenter, **ungepaddeter CoreUISafeInsets-Layout-Canvas** verankert den HUD mit `(1,1)` bei exakt `(-10,-10)` Pixeln innerhalb der Safe Area. Energy/Cash/Rebirths bleiben in dieser Reihenfolge übereinander, Icons links und weiße konturierte Werte rechtsbündig. Die vorhandenen grafischen Symbole und K/M/B/T-Formatierung bleiben. Touchbreite 136px, Desktopbreite 160px; skalierte Schrift mit Größenlimits schützt lange Zahlen. Keine sichtbaren Boxen, Kacheln, Rahmen oder zusätzliche Ressourcenzähler.

Der eigene Touch-Sprungbutton sitzt oberhalb des HUDs statt an dessen Position. Space/Touch-Sprung und Shift/Touch-Bremse bleiben gebunden. Der Ressourcen-Canvas liegt hinter Modalmenüs. Echte CoreGui-/Device-Überlappungen müssen im Studio-Emulator abgenommen werden.

## 4. Auto Train teleportiert den vorhandenen Mount

- `AutoTraining` ermittelt aus dem bestehenden 40er-Katalog das stärkste **tatsächlich registrierte/verfügbare** Laufband. Bedingung: Weltbesitz UND (aktuelle Energy ODER Rebirths ausreichend), zusätzlich echte serverseitige VIP-Berechtigung bei VIP-Markierung. Ungebaute Welten liefern keine Teleportziele. Aktuell sind weiterhin nur die fünf Welt-1-Geräte gebaut.
- Beim Einschalten prüft die Zustandsmaschine sofort. Danach werden relevante Freischaltungen/Resets im bestehenden 200ms-Servertakt erkannt. Keine Fahrt zwischen Trainingsgeräten mehr. Ein Schutzintervall von 0.4s begrenzt aufeinanderfolgende echte Versetzungen; normale Freischaltungen benötigen keine zusätzliche Bestätigung.
- `MountedBikeService.trainTeleport(player,id)` akzeptiert nur eine stabile ID. Zielposition und Ausrichtung stammen ausschließlich aus der privaten serverseitigen Zonenregistrierung. Kein frei wählbarer Ziel-Remote, keine CFrames/Positions-/VIP-/Reward-Felder im Client-Intent.
- Unabhängige erneute Prüfung von Datenbereitschaft, Berechtigung, verfügbarer Zone, ebenem ausreichend großem Ziel, endlichen Koordinaten, Bodenkontakt und freiem Körperraum per Overlap-Abfrage. Ein blockierter Zielraum beendet Auto Train mit sichtbarem Fehler; keine wiederholten Fehlteleports.
- Genau dasselbe vorhandene Bike bleibt erhalten. Die zentrale Bike-Wurzel wird versetzt, der Fahrer folgt seinem bestehenden Sattel-Weld. Kein Root-Offset als Bewegungsursprung, kein Absteigen und kein zweites Trainingsbike.
- Speed/VY und Eingabewarteschlangen werden zurückgesetzt. Eine neue Drive-Epoch verwirft alte Fahrbefehle und Vorhersage. DriveState meldet den Automatikzustand zusätzlich zum Attribut, damit verspätete Attributreplikation keine manuelle Vorhersage auf dem Auto-Bike aktiviert. Der einzige Kamerabesitzer setzt sein Ziel bei geändertem Teleport-Serial sauber um, auch bei kurzen Bandwechseln.
- Bereits korrekt platzierte Spieler werden trotz identischer Anfragen, normalen Energy-Updates oder Bike-Wechsel nicht erneut versetzt. Nach Respawn, Verlust der aktuellen Berechtigung, Rebirth oder einem echten stärkeren Ziel wird neu entschieden. Kein künstlicher Tap/Extraimpuls; der bestehende TrainingController vergibt die normalen Gewinne.
- Auto Train hält das Bike während der Automatik am Band. Ausschalten stellt die manuelle Fahrt wieder her. Normales Training kann weiterlaufen, solange der Spieler gültig auf dem Band bleibt; Wegfahren/Sprung beendet es wie bisher. Manuelles Springen bleibt nach Abschalten der Automatik verfügbar.
- Ein aktives Rennen hat Vorrang: keinerlei Trainings-Teleport während Countdown/Fahrt/Zielabwicklung. Nach Rennende kehrt Auto Train sofort zum besten Band zurück. Auto Race behält seine normale dreisekündige Neustartpause und fährt anschließend wieder zur Rennzone; dessen Navigation/Rennwiederholung bleibt erhalten. Trainingsteleports unterbrechen niemals ein laufendes Rennen.

VIP bleibt zukünftiger Inhalt, Produkt-IDs bleiben deaktiviert. Die neuen Gate-Prüfungen aktivieren keine bisher nicht vorhandenen VIP-Laufbänder. Welt 2–8 bleiben ungebaut.

## Daten und bewahrte Systeme

**Keine Schemaänderung:** Schema 3, Store-/Schlüsselnamen, Session-Locks, Autosave, Receipts, Migration und bestehende Profile bleiben unverändert. Energy/Cash/Rebirths, Balancingwerte, Fahrzeuge, Garage/Halbkreis, Eggs/Pets/Equip Best, Fusionen, Premium-Shop und Rennen werden nicht zurückgesetzt. Teleportzustand/Serial/Epoch sind ausschließlich Laufzeitdaten. Alle lokalen Speicherfälle verwenden Engine-/In-Memory-Fixtures.

## Ausgeführte Prüfungen

`python3 tools/test.py`: **229 Luau-Tests bestanden**, darunter **74 Runtime-Verdrahtungstests** mit den echten Modulen gegen Engine-Doubles. Vier neue reine Zugangstests, 15 zusätzliche Runtime-Fälle: Aktivierung, gemeinsame Transformation mit PivotOffset, Ausrichtung auch bei gedrehter Zone, Freischaltung, Energy-Reset/Rebirth, Welt-/VIP-Gates, fehlender/blockierter Boden/Zielraum, keine Spam-/Tap-Gewinne, Deaktivierung, Race-Ausschluss/Wiederholung/Rückkehr, Respawn/Bike-Wechsel, Kamera/alte Epochen, Touch/HUD und Diagnosemessungslogik.

**19 Python-Geometrie-/Source-Tests bestanden** (sieben neue V4.5-Fälle). Prüfung der wirklichen rbxlx/rbxmx: beide GUI-Seiten/Adornee/SizingMode, Kontrast, BIKE-SHOP-Sichtseite vor Glas/Dach, große geometrische Icons, nur dünne Neon-Inlays, rechteckige symmetrische Geräte/Rollen/Collision-Top, freier Premiumbereich, keine alten Schilder/Ovale/Rampen, komplette Module und einmaliger Eck-HUD. Rojo-Farbserialisierung wird auch im tatsächlich gebauten Place geprüft.

Zusätzlich: alle bestehenden Struktur-/Generatorprüfungen, vollständige Produktions-Luau-Kompilierung, Strict-Analyse, Roblox-API-/Typprüfung und vollständiger Rojo-Build. Insel: 3297 verankerte Parts, bestehendes Budget <3300 bleibt eingehalten. Keine gemessene mobile Framerate.

Zwischenläufe fanden veraltete Testannahmen zu Touchabständen/alten Modellnamen, eine fehlende Typ-Eingrenzung beim Teleport-Attribut und einen Testlesefehler bei Rojo-gepackten Farben. Tests wurden nicht entfernt; geänderte Erwartungen folgen ausschließlich den V4.5-Vorgaben. Native Renderingwerte werden nicht als erfolgreiche Sichtprüfung ausgegeben.

## NICHT AUSGEFÜHRT — verpflichtende Roblox-Studio-Abnahme

Roblox Studio ist in dieser Linux-Umgebung nicht verfügbar. Keine tatsächliche Öffnung/Play-Ausführung, native Physik-/Text-/IK-/Kamera-Replikationsmessung, Touch-Geräteprüfung, echte Marketplace-Käufe, produktive/isolierte Roblox-DataStore-Aufrufe oder mobile Lastmessung. Der Build und seine XML-/ZIP-Struktur sind geprüft, seine visuelle Spielbarkeit benötigt weiterhin manuelle Abnahme.

1. **Datei:** neuesten erfolgreichen Artifact `BikeEvolutionSimulator-V4.5` herunterladen, entpacken und Commit/SHA-256 in BUILD_INFO vergleichen. `.rbxlx` in Studio öffnen, Play im standardmäßigen nicht persistenten Preview. Keine Bootstrap-/Outputfehler.
2. **Schilder:** BIKE SHOP vom Spawn/Shop-Halbkreis aus bei normalem Kameraabstand lesen. Vollständiger großer Schriftzug, dunkle matte Fläche, sichtbares Bike-Icon, dünne Akzente; kein Dach/Glas/Part verdeckt Text. Alle übrigen Schilder einschließlich Rückseiten, Garage-Kleinschilder und Start/Finish prüfen. Keine abgeschnittenen Glyphen, Floating-Icons oder überstrahlten Flächen. Explorer: Adornee/Face/PixelsPerStud/SizingMode/TextBounds/TextFits; `BikeRuntime.SignDiagnostics` darf ungemessene Flächen nur als pending ausweisen.
3. **Geräte:** fünf rechteckige dunkle Trainingsgeräte mit sichtbaren Rollen und symmetrischen Rahmen. Farbfolge korrekt, Premium-Mitte frei. Mit allen zehn Bikes von vorne/seitlich befahren, keine unsichtbare Kante oder Rahmenkollision. Automatisches Training/Taps und Sperren prüfen, keine E-Taste/Billboards.
4. **HUD:** PC, iPhone/iPad sowie sehr kleine Querformate. Drei einzelne Ressourcenzeilen mit erhaltenen Icons unmittelbar unten rechts, jeweils ~10px Abstand zur Safe Area, keine Root-Padding-/130px-Verschiebung. Große Zahlen und CoreGui/Home-Indikator prüfen; Touch-Sprungbutton über dem HUD, keine Überlappung, Menüs liegen darüber.
5. **Auto Train:** vom Spawn einschalten → sofort auf das beste erlaubte Band, genau ein Bike, korrekte Sattelpose/Orientierung, Speed=0, kein Fall. Erster Gewinn nur normal nach Auto-Intervall; gültige Taps zusätzlich. Nächste Energy-Schwelle erreichen → automatischer einmaliger Wechsel. Rebirth/isolierter Energy-Reset → neu erlaubtes Band. Aktuellen gültigen Stand über viele Impulse beobachten: keine wiederholten Teleports.
6. **Berechtigungen/Sicherheit:** höhere/gesperrte Bänder, fehlende Welt und VIP-Sperre in der separaten Test-Experience prüfen. Ein lokales VIP-Attribut darf nicht reichen. Kein neuer Kauf/World-Unlock. Blockierten Zielraum simulieren → sichere Fehlermeldung/Stop statt Fall/Teleport-Schleife. Keine frei wählbaren Ziele über Remotes.
7. **Transitions:** Auto Train ausschalten → sofort normale manuelle Fahrt; auf dem Band bleibt nur berechtigtes normales Training. Wegfahren/Space/Touch-Sprung beendet Training. Auto Train bei laufendem Rennen einschalten, Energy ändern und Anfragen wiederholen: kein Teleport/Abbruch. Nach regulärem Ende zurück zum besten Band. Beide Automatiken an: Pause/Train/Rennwiederholung beobachten, keine Schleife oder Doppelzahlung.
8. **Mount/Kamera:** kleine/große R15-/R6-Avatare, Respawn, Bike-Wechsel und 18-Studs-Bandwechsel prüfen. Fahrer/Bike bleiben zusammen, keine neue Bikeinstanz oder Pivot-Orbit. Kamera ohne dauerhaftes Zittern; Replikation bei 0/100/250ms Latenz testen. Native TextFits-/Pixelprüfung und solche Fahrtests sind durch die CLI-Tests nicht ersetzt.
9. **Regression/Persistenz:** Garage-Kauf/Equip/Halbkreis, Eier/Pets/EQUIP BEST, Rebirth, Easy/Medium/Hard, Slow Mode und deaktivierte Robux-Angebote prüfen. Save/Rejoin ausschließlich in separater Test-Experience/isoliertem Teststore. Keine Produktionsprofile verwenden. Änderungen an Fortschritt oder Schema sind durch diesen Umbau nicht beabsichtigt.

## Build

Lokal: `python3 tools/test.py`, dann `python3 tools/package_v4.py --version V4.5`. Ausgabe `build/BikeEvolutionSimulator-V4.5.zip` mit vollständiger Place-Datei, BUILD_INFO (Commit, UTC, Bytes, SHA-256, Studio-Teststatus) und SHA256SUMS. Der Packager prüft XML-Abschluss, ZIP-CRC und identischen Place-Hash. GitHub Actions führt alle bisherigen Schritte aus und ergänzt den V4.5-Artifact. Ältere Artifact-Bezeichner bleiben aus Kompatibilitätsgründen erhalten; historische Versionsstände sind nur in ihren jeweiligen älteren Actions-Läufen zu finden.
