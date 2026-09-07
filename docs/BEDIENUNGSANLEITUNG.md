# Bedienungsanleitung

## Zweck

Diese Anleitung beschreibt den praktischen Einsatz des Toolkits im IT-Support. Sie ist für den konkreten Ablauf auf einem Kunden-PC geschrieben.

## Zielbild

Der Support kopiert den vorbereiteten Ordner auf den Kunden-PC, startet `Performance Test.cmd`, bestätigt die notwendige Windows-Elevation, lässt freigegebene Tools installieren und erhält danach:

- `Abschlussbericht.html`
- `Rohbewertung.html`
- `Records.csv`
- `Run.zip`

## Schnellstart

1. Toolkit-Ordner lokal auf den Kunden-PC kopieren.
2. Falls nötig, freigegebene Zusatztools in `ToolkitPrograms\AutoInstall\` und `ToolkitPrograms\Optional\` ablegen.
3. `Performance Test.cmd` per Doppelklick starten.
4. Windows-UAC bestätigen.
5. Auf Abschluss des Laufs warten.
6. `Abschlussbericht.html` öffnen.
7. Bei Bedarf `Rohbewertung.html` und `Records.csv` nachziehen.

## Welche Datei wird beim Kunden gestartet

Primärer Kundenstart:

```powershell
.\Performance Test.cmd
```

Interner Ablauf:

```powershell
.\Performance Test.ps1
.\Start-Diagnose.ps1 -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools
```

## Was passiert beim Start

### 1. Elevation

`Performance Test.ps1` prüft, ob die Sitzung bereits mit Administratorrechten läuft. Wenn nicht, fordert Windows eine erhöhte Ausführung an.

Wichtig:

- Das Toolkit speichert kein Passwort.
- Das Toolkit umgeht keine Unternehmensrichtlinien.
- Die tatsächliche UAC-Führung kommt von Windows.

### 2. AutoInstall-Phase

Das Toolkit durchsucht zuerst:

- `ToolkitPrograms\AutoInstall\`

und verwendet nur die in `Config\tools.json` freigegebenen Dateien.

Fallback:

- `Installers\`

### 3. Datensammlung

Das Toolkit sammelt normalisierte Daten aus:

- Windows
- Storage
- Netzwerk
- Benchmarks
- Support-Tools
- Sensorik

### 4. Berichtserstellung

Am Ende werden HTML, CSV und ZIP gebaut.

## Empfohlene Ordnerbelegung

### Automatisch installierbare Tools

Diese Dateien gehören bevorzugt nach:

- `ToolkitPrograms\AutoInstall\`

Typische Beispiele:

- `cpu-z_2.18-en.exe`
- `TreeSizeFreeSetup.exe`
- `Unigine_Heaven-4.0.exe`
- `Wireshark-4.6.3-x64.exe`
- `CrystalDiskInfo.zip`
- `Autoruns.zip`
- `ProcessExplorer.zip`

### Optionale Tools

Diese Dateien gehören bevorzugt nach:

- `ToolkitPrograms\Optional\`

Beispiele:

- portable Diagnosetools
- Zusatz-Benchmarktools
- Tools für manuelle Einzelfallanalyse

## Empfohlener Support-Ablauf

### Variante A: schneller Kundeneinsatz

Nutze diese Variante für die meisten Fälle.

1. Toolkit kopieren
2. `Performance Test.cmd` starten
3. UAC bestätigen
4. Bericht abwarten
5. `Abschlussbericht.html` prüfen

### Variante B: technischer Vorabtest

Nutze diese Variante vor einer breiteren Verteilung oder nach Änderungen.

```powershell
.\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests -RunBenchmarks -RunSupportTools -OutputRoot .\ValidationOutput
```

### Variante C: gezielte Engineering-Nutzung

```powershell
.\Start-Diagnose.ps1 -DryRun
.\Start-Diagnose.ps1 -OutputRoot .\EngineeringOutput
```

## Wie die Ergebnisse gelesen werden

### Abschlussbericht.html

Dieser Bericht ist für die schnelle Triage gedacht.

Er beantwortet vor allem:

- Wo liegt wahrscheinlich die Ursache?
- Gibt es Warnungen?
- Welche nächsten Schritte sind sinnvoll?

### Rohbewertung.html

Dieser Bericht ist für technische Detailanalyse gedacht.

Er zeigt:

- alle normalisierten Datensätze
- Benchmarkvergleiche
- Severity-Einstufungen
- technische Rohhinweise

### Records.csv

Diese Datei ist ideal für:

- Filterung
- Sortierung
- Pivot-Auswertung
- Mehrlaufvergleich

### Run.zip

Diese Datei bündelt:

- Berichte
- Rohdaten
- Logs

Vor Weitergabe immer auf sensible Inhalte prüfen.

## Typische Ursachenbilder

### CPU- oder Prozesslast

Hinweise:

- auffällige Prozesse
- hohe CPU-Zeit
- Benchmark-Unterperformance

Nächster Schritt:

- betroffene Anwendung isolieren
- Zeitpunkt und Lastprofil vergleichen

### RAM-Engpass

Hinweise:

- hoher Speicherdruck
- viele parallele Prozesse
- Paging-/Storage-Folgen

Nächster Schritt:

- Hauptverbraucher prüfen
- mögliche Speicherlecks oder Browser-/Client-Last bewerten

### Storage-Probleme

Hinweise:

- wenig freier Speicher
- hohe I/O-Last
- Health-Warnungen über CrystalDiskInfo

Nächster Schritt:

- Datenträgerzustand prüfen
- TreeSize/Storage-Verteilung nachziehen

### Zu viele Autostarts

Hinweise:

- hohe `Autoruns:TotalEntries`
- viele problematische oder unsigned Einträge

Nächster Schritt:

- unnötige Drittanbieter-Autostarts reduzieren

### Thermische oder Sensor-bezogene Themen

Hinweise:

- Temperaturdaten
- fehlende Sensorik
- begrenzte Bewertung im Bericht

Nächster Schritt:

- Sensorquelle validieren
- Lauf ggf. unter besseren technischen Voraussetzungen wiederholen

## Grenzen des Toolkits

Das Toolkit ist bewusst konservativ.

Es macht nicht automatisch:

- Registry-Tuning
- Treiberänderungen
- Cleanup- oder Optimierungsmaßnahmen
- Deinstallationen
- automatische Netzwerkmitschnitte
- Passwortspeicherung

## Ausgeschlossene Tools

Nicht Teil des genehmigten Automationspfads sind insbesondere:

- PC-Putzer
- Revo Uninstaller
- CHIP-Wrapper-Installer

## GitHub- und Projektpflege

Für Quellcode-/Dokumentationspflege:

```powershell
.\Create-Distributions.ps1
```

Dadurch entstehen:

- `Distributions\Customer Toolkit\`
- `Distributions\GitHub Repository\`

## Checkliste vor Kundeneinsatz

- freigegebene Tools in `ToolkitPrograms\AutoInstall\` abgelegt
- optionale Tools in `ToolkitPrograms\Optional\` abgelegt
- Dry-Run erfolgreich
- letzter Testsatz erfolgreich
- Word- und Markdown-Doku aktuell
- keine sensiblen Altberichte im Kundenordner

## Checkliste nach Kundeneinsatz

- `Abschlussbericht.html` geprüft
- `Rohbewertung.html` geprüft
- `Records.csv` archiviert
- `Run.zip` auf sensible Inhalte geprüft
- Ergebnis und konkrete Symptome zusammen dokumentiert
