# World-1-Balancing — vorläufig

Autoritative Quelle: `src/shared/World1Content.luau`. Die vom Auftrag vorgegebenen Fahrzeugpreise ersetzen nur die bisherigen provisorischen Formeln für IDs 1–10. Klassen, IDs 11–40 und World-Unlock-Regeln bleiben erhalten.

| ID | Fahrzeug | Cash | Speed-Faktor |
| --- | --- | ---: | ---: |
| 1 | Mountainbike | 0 | 1 |
| 2 | City Bike | 250 | 1.06 |
| 3 | BMX | 750 | 1.12 |
| 4 | Road Bike | 2000 | 1.2 |
| 5 | Racing Bicycle | 5000 | 1.3 |
| 6 | Carbon Bike | 12000 | 1.42 |
| 7 | Classic Moped | 25000 | 1.55 |
| 8 | City Scooter | 50000 | 1.7 |
| 9 | Sport Moped | 100000 | 1.9 |
| 10 | Racing Moped | 200000 | 2.1 |

| Tier | Feste Bot-Tempi | Cash Plätze 1 bis 6 |
| --- | --- | --- |
| Easy | 22 / 24 / 26 / 28 / 30 | 200 / 150 / 110 / 80 / 60 / 40 |
| Medium | 34 / 37 / 40 / 43 / 46 | 700 / 450 / 250 / 130 / 75 / 45 |
| Hard | 55 / 59 / 63 / 67 / 71 | 2400 / 1500 / 600 / 200 / 90 / 50 |

Höhere Tiers belohnen gute Platzierung, statt Anfänger allein für garantiertes Verlieren auf Hard stark zu bevorteilen. Jeder Platz zahlt positiv: kein Start-Cash ist zum Fortschritt nötig. Rennen kosten weder Cash noch Energy. Noch keine täglichen Boni, Käufe mit Echtgeld oder Offline-Belohnungen.

Eier: Tropical 100 Cash, Jungle 750, Waterfall 4000. In jedem Ei Common 55 %, Uncommon 28 %, Rare 14 %, Legendary 3 % (exakt 10000 Integer-Gewichte). Innerhalb eines Eis steigen beide Boni mit der Seltenheit. Beispiele: Coconut Buddy Energy 1.1/Cash 1.05; Jungle Tiger 2/1.65; Water Dragon 2.6/2.2. Sämtliche zwölf Werte stehen zentral im Modul und werden im UI angezeigt.

Drei Pets stacken **additiv auf den Bonus über 1**. Golden/Rainbow skalieren diesen Bonus pro Pet um 2/4, ihre Maschinen bleiben Welt 4/5 vorbehalten. Rebirth multipliziert den gesamten Trainingsgewinn mit `1 + 0.5 × Rebirths`; Varianten und Boni ändern keine Rebirth-Voraussetzungen.

**Langfristiges Ziel 9–10 Stunden reines Training:** Das ist ein Designziel für alle acht Welten und noch kein nachgewiesenes Ergebnis. Dieser Build enthält nur Welt 1; spätere Eggs/Pets/Fahrzeugpreise und Endgame-Zielschwellen sind nicht festgelegt. Eine belastbare Gesamtzeit daraus zu behaupten wäre falsch. Vor Freigabe der späteren Welten mit realistischen Klick-/AFK-Raten, Rebirth-Strategien, erwarteten Hatch-Boni und Fusionen simulieren und anschließend per Telemetrie/Spieltests kalibrieren. Dafür keine erfundenen zukünftigen Werte als verbindlich einsetzen.
