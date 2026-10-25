# Bike Evolution Simulator — Phase 1

Modulares Roblox-Luau-Grundgerüst mit Rojo, serverseitigen Profilen, sicherem HUD-Protokoll und ausführbaren Regeltests. Noch keine Maps, Trainings-/Kaufaktionen, Rennen, Bot-KI, Egg-Hatching oder Pet-Inventaroberflächen. Die Regeln dafür sind als Daten und reine Funktionen vorbereitet; das Debug-HUD zeigt die tatsächlich geladenen Serverwerte (anfangs jeweils 0).

## Installation und Start

Voraussetzungen: Git, Roblox Studio und das offizielle **Rojo Studio Plugin 7.4.4**. Für lokale CLI-Prüfungen werden Python 3, curl, **Rojo 7.4.4** und **Luau 0.744** verwendet. Keine npm-Abhängigkeiten, API-Schlüssel oder zusätzlichen Dienste erforderlich.

```sh
git clone https://github.com/Eliaaaaas/BikeEvolutionSimulator.git
cd BikeEvolutionSimulator
# Linux x86_64: offizielle, versionsgebundene HTTPS-Release-Artefakte
python3 tools/bootstrap.py
python3 tools/test.py
mkdir -p build
.tools/rojo build default.project.json --output build/BikeEvolutionSimulator.rbxlx
.tools/rojo serve default.project.json
```

`bootstrap.py` installiert nur nach `.tools/`; TLS-Verifikation bleibt aktiv. Auf Windows/macOS Rojo über die offizielle Installation bzw. `aftman install` (`aftman.toml`) und die Luau-CLIs aus dem offiziellen Release 0.744 installieren. Für Tests bei abweichenden Pfaden `LUAU_BIN`, `LUAU_COMPILE_BIN` und `LUAU_ANALYZE_BIN` setzen. Das Bootstrap-Skript ist ausschließlich für Linux x86_64 vorgesehen.

In Studio einen eigenen **veröffentlichten Test-Place** öffnen, über das Rojo-Plugin mit dem gestarteten Rojo-Server verbinden und synchronisieren. Alternativ die erzeugte `.rbxlx` öffnen. Unter Game Settings → Security → **Enable Studio Access to API Services** einschalten, damit DataStore funktioniert. Nur in einer getrennten Test-Experience aktivieren: Studio kann sonst dieselben Daten wie die Live-Experience verändern. Ohne DataStore-Zugriff wird der Spieler absichtlich getrennt; es gibt keinen flüchtigen Ersatzspeicher, der später echte Daten überschreibt.

Play starten. Links oben erscheinen Energy, Cash und Rebirths. Ein Respawn erhält das HUD. Stoppen und erneut starten prüft das Laden des gespeicherten Profils. Eine eigene Weltkarte ist noch nicht enthalten.

## Struktur

| Pfad | Aufgabe |
| --- | --- |
| `default.project.json` | Shared → ReplicatedStorage, Server → ServerScriptService, Client → StarterPlayerScripts |
| `src/shared/Config.luau` | Unveränderliche Regeln, provisorische Economy-Werte, Speicher-/Netzwerkparameter |
| `src/shared/Catalog.luau` | Stabile IDs für Welten, Fahrzeuge, Laufbänder, Eier und Pet-Arten |
| `src/shared/Rules.luau` | Reine Abfragen/Berechnungen für Training, Rebirth, Kaufberechtigung und Fusion |
| `src/shared/Profile.luau` | Profilschema, Validierung, isolierte Kopien und HUD-Snapshot |
| `src/shared/Protocol.luau` | Remote-Vertrag und Payload-Prüfung |
| `src/server/Persistence.luau` | Testbarer DataStore-Adapter mit Retry und Sitzungssperre |
| `src/server/PlayerDataService.luau` | Load/Leave/Autosave/Shutdown und serverseitiger Profilbesitz |
| `src/server/RemoteService.luau` | Erstellung und Absicherung der Remotes |
| `src/client/init.client.luau` | Lesendes Debug-HUD mit Ladeanzeige und initialen Wiederholungen |
| `tests/rules.spec.luau` | Regel-, Protokoll-, Profil- und Persistenztests |
| `.github/workflows/validate.yml` | CI: Syntax, Typprüfung der reinen Module, Tests und Rojo-Build |

## Regeln und Datenmodell

- 8 Welten, 40 Fahrzeuge und 40 Laufbänder (genau 5 je Welt).
- Fahrzeug-IDs 1–6: Fahrräder; 7–15: Mopeds; 16–27: Motorräder; 28–34: Supersportler; 35–40: Rennmaschinen.
- Starttraining: +1 Energy. Formel: `1 * (1 + Rebirths * 0.5) * Laufbandmultiplikator`. Rebirth setzt Energy auf 0 und erhöht Rebirths um 1. Der permanente Bonus wird aus Rebirths abgeleitet, nicht redundant gespeichert.
- 24 Eier mit jeweils 4 Pet-Arten = 96 Arten. Pet-Instanzen besitzen eigene String-IDs, eine SpeciesId und die Variante Normal/Golden/Rainbow. Maximal 3 verschiedene eigene Pets ausrüstbar.
- Fusion prüft 5 unterschiedliche Instanzen derselben normalen Art → Golden bzw. 3 derselben Golden-Art → Rainbow. Rainbow ist nicht weiter fusionierbar. Die Funktion liefert ein Ergebnis, mutiert aber kein Inventar; eine spätere Servertransaktion muss Verbrauch und Erstellung atomar ausführen.
- Welt 1 und Fahrzeug 1 gehören zum Startprofil. Weitere Welten sind ausschließlich mit Cash freischaltbar. Fahrzeugkäufe haben keine Weltbedingung.
- Rennen sind automatisch gegen Bots vorgesehen, mit Easy/Medium/Hard und Energy-Kosten 0. Die Infrastruktur enthält noch keinen Rennablauf oder Scheduler.

**Noch abzustimmendes Balancing:** Cash-Preise, Rebirth-Schwelle und Laufbandmultiplikatoren sind ausdrücklich provisorische zentrale Konfigurationswerte. IDs/Zuweisungen sind technische Katalogdaten, keine fertigen Assets. Pet-Stärken, Drop-Chancen, Rennbelohnungen und Bot-Geschwindigkeiten werden noch nicht erfunden oder implementiert.

Schema v1 speichert Energy, Cash, Rebirths, freigeschaltete Welten, Fahrzeuge, Pet-Instanzen und ausgerüstete Pet-IDs. Ungültige Zahlen (auch NaN/Unendlich), ungültige IDs, doppelte Equip-IDs und zu große Inventare werden abgelehnt. Höhere/unbekannte Schemas werden nicht zurückgesetzt; vor einer Schemaerhöhung ist eine explizite getestete Migration nötig.

## Remotes und Vertrauen

Der Server erzeugt `ReplicatedStorage.BikeRemotes`:

- `GetSnapshot` (**RemoteFunction**): ausschließlich `{ Version = 1 }`, höchstens eine Anfrage pro Spieler/Sekunde. Antwort `{ Ok = true, Data = {Energy, Cash, Rebirths} }` oder ein Fehler (`RateLimited`, `BadRequest`, `NotReady`). Die Identität stammt ausschließlich aus Roblox' serverseitigem Player-Argument.
- `SnapshotChanged` (**RemoteEvent**): Server → eigener Client, initial bzw. bei Änderungen; Prüfung einmal pro Sekunde. Kein Server-Handler für Client-Fires.

Clients senden niemals neue Guthaben, Pet-Inventare oder fremde UserIds. Es existieren bewusst keine schreibenden Gameplay-Remotes. Spätere Systeme müssen zusätzlich Berechtigungen, Besitz, Distanz/Zustand und Cooldowns auf dem Server prüfen. Shared-Code ist öffentlich einsehbar und keine Sicherheitsgrenze. Das HUD validiert Snapshots zusätzlich, ist aber keine Datenautorität.

## Persistenz und Ausfallverhalten

DataStore `BikeEvolution_Player_v1`, Schlüssel `Player_<UserId>`. Das gespeicherte Envelope enthält `Data` und eine serverseitige `Lock` mit eindeutiger Sitzungs-ID und Ablaufzeit.

- Laden und Schreiben ausschließlich mit `UpdateAsync`; jeder Callback prüft den aktuellen Lock erneut, auch bei Callback-Wiederholungen.
- 180 Sekunden Lease, Erneuerung durch Autosave alle 60 Sekunden. Aktive fremde Sitzungen verhindern das Laden. Abgelaufene Locks sind übernehmbar; alte Server dürfen danach nicht mehr speichern.
- Bis zu 3 Versuche pro Operation mit 2/4 Sekunden Pause. Writes pro Spieler werden serialisiert. Snapshots sind Kopien.
- Fehlgeschlagenes Laden, beschädigte Daten oder fremde aktive Locks führen zum Kick, niemals zum Speichern von Defaults über bestehende Daten.
- Fehlgeschlagenes Speichern nach allen Versuchen beendet die Sitzung. Der letzte erfolgreiche Stand bleibt erhalten; ein alter Lock läuft aus. Auch bei Lease-Ablauf werden keine weiteren HUD-Daten ausgegeben.
- `PlayerRemoving` speichert und gibt den Lock frei. `BindToClose` speichert parallel und wartet bis zu 25 Sekunden, inklusive noch laufender Loads. Live-Prozesse werden bei Neustarts nicht vorausgesetzt.

Dies reduziert Überschreibungen und Datenverluste, garantiert aber bei Roblox-Ausfällen, abruptem Prozessabbruch, Drosselung oder Shutdown-Zeitlimit keinen verlustfreien letzten Spielstand. Seit dem letzten erfolgreichen Save können Änderungen verloren gehen. Es gibt noch kein zusätzliches Backup-/Admin-Recovery-System; für einen Live-Launch sind Monitoring, DataStore-Versionswiederherstellung und Lasttests erforderlich. Nur eine aktive Serverinstanz darf künftig über einen kontrollierten Service Daten mutieren; aktuell ist absichtlich nur eine Snapshot-API öffentlich.

## Prüfungen

```sh
python3 tools/test.py
.tools/rojo build default.project.json --output build/BikeEvolutionSimulator.rbxlx
```

Der Test-Runner kompiliert **alle Produktionsdateien** mit dem echten Luau-Compiler. Für reine Module wird nur die Roblox-`require(script.Parent.X)`-Auflösung im temporären Testbundle angepasst; Geschäftslogik und Assertions bleiben unverändert. Diese Module werden im Strict-Modus typgeprüft. Tests laufen mit der echten Luau-VM, nicht als Python-Nachbau. Der CLI-Analyzer besitzt keine Roblox-Engine-Typdefinitionen; die Roblox-Service-/UI-Adapter benötigen zusätzlich Studio Script Analysis. CI führt dieselben CLI-Prüfungen aus.

**Ohne Roblox Studio nicht ausgeführt:**

1. Studio Script Analysis für Roblox-Service-/UI-Adapter; Play/Respawn und lesbare HUD-Darstellung auf Desktop/Mobilgeräten.
2. Reale DataStore-Berechtigungen, Throttling, Autosave nach 60 Sekunden, Leave/Rejoin und Shutdown-Speicherung in einer Test-Experience.
3. Zwei Live-Testserver mit konkurrierendem Profilzugriff, Lease-Verlust und Netzwerkunterbrechungen. Die zugrunde liegende Lock-Logik ist lokal gegen einen injizierten DataStore getestet.
4. Studio-Mehrspielerprüfung: jeder Client sieht nur eigene Werte; manipulierte `GetSnapshot`-Payloads und Spam liefern Fehler; `SnapshotChanged:FireServer(...)` ändert nichts. Engine-seitige Remote-Serialisierung und tatsächliches Rate-Limit-Timing sind CLI-seitig nicht verifiziert.

Für eine sichtbare Änderungsprüfung kann im **Server-Debugger einer separaten Test-Experience** ein Haltepunkt nach dem Laden gesetzt und `data.Cash` geändert werden. Danach erscheinen die Werte im HUD und nach erfolgreichem Autosave erneutem Beitritt. Dafür existiert absichtlich kein unsicherer Debug-Schreibremote.
