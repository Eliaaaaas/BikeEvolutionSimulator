# UI & Training Overhaul V3

> V4.1 ersetzt die frühere Fußbewegungs-/Trainingsrad-Regel: [Permanentes Bike-System](PERMANENT_BIKE_V41.md). Spieler bleiben auf genau einem Bike; Garage öffnet automatisch im Halbkreis ohne E-Prompt. Historische Beschreibungen sind entsprechend überholt.

> Historischer V3-Stand. [V4](VISUAL_OVERHAUL_V4.md) ersetzt die hier beschriebene Trainings-BillboardGui vollständig durch deren Entfernung und ersetzt Upgrades durch Shop. Die übrigen Eingabe- und Sicherheitsregeln bleiben gültig.

Dieser Stand setzt den angehängten schriftlichen Auftrag und den Zusatz zur vollständigen HUD-Bereinigung um. Die erwähnten Screenshots lagen hier nicht vor. Der Vertrag Visual Upgrade V2 bleibt für die unteren rechten Ressourcenanzeigen verbindlich.

## Entfernte Oberfläche und Weltobjekte

- Keine permanente PALM-BAY-Kopfzeile, keine Energy-/Cash-Menükacheln links, keine Sidebar-Hintergrundbox, kein Sidebar-Schatten/-Rahmen und kein Navigation-ScrollingFrame.
- Nur Garage, Pets, Race, Worlds, Rebirth, Upgrades und Settings als eigenständige farbige Menübuttons. Im Hochformat eine Spalte; auf niedrigen Displays kompakt in zwei Reihen, damit alle sieben Buttons ohne Scrollen sichtbar bleiben. Safe Insets und dynamische Skalierung bleiben aktiv.
- Kein permanenter Trainingsstatus-Kasten, kein Trainingsbutton, keine dauerhafte Tap-Anleitung und kein altes Energy-Fortschrittsfenster. Situative Fehlermeldungen erscheinen kurz als transparenter Text.
- Energy, Cash und Rebirths ausschließlich unten rechts: ein einzelner transparenter Ressourcen-HUD mit freistehenden Icons/Zahlen aus bestätigten Snapshots. Geöffnete Menüs dürfen weiterhin Voraussetzungen und Vorschauen zeigen.
- Kein Trainings-E-Prompt und keine zugehörigen Client-Warteschleifen oder Server-Prompt-Callbacks. Die anderen Interaktionsprompts für Garage/Eggs/Race bleiben bestehen.
- Keine großen Front-/Rücktafeln, SurfaceGuis, Konsolenplatten oder Infotextschilder an den fünf Trainingsgeräten. Auch die Premium-Platzhaltertafel wurde entfernt; der reservierte Bodenbereich bleibt frei.

Beim erneuten GUI-Aufbau wird eine alte `PalmBaySidebar` und ein eventuell vorhandener V3-HUD kontrolliert entfernt. Dadurch kann ein alter Overlay beim erneuten Start nicht zusätzlich zum neuen HUD stehen bleiben. Der Map-Schriftzug in der 3D-Welt ist kein HUD und bleibt erhalten.

## Automatisches Training und Eingaben

Die bestehende serverseitige Betretenerkennung prüft weiter Weltzugang UND (aktuelle Energy ODER Rebirths), Abstand, lebenden Charakter und Sitzung. Auf einem erlaubten Belt startet automatisch das bestehende Sekunden-Training; beim Verlassen, Tod, Rennen oder nach verlorenem Rebirth-Zugang endet es. Strengths/Requirements, Rebirth-/Pet-Boni und Datenspeicherung bleiben unverändert.

`TrainingInput` verarbeitet ausschließlich linken Mausklick und einen einzelnen `TouchTap`. Touch-InputBegan ist keine zweite Tap-Quelle. `TrainingTap` dedupliziert schnelle Eingaben und synthetische Mausereignisse nach Touch; Menü-/GUI-Eingaben, Textfelder, Mehrfingergesten, Rennen und fehlende Trainingsauswahl senden keinen Trainingsintent. Zusätzlich zur `gameProcessedEvent`-Prüfung werden getroffene GuiButtons erkannt.

Der Client sendet nur `Click`. Der Server behält seine unabhängige Impuls-/Rate-/Berechtigungsprüfung. Es gibt keine clientseitige Energy-Vergabe. Ein bunter Popup zeigt ausschließlich den im Server-Feedback bestätigten tatsächlichen Gewinn. Kleine Dezimalgewinne wie 1.65 werden lesbar erhalten; große Zahlen bleiben abgekürzt. Auto- und Klickimpulse verwenden weiter getrennte serverseitige Cooldowns.

## Neue 3D-Geräte und aktive Trainingsdarstellung

Die fünf Geräte behalten ihre Zonen und IDs. Neue eigene Geometrie: mehrschichtige ovale Basen, verschiedene Neonfarbpaare, leuchtende Kanten, bewegte Richtungsstreifen, größere Energiekerne, Orbitlichter und mit der Stufe zunehmende Energiefinnen. Keine externen Models/Animations-/Bild-IDs.

Lokale Effekte werden distanzbegrenzt in einer gemeinsamen Schleife verwaltet; ausgeschaltete Animationen stoppen Bewegung und Energiepartikel. Kleine Sparks sind auf zwei pro Gerät auf Touch-Geräten beziehungsweise vier am PC begrenzt. Keine replizierten Effektupdates oder unbegrenzten Emitter.

Während bestätigten aktiven Trainings wird eine lokale verkleinerte Kopie des vorhandenen Mountainbikes als Trainingsfahrrad unter dem Avatar dargestellt. Die gemeinsame Rig-/Wheel-/Crank- und Fahrer-IK-Architektur wird genutzt, einschließlich skalierter Zielpunkte. So wird die Tretpose statt der Laufpose verwendet. Körperbewegung bleibt möglich, damit der Spieler den Belt verlassen kann; keine neue Fahrzeugsteuerung oder serverseitige Zwangsverankerung. Maximal zwei Trainingsfahrräder auf Touch-Geräten oder vier am PC, eigener Spieler priorisiert. Die temporären Modelle und Posen werden beim Trainingsende/GUI-Abbau aufgeräumt.

Eine transparente BillboardGui folgt dem aktiven Avatar deutlich über dem Kopf. Große mehrfarbige Schrift mit Kontur zeigt `⚡ TRAINING +<bestätigter Impuls>/SEK`, optional mit kleinem animiertem Stern. Maximal vier nahe Anzeigen, Sichtweite 65 Studs. Beim Verlassen wird die Anzeige zerstört. Der Impulswert wird vom Server berechnet und berücksichtigt auch numerische Sättigung. Animationseinstellungen ändern keine Gewinne.

## Prüfstand und Grenzen

**139 Luau-Tests bestanden.** Dazu Luau-Kompilierung, Strict-/Roblox-Typprüfung, Rojo-Build, deterministische Assetprüfungen und Built-Place-Integration.

Neu: drei Input-Gate-Tests und fünf Runtime-Tests mit echten UI-/Input-/Remote-/Servermodulen gegen Engine-Doubles. Sie prüfen entfernte Kopfzeile/Navigationselemente, einmaligen GUI-Aufbau, keine Navigation-Scrollfläche, reale Bildschirm-Tap-Anbindung samt synthetischem Mausereignis und GUI-Hit, tatsächliche Rebirth-/Pet-Multiplikatoren, Zugangsverlust nach Rebirth, fehlende Prompts sowie die tatsächliche Erzeugung/Entfernung der transparenten Trainings-BillboardGui.

Der generierte Place wird auf fehlende Trainingsschilder/-prompts und auf das Fehlen alter UI-Erzeugung geprüft. Der im Place enthaltene UI-Source muss dem runtime-getesteten Source entsprechen. Bestehende V2-Ressourcenbindung, Rebirth-Sidebar und Pet-V3-Tests bleiben erhalten.

**NICHT AUSGEFÜHRT:** echte Roblox-Studio-Öffnung/Playtests, iPhone/iPad/PC-Darstellung und Eingaben, Render-/Motor6D-/IK-/Avatar-Skalierung, reale Replikation/Streaming, Effektauslastung und echte DataStores. Engine-Doubles ersetzen diese Prüfungen nicht. Das Fahrgefühl/Clipping der kleinen Trainingsfahrräder, Billboard-Überlappungen bei Gruppen und sehr kleine Querformat-Displays müssen ausdrücklich in Studio abgenommen werden. Der neue Build ist dafür vorbereitet, nicht bereits abgenommen.

## Manuelle Prüfreihenfolge — NICHT AUSGEFÜHRT

1. Neue Datei öffnen: links kein PALM BAY und keine Energy-/Cash-Kacheln; alle sieben Menübuttons ohne Scrollen; rechts unten genau drei freistehende Ressourcenzähler. Hoch-/Querformat wechseln.
2. Belt 1 betreten, keine Taste drücken: automatischer Gewinn, kleine Fahrrad-/Tretanimation und transparente aktive Anzeige über dem Kopf. Kein E-Prompt und keine Schilder an den Geräten.
3. Auf die freie Spielfläche klicken/tippen: bestätigte zusätzliche Gewinne und kurze farbige Zahlen; automatisches Training läuft parallel. UI-Buttons, Chat/Textfelder und Mehrfingergesten erzeugen keine zusätzlichen Tap-Gewinne.
4. Weggehen/sterben/Race starten: Training, Fahrerpose, Trainingsmodell und aktive BillboardGui enden; außerhalb kein Training.
5. Gesperrten Belt betreten: keine Gewinne. Energieanforderung erfüllen und erneut versuchen. Rebirth über die linke Sidebar bestätigen: ein höherer Belt kann wieder gesperrt sein.
6. Pets ausrüsten und Rebirths berücksichtigen: angezeigter Impuls und reale Energy-Differenz stimmen überein. Weiterhin kein doppelter Ressourcen-HUD.
7. Animationen/Popups deaktivieren: Effekte ruhen, gültige Servergewinne bleiben korrekt. GUI erneut starten/Avatar wechseln: keine alten Overlays, Modelle, Ziel-Attachments oder Schleifen bleiben zurück.
8. Garage, Rennen, Cash, Eggs, EQUIP BEST, UNEQUIP ALL sowie Save/Rejoin in der separaten Test-Experience prüfen. Normale Produktionsprofile nicht verwenden.
