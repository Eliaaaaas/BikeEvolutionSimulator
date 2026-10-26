# Pet Equip V3

## Einmaliges EQUIP BEST

Der farbige Button **⚡ EQUIP BEST** im Pet-Inventar schickt ausschließlich einen Intent mit Request-ID. Der Server bewertet alle verfügbaren Inventarinstanzen, einschließlich bereits ausgerüsteter Pets, und ersetzt die Equip-Liste durch höchstens drei IDs. Inventareinträge, Varianten und Währungen bleiben unverändert. Es gibt keinen gespeicherten oder dauerhaft aktiven Auto-Equip-Modus.

Die vorhandenen Bonusregeln bleiben erhalten:

```
Variantenfaktor F: Normal=1, Golden=2, Rainbow=4
Effektive Energy E = 1 + (Energy-Basismultiplikator - 1) * F
Effektiver Cash   C = 1 + (Cash-Basismultiplikator   - 1) * F
Score = ((E - 1) + (C - 1)) / 2
```

Beide Boni zählen gleich. Da die bestehenden Equip-Boni additiv über den Bonus über 1 stacken, maximiert die Auswahl der drei höchsten Scores den gleich gewichteten Gesamtbonus. Es ist keine Optimierung ausschließlich für Energy und auch keine Multiplikation aller Pet-Faktoren miteinander. Ein Pet mit weniger Energy kann durch mehr Cash insgesamt stärker sein.

Bei gleichem Score werden bereits ausgerüstete Instanzen mit ihrer aktuellen Slotreihenfolge bevorzugt; danach entscheidet die lexikografische Inventar-ID. Das sorgt für reproduzierbare Auswahl ohne zufälligen Austausch bei Gleichstand. Mehrere gleiche Arten/Varianten bleiben unterschiedliche Instanzen und können mehrere Slots belegen.

## Hatch und UNEQUIP ALL

Nur ein erfolgreicher, tatsächlich neuer Hatch darf `equipHatched()` aufrufen, innerhalb derselben Copy/Validate/Commit-Transaktion wie Cash-Abzug, Inventar und Entdeckung. Bei weniger als drei Equips wird genau die neue Instanz ergänzt. Bei vollen Slots bleibt sie im Inventar; kein bereits ausgerüstetes Pet wird ersetzt, unabhängig von der Stärke des neuen Pets.

**UNEQUIP ALL** leert die Equip-Liste einmalig. Weder Snapshot-Abfragen noch Autosave, Rejoin, Inventaröffnung oder Änderungen an bestehenden Pets füllen Slots wieder. Erst ein neuer Hatch kann genau das neu erhaltene Pet in einen freien Slot setzen. Manuelle Einzelwahl und EQUIP BEST funktionieren jederzeit unter den bestehenden Regeln, einschließlich der Sperre wirtschaftlicher Aktionen während Rennen.

Nach erfolgreichen Hatch-/Equip-Aktionen sendet der Server direkt einen bestätigten Inventar-Snapshot. Die UI aktualisiert Slots und beide Boni damit sofort nach Bestätigung, ohne auf den periodischen Snapshot-Tick zu warten. Die drei sichtbaren Begleiter verwenden weiterhin dieselben replizierten Equip-Daten.

## Verfügbarkeit und Sicherheit

Ein ausrüstbares Pet muss im Spielerinventar vorhanden sein, eine gültige Variante besitzen und eine bereits spielbare Katalogart referenzieren. Noch offene/gesperrte Katalogarten werden nicht mit erfundenen Boni bewertet und nicht neu ausgerüstet. Das bestehende Schema hat kein separates individuelles Lock-Feld; V3 führt kein zusätzliches Lock-System ein. Fehlende/verbrauchte IDs werden abgewiesen. Bereits gespeicherte Inventare werden nicht gelöscht oder zurückgesetzt.

`EquipBest` und `UnequipAll` verwenden die bestehende strikte Remote-Allowlist, monotone Request-IDs, gemeinsame Rate-Limits und validierte serverseitige Profiltransaktionen. Der Client kann weder Kandidatenliste noch Score, Multiplikatoren oder Slotzahl vorgeben. Fehlgeschlagene Transaktionen erzeugen keine erfolgreiche Equip-Rückmeldung und ändern die gespeicherte Liste nicht.

24 Eier, 96 Pet-Arten und drei Slots bleiben unverändert. Keine Schemaänderung oder Migration. Inventar-IDs und `EquippedPets` werden weiterhin in der bestehenden sicheren Speicherarchitektur persistiert. Normale Spielserver greifen auf denselben Store zu; während Entwicklung/Tests werden ausschließlich Fixtures/Engine-Doubles benutzt.

## Golden-/Rainbow-Fusionsvorbereitung

In Welt 1 bleiben die Maschinen gesperrt. Die vorhandenen Rezepte bleiben fünf identische Normal-Pets → Golden und drei identische Golden-Pets → Rainbow; Golden erst Welt 4, Rainbow erst Welt 5.

Der neue **serverinterne** Helfer `PetRules.fuse(candidate, ingredientIds, freshId)` ist für die spätere Anbindung vorbereitet; er hat keinen Remote und keine neue Maschine. Auf einem Transaktionskandidaten prüft er Rezept, Weltenzugang, Verfügbarkeit und eine neue eindeutige ID. Erst danach entfernt er die Zutaten. Sind Zutaten ausgerüstet, ersetzt das Ergebnis sie genau einmal am ersten betroffenen Slot; andere aktive Instanzen bleiben erhalten. Sind alle Zutaten unausgerüstet, bleibt auch das Ergebnis unausgerüstet. Es gibt kein automatisches Nachfüllen aus anderen vorhandenen Pets. Ein künftiger Aufrufer muss den Helfer über `PlayerDataService.change(..., true)` aufrufen, damit Validierung, atomarer Commit und Inventarrevision erhalten bleiben.

## Tests und manuelle Prüfung

14 neue Pet-Regel-/Ökonomietests prüfen Hatch-Slots, kein Ersetzen voller Slots, UNEQUIP ALL, Mischbewertung, Golden/Rainbow, identische Instanzen, gesperrte/fehlende/verbrauchte IDs, Request-Sicherheit, Speichern/Restore, beide Boni, Fusion-Slotpflege und fehlgeschlagene Commits. Zwei zusätzliche Runtime-Tests führen die echten Inventar-/Hatch-Buttons über Client, Remotes und Server mit Engine-Doubles aus; sie prüfen unter anderem den sofortigen bestätigten Snapshot und leere Slots nach Rejoin. Bestehende Hatch-Erwartungen wurden an das ausdrücklich neue automatische Ausrüsten angepasst.

**Roblox-Studio-Prüfung: NICHT AUSGEFÜHRT.** In separater Test-Experience prüfen: erstes/zweites/drittes Pet hatchen; viertes stärkeres Pet bleibt im Inventar; EQUIP BEST einmal drücken; UNEQUIP ALL und Inventar erneut öffnen; anschließend neues Ei hatchen; Einzelwahl; Trainings-/Rennboni; Autosave/Leave/Rejoin. Normale, Golden- und Rainbow-Fixtures sowie Fusions-Slotfälle ausschließlich in einer isolierten Testumgebung prüfen. Keine Maschinen in Welt 1 freischalten und keine produktiven Daten bearbeiten. Der HUD-Vertrag Visual Upgrade V2 gilt unverändert.
