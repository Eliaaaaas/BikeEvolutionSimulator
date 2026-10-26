# Bike Evolution Simulator — Palm Bay Visual Overhaul V4

Palm Bay verbindet Training, Rebirths, zehn kauf-/ausrüstbare Fahrzeuge, automatische Rennen gegen fünf Bots, Cash-Belohnungen, drei Eier und zwölf sammelbare Pets. Der bestehende Draft [PR #2](https://github.com/Eliaaaaas/BikeEvolutionSimulator/pull/2) liegt auf `feat/phase-2-training-world`; Basis bleibt der ungemergte Phase-1-Branch. Der vorherige Build wurde vom Spieler **nicht abgenommen**. Dieser Rebuild repariert belegte Integrationsfehler und ist erneut manuell zu prüfen. **Keine Studio-Abnahme durchgeführt.** Ursachen, sichere Testmodi und vollständige Checkliste: [Emergency-Rebuild-Bericht](docs/EMERGENCY_REBUILD.md).

## Studio-Build öffnen

1. Unter [Actions → Validate Luau foundation](https://github.com/Eliaaaaas/BikeEvolutionSimulator/actions/workflows/validate.yml) den neuesten erfolgreichen Lauf von `feat/phase-2-training-world` auswählen.
2. **Artifacts → BikeEvolutionSimulator-V4** herunterladen (enthält Place, `BUILD_INFO.json` mit Commit und SHA-256 sowie `SHA256SUMS.txt`). Alternativ bleibt **BikeEvolutionSimulator-Studio** verfügbar. ZIP entpacken und `BikeEvolutionSimulator.rbxlx` über **File → Open from File…** öffnen. Eine GitHub-Anmeldung ist für den Download nötig; lokale CLI-Tools sind dafür nicht erforderlich.
3. Zunächst direkt **Play** starten: `Workspace.StudioPreviewData=true` aktiviert ausschließlich in Studio den deutlich markierten **nicht dauerhaften Vorschau-Store**. Kein Veröffentlichen oder DataStore-Zugriff erforderlich. Alle normalen Validierungen und Session-Locks bleiben aktiv. Stop/Play verwirft ausdrücklich diese Vorschau-Daten.
4. Für dauerhafte Speicherprüfungen in einer **separaten Test-Experience** veröffentlichen, `Workspace.StudioPreviewData=false` setzen und **Enable Studio Access to API Services** dort aktivieren. Studio verwendet dann ausschließlich **BikeEvolution_StudioTest_v2**. Normale veröffentlichte Spielserver ignorieren das Preview-Attribut und behalten den bisherigen Store. Es gibt keinen automatischen In-Memory-Fallback nach einem Live-Speicherfehler.

Insel, Strecke, zehn Fahrzeuge, Egg-Stationen und zwölf Pet-Modelle sind editierbare Studio-Objekte im Build. Der Workflow führt alle Tests aus und lädt anschließend die vollständige `.rbxlx` mit `actions/upload-artifact@v4` hoch. Fehlende Datei: Workflow-Fehler über `if-no-files-found: error`.

## Welt 1 durchspielen / manuelle Prüfreihenfolge

1. **Insel:** Zentral spawnen, alle Wege ablaufen. Flache Grasoberfläche, natürliche Kontur (~180×180), Palmen, Büsche, Blumen, Felsen, Wasserfälle, Wege, Beleuchtung und drei getrennte Egg-Stationen prüfen. Trainingsreihe hinten, Race vorne, Garage seitlich und World-Portal in der Ecke. Rebirth ist ausschließlich über die linke Sidebar erreichbar. Die Premium-Lücke bleibt frei. Wasser/Wasserfälle sind dekorative Geometrie, keine Flüssigkeitssimulation. Wasserfälle erhalten lokal animierte Schaumstreifen; diese verschwinden bei ausgeschalteten Animationen und werden nur bis 140 Studs animiert.
2. **Training:** Hinten Laufband 1 betreten: Die Auswahl erfolgt automatisch auf dem Server. Ein E-Prompt ist nicht mehr nötig und wurde entfernt. Automatisch ein Impuls/Sekunde; jeder gültige Klick/Tap auf die freie Spielfläche ergänzt einen Impuls, maximal fünf/Sekunde. Basisgewinne 1/2/4/8/16. Weglaufen oder Tod beendet die Auswahl. Es gibt keine dauerhafte Trainings-BillboardGui oder Trainingsbox; bestätigte kurze Energy-Pop-ups und die Anzeige unten rechts bleiben. Animationen erzeugen keine zusätzlichen Gewinne.
3. **Rebirth:** Ausschließlich links über den Rebirth-Menüpunkt der Sidebar öffnen. Aktuellen/nächsten Multiplikator und Fortschritt prüfen. Abbrechen muss unverändert bleiben. Bestätigen bei genug Energy setzt ausschließlich Energy auf 0 und erhöht Rebirths um 1. Cash, Fahrzeuge und Pets bleiben erhalten. Ein höheres Laufband kann dadurch wieder gesperrt sein.
4. **Cash verdienen:** Zur Race-Zone vorne gehen, **Race → Easy/Medium/Hard → Rennen starten**. Der ProximityPrompt startet Easy. Nach drei Sekunden fährt das ausgewählte Fahrzeug automatisch auf der offenen 800-Studs-S-Fahrlinie mit Höhenwechseln und Brückenabschnitten. Eine eigene Rennkamera folgt dem Fahrer und wird nach Ende/Abbruch wieder freigegeben. Fünf Bots haben feste Tempi. Platzierung folgt dem tatsächlichen Fortschritt bzw. Zielübertritt, nicht Zufall. Am Ziel abbremsen, Cash-Ergebnis sehen und sicher zur Insel zurückkehren. Energy bleibt erhalten. Auch Platz 6 erhält Cash, sodass das Spiel ohne Startguthaben funktioniert.
5. **Garage:** Verdientes Cash für City Bike und weitere Fahrzeuge ausgeben, Besitzstatus prüfen und ausdrücklich **Ausrüsten** wählen. Nach dem nächsten Start muss genau dieses Fahrzeug erscheinen. Alle zehn Modelle stehen zusätzlich als verankerte Ausstellung auf der Insel. Die 3D-Vorschau zentriert das Modell anhand seiner Grenzen; Preis und Geschwindigkeitsfaktor werden pro Auswahl angezeigt. Käufe hängen nicht von World-Unlocks ab. Außerhalb von Rennen läuft der Spieler zu Fuß; keine manuelle Fahrsteuerung.
6. **Eier:** Tropical/Jungle/Waterfall-Station öffnen oder **Pets → Eier öffnen**. Die vier möglichen Arten, Raritäten, Chancen, Boni und der Cash-Preis sind sichtbar. **Ei öffnen** zieht serverseitig Cash ab und vergibt genau ein Pet. Bei fehlendem Cash/voller Tasche darf nichts abgezogen werden. Das bestätigte Pet erscheint mit kurzer Reveal-Animation.
7. **Pets:** Inventar öffnen, Pet-Vorschau/Boni prüfen, bis zu drei unterschiedliche Instanzen ausrüsten und wieder ablegen. Neue Hatch-Pets füllen freie Slots automatisch; bei drei belegten Slots wird nichts ersetzt. **⚡ EQUIP BEST** wählt einmalig die drei stärksten Instanzen anhand beider Boni; **UNEQUIP ALL** lässt die Slots bis zu einer neuen bewussten Aktion oder einem neuen Hatch leer. Die drei aktiven Slots und Begleiter sind sichtbar. Ein viertes Equip muss scheitern. Training und Renn-Cash müssen sich entsprechend erhöhen. **Pet-Index** zeigt Entdeckungen, unbekannte Arten, Raritäten und Sammelfortschritt je Ei. Inventarlisten sind seitenweise auf 20 Einträge begrenzt.
8. **Speichern (dauerhafter Testmodus erforderlich):** Nach erfolgreichem Autosave oder normalem Verlassen erneut beitreten: Energy/Cash/Rebirths, gekaufte/aktive Fahrzeuge, Pet-Instanzen, Equip und Entdeckungen müssen erhalten bleiben. Training und laufende Rennen werden nicht als aktive Sitzung restauriert. Abbruch, Tod, Disconnect, fehlenden RootPart und mehrere parallele Rennteilnehmer separat testen.
9. **Mobile/UI:** iPhone/iPad in Hoch-/Querformat und PC prüfen. Sidebar startet auf Smartphones kompakt, lässt sich aufklappen; alle sieben Menübuttons bleiben ohne Scrollen sichtbar und wechseln bei kleinen Höhen in ein kompaktes Raster. Safe Areas, CoreGui, Joystick und Jump dürfen nicht verdeckt werden. Settings für Animationen/Popups/Sound/Lautstärke wirken sofort, nur in der Sitzung. Garage/Pet-Viewports, Hover/Tap und Fortschrittsbalken prüfen. Popup-Anzahl ist begrenzt; Rebirth-Effekte werden durch Server-Feedback-IDs dedupliziert.

**Noch nicht ausgeführt:** tatsächliche Studio-Playtests, Geräte-/Touch-/Audio-Abnahme, R15/R6-Körperkontakt, echte Motor6D-/Streaming-/Kamera-Replikation, reale DataStore-Migration/Throttling/Shutdown und Mehrspieler-Last. Für schnelle Rebirth-Prüfungen darf ausschließlich in der separaten Test-Experience ein Server-Debugger verwendet werden; ein unsicherer Debug-Schreibremote existiert nicht.

## Zentrale Regeln und vorläufiges Balancing

`src/shared/World1Content.luau` enthält alle neuen Fahrzeugpreise/Tempi, Egg-Preise/Chancen, Pet-Boni und Schwierigkeitstabellen. Diese Zahlen sind **vorläufig**; [Balancing-Notizen](docs/BALANCE.md) erklären das langfristige Ziel und die noch fehlende Validierung.

- Laufbandzugang: **Weltbesitz UND (aktuelle Energy ausreichend ODER Rebirths ausreichend)**. Kein Kauf und kein permanenter Laufband-Unlock. Laufband 1 verlangt 0/0, Laufband 2 provisorisch 1/1, danach Faktoren 4 bzw. 3.
- Training: `Basisimpuls × (1 + Rebirths × 0.5) × PetEnergyBonus`. Rebirth benötigt aktuell `1000 × (Rebirths + 1)` Energy. Automatische und Klick-Cooldowns sind getrennt; keine Offline-/Nachholbursts.
- Pets: `Bonus = 1 + Summe((Basis-Multiplikator − 1) × Variantenfaktor)` über maximal drei Equips. Energy und Cash werden getrennt berechnet. Normal=1, Golden=2, Rainbow=4. Beispiel: drei normale Pets mit Energy 1.1 ergeben insgesamt ×1.3, nicht ×1.331. Varianten skalieren den **Bonus über 1**, nicht den gesamten Basisfaktor.
- Rennen: `(24 + min(28, log10(1+Energy) × 4)) × Fahrzeug-Speedfaktor`. Serverseitiger Snapshot beim Start; Fahrzeug-/Pet-Auswahl, Training und Rebirth sind während des Rennens gesperrt. Bots laufen zu den festen Tabellenwerten. Cash = Platzierungsbetrag × Weltfaktor × PetCashBonus. `RaceWorlds[1]` ist für spätere Welten erweiterbar; unbekannte Welten werden nicht ausgezahlt.
- Pro Rennen fünf eigene sichtbare Bot-Fahrzeuge; Bots fremder paralleler Rennen werden lokal ausgeblendet. Reale Spieler bleiben sichtbar, sind aber keine Teilnehmer deiner Solo-Bot-Wertung. Player-Fahrlinie beträgt 800 Studs; dekorative Bot-Spuren sind seitlich versetzt.
- Stabile IDs: 40 Fahrzeuge bleiben erhalten; 1–6 Fahrräder, 7–15 Mopeds, 16–27 Motorräder, 28–34 Supersportler, 35–40 Rennmaschinen. Nur 1–10 sind aktuell spielbar. Der 24-Egg-/96-Pet-Katalog bleibt bestehen; Welt 1 implementiert Egg-IDs 1–3 und Species 1–12.
- Golden-Fusion 5 identische normale Pets → Golden (Maschine erst Welt 4); Rainbow-Fusion 3 identische Golden → Rainbow (erst Welt 5). Daten-/Bonusarchitektur ist vorbereitet; diese Maschinen sind bewusst nicht in Welt 1 aktiv.
- Worlds zeigt den tatsächlichen Besitz und die noch nicht verfügbaren Maps; Shop verlinkt auf die vorhandenen Fahrzeug-/Egg-Käufe. VIP ist ausdrücklich zukünftiger Inhalt. Weitere Welten bleiben im Katalog cashbasiert; sie sind noch nicht als spielbare Maps verfügbar. Es gibt keine vorgetäuschten Käufe oder freigeschalteten Inhalte.

## Datenmigration, Serverautorität und Ausfälle

**Schema v2:** `ActiveVehicle`, `DiscoveredPets`, `LastRaceReward` ergänzen die bestehenden Felder. Die [vor Implementierung dokumentierte Migration](docs/PROFILE_MIGRATION.md) beschreibt Defaults, Rollout und Rollback-Grenzen. v1 wird erst beim normalen Load unter `UpdateAsync` und Session-Lock übernommen. Guthaben, Rebirths, Inventar-IDs und Besitz bleiben erhalten. Aktives Startfahrzeug=1, Entdeckungen werden aus dem vorhandenen Inventar gewonnen, Receipt startet leer. v2-Migration ist idempotent; beschädigte/unbekannte Profile werden abgelehnt statt zurückgesetzt.

Store **BikeEvolution_Player_v1** und Schlüssel **Player_<UserId>** bleiben unverändert (der Store-Name ist nicht die Schemaversion). Alte Server vor Rollout drainen: v1-Code kann v2 nicht laden. Keine automatische Downgrade-Löschung. Während dieses Auftrags wurden ausschließlich In-Memory-Fixtures genutzt, keine produktiven Daten gelesen oder verändert.

Alle wirtschaftlichen Mutationen laufen durch die vorhandene serverseitige Copy/Validate/Commit-Transaktion. Ein gemeinsamer Token-Bucket begrenzt Prompts/Remotes; Training hat eigene Klick-/Auswahl-/Rebirth-Cooldowns, Hatch zusätzlich eine Sekunde Pause. Strikte Feld-Allowlist akzeptiert ausschließlich Intents und begrenzte IDs, niemals vom Client festgelegte Beträge, RNG, Speed, Platzierung oder Rewards. Wirtschaftliche Intents benötigen monoton steigende Request-IDs; Wiederholungen werden vor der Transaktion abgewiesen. Clientmeldungen vergeben keine Währungen.

Race-UUID und Cash werden **in derselben Profiltransaktion** als `LastRaceReward` geschrieben. Ein Retry desselben Abschlusses kann nicht doppelt zahlen. Es gibt keinen Claim-Remote für angebliche Rennsiege. Ungültige Rennen, Disconnects, technische Abbrüche und Timeout zahlen nicht aus. Bei temporärem `Saving` wird die gültige Zielauszahlung bis zu zehn Sekunden wiederholt; danach wird ein nicht ausgezahlter Abschluss als solcher gemeldet.

Autosave 60 Sekunden, Lease 180 Sekunden, UpdateAsync mit begrenzten Retries, Leave-/Shutdown-Recovery und Schutz vor alten Session-Writes bleiben erhalten. Während Save/Disconnect sind neue wirtschaftliche Änderungen gesperrt. Bei hartem Absturz können Änderungen seit dem letzten bestätigten Save verloren gehen; laufende Roblox-Requests lassen sich nicht abbrechen. Das Receipt verhindert doppelte Auszahlung, garantiert aber keine nachträgliche Zahlung nach einem ungespeicherten Serverabsturz. Wiederverbindung kann bis zum Lock-Ablauf blockiert sein.

Numerische Grenzen: endliche Energy/Cash bis 1e300, ganzzahlige Rebirths bis 2^53−1. Sichere Addition/Multiplikation sättigen am Limit. IEEE-754 bedeutet oberhalb 2^53 keine exakte Einzel-Cash-/Energy-Einheit. Zentrale Anzeigeformatierung verändert keine gespeicherten Zahlen.

## Projektstruktur und lokale Prüfungen

Linux x86_64, Python 3, curl und Git genügen für die reproduzierbaren CLI-Schritte:

```sh
git clone https://github.com/Eliaaaaas/BikeEvolutionSimulator.git
cd BikeEvolutionSimulator
git switch feat/phase-2-training-world
python3 tools/bootstrap.py
python3 tools/test.py
mkdir -p build
.tools/rojo build default.project.json --output build/BikeEvolutionSimulator.rbxlx
# Optional mit Rojo Studio Plugin 7.4.4 in einer separaten Test-Experience:
.tools/rojo serve default.project.json
```

Bootstrap pinnt Luau 0.744, Rojo 7.4.4 und luau-lsp 1.70.1 mit Roblox-Typdefinitionen vom selben Release. Downloads von offiziellen Repositories mit aktiver HTTPS-Prüfung. Windows/macOS können direkt den Studio-Artifact nutzen; CLI-Bootstrap wird unter Linux getestet.

| Pfad | Funktion |
| --- | --- |
| `src/shared/World1Content.luau`, `Catalog.luau` | Zentraler World-1-Inhalt ohne Verschieben bestehender IDs |
| `src/shared/Profile.luau`, `src/server/Persistence.luau` | Validiertes v1→v2, bestehende UpdateAsync-/Lock-Architektur |
| `src/shared/EconomyController.luau`, `PetRules.luau` | Atomare Käufe, Hatch, Equip, RNG-Grenzen und Boni |
| `src/shared/RaceController.luau`, `RaceRules.luau`, `src/server/RaceService.luau` | Kurs, fünf Bots, Ziele/Platzierung, Reward-Receipt, Fahrzeug-/Charakter-Cleanup |
| `src/client/UI.luau`, `ClientApp.luau`, `init.client.luau` | Sidebar, Garage-Kauf/-Auswahl, Inventar, Index, Eggs, Race-Ergebnis |
| `src/client/PetFollowers.luau`, `Visuals.luau`, `AvatarPose.luau`, `IslandEffects.luau` | Lokale Begleiter, gemeinsame Fahrzeuganimation, Fahrerpose und lokale Wasserfall-Schaumstreifen |
| `src/models/*.rbxmx` | Zehn strukturell unterschiedliche Fahrzeuge und zwölf unterscheidbare Pet-Arten |
| `tools/build_world.py`, `build_race_assets.py`, `build_vehicle_fleet.py`, `build_pet_assets.py` | Deterministische, editierbare Primitive-Assets; `--check` erkennt veraltete Dateien |
| `src/shared/RuntimeContract.luau`, `src/server/StudioStore.luau` | Frühe Dependency-Prüfung, ausdrücklich isolierte Studio-Vorschau |
| `src/client/StationEffects.luau`, `RaceCamera.luau` | Lokale Belt-Anzeigen/Animationen und wiederhergestellte Rennkamera |
| `tests/` | Bestehende Suiten und World-1-Ökonomie-/Migrations-/Bot-/Assetprüfungen |

Nach Änderungen an Generatoren diese ausführen und die erzeugten Assets mitcommitten. Keine kostenpflichtigen Modelle, Meshes oder erfundenen Asset-IDs. Audio referenziert ausschließlich nachgewiesene Roblox-Paketdateien (`volume_slider.ogg`, `action_jump.mp3`, `action_jump_land.mp3`, `action_get_up.mp3`), siehe [Client-Manifest a020070](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/a020070e2758a71b5d61cf692eee3704a5793011/rbxManifest.txt). Tatsächliche Wiedergabe auf iOS/PC bleibt zu prüfen.

## Prüfstand und Grenzen

**141 Luau-Tests bestanden:** 35 Regeln/Persistenz, 10 Profil-Lifecycle, 12 Training/Sicherheit, 14 frühere Phase-2.1-Prüfungen, 15 World-1-Ökonomie/Migration, 5 RaceService-/BikeRig-Adaptertests, 12 Hardening-Tests und 21 Runtime-Verdrahtungstests, 14 V3-Pet-Equip-Tests und 3 Input-Gate-Tests. Alle bisherigen Suiten bleiben erhalten; Erwartungen für die ausdrücklich neuen Namen und Schema v2 wurden angepasst. Dazu sechs V4-Geometrie-/Darstellungsvertragsprüfungen und deterministische Insel-/Strecken-/Fleet-/Pet-Strukturprüfungen, Luau-Kompilierung, Strict-Prüfung der reinen Module, Roblox-spezifische Typprüfung des gesamten Client-/Servercodes und Rojo-Build. Die letzten lokalen Prüfungen sind erfolgreich; der zugehörige CI-Lauf wird im PR verlinkt.

Die Adaptertests führen echten Code mit Engine-Doubles aus, keine Roblox-Physik oder GUI. **Nicht ausführbar hier:** Studio/Device-Emulator, Audio/IK/Kamera/Streaming, echte DataStore- und Lasttests. Kein Studio-Test wird als bestanden ausgegeben. Einfache R6-Posen haben keine separaten Knie/Ellenbogen; R15-IK kann für ungewöhnliche Körpermaße Tuning brauchen. Fahrer-/Fahrzeugbewegung ist servergesteuerte Kinematik, keine physikalische Bikesimulation.

Mobile-Vorkehrungen: kurze Pet-Modelle (<25 Teile), maximal drei sichtbare Begleiter pro Spieler mit Distanz-Culling, seitenweises Inventar, begrenzte Effekte, bedarfsgesteuerte gemeinsame Animationen, Welt-Streaming, atomar gestreamte Rennmodelle, feste Heimatinsel. Inventardaten werden nur bei Änderung übertragen; reine Energy-Ticks versenden nicht ständig alle Pet-Instanzen. Zusätzlich wird das Inventar serverseitig anhand seiner Revision gecacht, damit Training nicht viermal pro Sekunde bis zu 500 Pet-Einträge kopiert. Reale Frameraten und Netzwerk-/Serverlast bei vielen gleichzeitigen Rennen müssen vor Veröffentlichung gemessen werden. Ein vollständiges Anti-Teleport-System und ein Admin-Backup-Recovery-Werkzeug sind nicht Teil dieses Builds.


## Überarbeitung: Stabilität und Bedienung

- Snapshot-Sequenzen schützen auch Rennfortschritt ohne neue Datenrevision vor verspäteten Antworten. Teil-Snapshots übernehmen Inventar nur bei identischer Inventarrevision; ein altes GetSnapshot-Ergebnis darf keinen neueren Zustand überschreiben.
- Der Countdown zählt ausschließlich Fahrzeit nach dem Startsignal. Ein Server-Stall gewährt weiterhin maximal 0,25 Sekunden Fortschritt pro Tick. Fahrzeuge und Bots stehen bereits vor dem ersten Tick an der Startlinie; Bot-Räder rotieren während des Countdowns nicht.
- Fehler bei Zufallsauswahl oder GUID-Erzeugung brechen einen Hatch vor jeder Profiländerung ab und werden protokolliert. Fehlgeschlagene Profiltransaktionen dürfen weder ein Pet noch ein Hatch-Ergebnis anzeigen. Temporäre Renn-Auszahlungsfehler erhalten begrenzte Wiederholungen und aussagekräftige Logs.
- Auszahlungen melden die tatsächliche Cash-Differenz; am Zahlenlimit entsteht keine erfundene Gutschrift. Receipt-Deduplizierung bleibt aktiv. Ungültige wirtschaftliche Request-IDs und nicht endliche UI-Werte werden abgefangen.
- Die UI nutzt CoreGui-Safe-Areas, echte Rennbezeichnungen, aktives Fahrzeug, Platzierung und Fortschritt. Training während des Rennens und Rebirth ohne Voraussetzungen sind in der UI gesperrt; die verbindlichen Prüfungen bleiben auf dem Server. Fehlermeldungen bleiben vier Sekunden sichtbar. Schließende Fenster werden durch eine Inventaraktualisierung nicht wieder geöffnet.
- Schema, Store, Profilfelder, Preise und permanente Fortschritte bleiben bei dieser Überarbeitung unverändert. Keine produktiven Profile wurden aufgerufen.

Zusätzliche manuelle Abnahme in der separaten Test-Experience: Garage schließen und unmittelbar eine Inventaraktualisierung auslösen (Fenster bleibt zu); beim Countdown die stillstehenden Räder beobachten; Rebirth-Button bei unzureichender Energy prüfen; Netzwerklatenz simulieren und auf rückwärts springende Energy-/Rennanzeigen achten; unter Settings die Wasserfallanimation abschalten und auf einem iPhone im Querformat Safe Areas und Rennstatus prüfen. Lokale Typprüfung und Engine-Doubles ersetzen diese Studio-Prüfungen nicht.


## Emergency-Rebuild: verbindliche erneute Abnahme

Behoben: fehlendes `UI.Gui` (führte in Effekt-Loops zu `nil.Parent`), ungeschütztes `GetDataStore()` vor dem Load, still verworfene Prompt-Fehler und fehlende sichtbare Fahrzeugausstellung. Bootstrap-Stufen und ein Weltvertrag machen fehlende Komponenten sichtbar. Optionale Effekte starten nach der Kommunikationsverdrahtung. Kein Schemawechsel.

Neu gestaltet: glattere asymmetrische Küste mit 96 flachen Grasstreifen, segmentierte geneigte Palmen, Blumenbeete, terrassierte Wasserfälle, Pflasterwege, zehn Showroom-Fahrzeuge, Neon-Laufbänder mit Status/Anforderungen und bewegten Streifen, überarbeitete Stationen und Beleuchtung. Die offene S-Strecke misst 800 Studs einschließlich Höhenprofil; Serverführung interpoliert Höhe und Richtung.

Die Integrationstests führen die echten Server-/Client-Bootstraps, die echte UI mit Button-Callbacks und die Services gegen vereinfachte Engine-Doubles aus. Die Weltstruktur stammt aus dem tatsächlich gebauten Place. **Das ersetzt kein Roblox Studio.** Alle manuellen Tests sind im [Ursachenbericht und Abnahmeprotokoll](docs/EMERGENCY_REBUILD.md) ausdrücklich **NICHT AUSGEFÜHRT**. Der neue Build bleibt bis zur erneuten Spielerprüfung nicht abgenommen.


## Visual Upgrade V2: Ressourcen-HUD und Rebirth

Energy, Cash und Rebirths stehen ausschließlich unten rechts als freistehende Blitz-/Münz-/Kreis-Pfeil-Symbole mit Live-Zahlen aus bestätigten Server-Snapshots. Keine Hintergrundboxen, Kacheln oder Rahmen. Die Sidebar enthält statische Menünamen statt doppelter Zähler. Auf Touch-Geräten wird zusätzlich zu den Safe Insets Platz für die Sprungtaste freigehalten.

Der physische Rebirth-Stand ist vollständig aus Insel, Generator, Prompt-Erzeugung und Runtime-Abhängigkeiten entfernt. Der linke Rebirth-Menüpunkt öffnet weiterhin Voraussetzung, Vorschau, Fortschritt und Bestätigung; die Mechanik bleibt unverändert. Der [verbindliche HUD-Vertrag](docs/VISUAL_UPGRADE_V2.md) und `AGENTS.md` halten diese Vorgaben für weitere UI-Arbeiten fest. Manuelle Studio-/Geräteprüfung weiterhin **NICHT AUSGEFÜHRT**.


## Pet Equip V3

**⚡ EQUIP BEST** bewertet Energy und Cash gleichgewichtet einschließlich Normal/Golden/Rainbow und rüstet einmalig bis zu drei Instanzen aus. Neue Hatch-Pets werden ausschließlich in freie Slots ergänzt; volle Slots werden nie automatisch ersetzt. **UNEQUIP ALL** löst kein sofortiges Wiederauffüllen vorhandener Pets aus. Auswahl, beide Boni und Speicherung bleiben serverautoritativ. Schema und Kataloggrößen unverändert.

Formel, Verfügbarkeitsregeln, vorbereitete Fusion-Slotpflege, Sicherheits- und Testdetails: [Pet Equip V3](docs/PET_EQUIP_V3.md). Die Fusionsmaschinen bleiben weiterhin Welt 4/5 vorbehalten. Echte Studio-Prüfung **NICHT AUSGEFÜHRT**.


## UI & Training Overhaul V3

Die PALM-BAY-Kopfzeile, Energy-/Cash-Menükacheln, Sidebar-Hintergrund, Navigation-Scrollfläche und alte Trainingsbox samt Trainingsbutton sind entfernt. Ressourcen bleiben ausschließlich unten rechts. Training startet ohne E-Prompt beim Betreten; zusätzliche Bildschirm-Klicks/Taps senden servervalidierte Impulse. Neue Neon-Geräte haben keine großen Tafeln. Eine transparente aktive Anzeige folgt dem Spieler über dem Kopf; lokale Trainingsfahrräder verwenden die gemeinsame Tret-/Fahreranimation.

[Verbindlicher Umbau, Eingabeschutz, Grenzen und manuelle Studio-Checkliste](docs/UI_TRAINING_OVERHAUL_V3.md). Rendering/IK/Touch sind weiterhin **NICHT in Roblox Studio geprüft**.


## Visual Overhaul V4

Die Insel besitzt eine durchgehende polygonale Küstenkontur mit flacher Grasoberseite, geschwungene Wege, detailliertere Palmen, weitere Baumarten, Blumengärten und Teiche. Alle Zonen tragen abgerundete mehrschichtige 3D-Schilder mit geometrischen Icons; Garage, Eggs, Race, Portal, Shop, Training und die als zukünftig gekennzeichnete VIP-Zone sind optisch getrennt. Leuchtende Laufbänder behalten ihre automatische Auswahl und Tap-Steuerung ohne E-Prompt oder dauerhafte Trainingsanzeige.

Die sieben freistehenden Sidebar-Buttons und sämtliche Menüs verwenden abgestimmte Farben, Verläufe, Icons und Animationen. Ressourcen stehen weiterhin ausschließlich unten rechts ohne Hintergrund. Shop und Portal öffnen echte Menüs über validierte Prompts; nicht implementierte Welten/VIP-Käufe werden nicht vorgetäuscht. Spielregeln, Preise, Pet-Boni, Profilfelder und DataStore-Verfahren bleiben unverändert.

[V4-Änderungen, Prüfgrenzen und Studio-Abnahmecheckliste](docs/VISUAL_OVERHAUL_V4.md). Der aktuelle Build ist für die manuelle Prüfung vorbereitet. **Roblox Studio: NICHT AUSGEFÜHRT.**

Lokal nach `python3 tools/test.py`: `python3 tools/package_v4.py` erzeugt zusätzlich `build/BikeEvolutionSimulator-V4.zip` und prüft XML, ZIP-Integrität und SHA-256. Der Actions-Artifact `BikeEvolutionSimulator-V4` wird aus denselben drei Dateien als ZIP bereitgestellt; `BUILD_INFO.json` benennt den exakten Commit.
