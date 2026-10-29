# V4.4 — Modellierte Trainingsprogression

Vollständige 40-Stufen-Tabelle: [PROGRESSION_V44.csv](PROGRESSION_V44.csv). Generator: `python3 tools/simulate_progression.py`.

Formel für Band i ≥ 2: `4 × 21 × (i−1) × 2^(i−2)` Energy. Vierfacher Schwierigkeitsfaktor genau einmal. Ertrag `2^(i−1)` pro Sekunde und pro gültigem Tap. Rebirth-Anforderung bleibt `3^(i−2)`. Band 1 ist frei. Weltzugang bleibt zusätzlich nötig.

Die frühere exponentielle Energy-Vervierfachung je Stufe bei lediglich verdoppeltem Ertrag führt mathematisch zu Jahren statt Stunden. V4.4 ersetzt deshalb diese Kurve durch wachsende Verweildauern mit einmaligem ×4-Schwierigkeitsfaktor. Das ist eine ausdrücklich dokumentierte Balancingänderung, keine Profilmigration. Erste Schwellen: 0 / 84 / 336 / 1008 / 2688. Rebirth 1/2: 1000/2000; ab dem dritten Rebirth (aktueller Zähler ≥2) `4 × 1000 × (Rebirths+1)`. Der bisherige Code enthielt keinen erschwerten Faktor; ×4 ist ein vorläufiger zentraler Wert.

Annahmen: alle Welten schon zugänglich, sofortiger Bandwechsel, reine Auto-Impulse, keine Tap-Boni, kein Weg-/Race-/Cash-/Offline-Aufwand. Rebirth-Zähler werden als bereits erworben angenommen; Kosten/Zeit dieser früheren Rebirths sind nicht enthalten. Nicht gebaute Welten bleiben unspielbar. Zeiten sind Vergleichsmodelle und kein Nachweis für echte 9–10 Stunden Endgame. Paid- und Pet-Boni verkürzen dieselbe Kurve bewusst; nicht alle Profile können bei einheitlichen Schwellen 9–10 Stunden benötigen.

| Profil | Stunden bis Band 40 |
|---|---:|
| Baseline | 9.555 |
| 3 Tropical Common | 7.350 |
| 3 Water Dragons | 1.647 |
| 5 Rebirths + pets | 0.468 |
| Energy pass + pets | 0.824 |
| Pass + potion + pets | 0.412 |

Energy-Gesamtfaktor: `(1 + 0.5 × Rebirths) × (1 + Summe(PetEnergy−1)) × EnergyPass × EnergyPotion`. Pass/Potion jeweils höchstens ×2. Cash entsprechend ohne Rebirthfaktor. Gleiche Tränke verlängern nur Dauer; kein weiterer Faktor. Golden/Rainbow skalieren die Pet-Überschüsse mit ×2/×4. Exklusiver Sunfox: Energy ×3, Cash ×2.8; drei Exemplare ergeben ×7/×6.4 additiv, keine Multiplikation untereinander. Alle Premiumwerte und Preise sind vorläufig; reale Produkte noch deaktiviert.

Die Potion-Spalte setzt durchgängig erneuerte Tränke voraus; ein einzelner Kauf wirkt nur 300 aktive Sekunden.
