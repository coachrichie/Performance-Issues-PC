# PC Performance Diagnostics Design

## Ziel

Ein transportierbarer Diagnoseordner für Windows 10/11 x64, der die freigegebenen Prüfwerkzeuge optional installiert, Windows- und Drittanbieterdiagnosen ausführt, begrenzte CPU-/GPU-Stresstests überwacht und pro Lauf einen HTML-Bericht, CSV-Rohdaten sowie ein ZIP-Archiv erzeugt.

## Nutzerentscheidungen

- Vorhandene Tools werden in einen neuen, eigenständigen Projektordner kopiert.
- Installationen laufen bevorzugt unbeaufsichtigt, aber nur mit bekannten, explizit hinterlegten Parametern.
- Nicht kompatible Installer werden nicht blind bedient; sie werden als Ausnahme protokolliert und können sichtbar geöffnet werden.
- Der Benutzer gibt kein Passwort an das Skript weiter. Erledigte UAC-Abfragen werden nur als Status protokolliert.
- Ausgabe: HTML-Bericht, CSV-Rohdaten und ZIP-Archiv einschließlich Original-Logs.
- CPU- und GPU-Stresstest: jeweils standardmäßig 10 Minuten, temperaturüberwacht und abbrechbar.
- Wireshark darf installiert werden, führt aber keine automatische Paketaufzeichnung durch.

## Sicherheits- und Datenschutzgrenzen

Die Automatisierung führt keine Bereinigung, Deinstallation, Registry-Optimierung, Treiberänderung oder Netzwerkkonfigurationsänderung durch. `PC-Putzer`, Revo Uninstaller und CHIP-Installer stehen nicht auf der automatischen Allowlist. Wireshark erfasst keine Paketinhalte. Rohdaten können Gerätenamen, Benutzername, Prozessnamen, Pfade, Ereignisdetails und Netzwerkkonfiguration enthalten; der Bericht weist darauf hin, bevor ein Archiv weitergegeben wird.

## Architektur

`Start-Diagnose.ps1` ist der Einstiegspunkt und prüft Windows-Version, 64-Bit-Kontext, Schreibrechte, verfügbare Werkzeuge und Administratorstatus. Es erzeugt eine Run-ID und delegiert an fokussierte Module:

- `Install-Tools.ps1`: Manifest-basierte, optionale Installation der freigegebenen Tools.
- `Collect-Windows.ps1`: Systeminformationen, Task-Manager-nahe Momentaufnahmen, Prozesse, Dienste, Autostart, Ereignisprotokolle, Energie-/Leistungsindikatoren und Netzwerkbasisdaten.
- `Collect-Storage.ps1`: Volumes, freier Speicher, Datenträgeraktivität, Dateisystem- und SMART-Informationen soweit durch Windows verfügbar.
- `Collect-Sensors.ps1`: CPU-/GPU-Temperatur, Lüfter-/Takt-/Lastwerte, soweit ein unterstütztes Tool oder eine zuverlässige Windows-Schnittstelle verfügbar ist.
- `Run-StressTests.ps1`: begrenzte Prime95-/Unigine-Heaven-Läufe; Start nur nach Prüfung der Messbarkeit, Abbruch bei Grenzwertüberschreitung, Zeitüberschreitung oder Benutzerabbruch.
- `Build-Report.ps1`: normalisiert Ergebnisse, erstellt CSV, HTML und ZIP.

Jedes Modul liefert strukturierte Datensätze mit `RunId`, `Timestamp`, `Category`, `Name`, `Value`, `Unit`, `Severity`, `Source` und `Message`. Fehler eines Moduls beenden nicht den gesamten Lauf; sie werden mit Schweregrad `Error` oder `Warning` erfasst und im Bericht angezeigt.

## Freigegebene Tool-Allowlist

Die initiale Allowlist umfasst CPU-Z, GPU-Z, PCMark 10, Prime95, Process Monitor, TreeSize Free, Unigine Heaven, WiFi Analyzer, WinfrGUI und Wireshark. Die vorhandenen Dateien werden anhand eines Manifestes mit erwarteten Dateinamen, optionalen Hashes, Installationsmodus und Prüfzweck verwaltet. CHIP-Installer werden ausgeschlossen. Quellen und Versionen werden im Bericht und in `ToolInventory.csv` festgehalten. Das Projekt lädt ohne explizite spätere Freigabe keine zusätzliche Software aus dem Internet herunter.

## Diagnoseumfang

Der Lauf erfasst mindestens:

- Windows-Version, Build, Uptime, BIOS-/Firmware- und Gerätemodell.
- CPU-Modell, Kerne/Threads, Frequenz und Temperatur, falls verfügbar.
- RAM gesamt, belegt, verfügbar, Commit-Auslastung und auffällige Prozesse.
- Datenträgerbelegung, freie Kapazität, Antwort-/Aktivitätswerte, SMART-Zustand soweit verfügbar.
- CPU-, RAM-, Datenträger- und Netzwerkaktivität als Momentaufnahme und wiederholte Stichprobe während der Tests.
- Prozesse, Dienste, Autostart, Pagefile, Energieplan und relevante Windows-Ereignisse.
- Netzwerkadapter, IP/DNS/Gateway und einfache Erreichbarkeitstests ohne Paketmitschnitt.
- Toolinstallation, Laufzeit, Exitcode, Warnungen und fehlende Messwerte.

Der Bericht markiert Grenzwertverletzungen als `Critical`, `Warning` oder `Info`. Ein fehlender Sensor wird ausdrücklich als „nicht verfügbar“ statt als Nullwert ausgegeben.

## Ablauf

1. Benutzer startet `Start-Diagnose.cmd` oder `Start-Diagnose.ps1`.
2. Das Skript legt einen Run-Ordner an und prüft Voraussetzungen.
3. Optional werden Allowlist-Tools mit bekannten Silent-Schaltern installiert; jeder Versuch wird protokolliert.
4. Windows- und Toolinventar werden gesammelt.
5. Basismessung und Ereignis-/Speicher-/Datenträgeranalyse laufen.
6. Nach einer sichtbaren Sicherheitsbestätigung starten die 10-Minuten-CPU- und GPU-Tests nacheinander. Bei fehlender Sensorik werden sie übersprungen.
7. Alle Logs werden normalisiert, bewertet und in HTML/CSV geschrieben.
8. Der vollständige Laufordner wird als ZIP neben dem HTML-Bericht abgelegt.

## Konfiguration

`Config\diagnostics.json` enthält Testdauer, Temperaturgrenzen, Stichprobenintervall, Pfade, Allowlist und Verhalten bei nicht unterstützten Installern. Standardwerte sind CPU 10 Minuten, GPU 10 Minuten, Stichprobe 5 Sekunden, Warnung bei 85 °C und Abbruch bei 95 °C; die Grenzwerte werden vor einem Lauf angezeigt und dürfen nicht automatisch verschärft werden.

## Verifikation

Die Skripte werden ohne Installation realer Tools mit Testmanifesten und temporären Run-Ordnern geprüft. Tests decken Manifest-Allowlisting, Pfadvalidierung, JSON-Konfiguration, Normalisierung fehlender Sensorwerte, Grenzwertentscheidungen, Exitcode-/Fehlerprotokollierung sowie deterministische Berichtserzeugung ab. Zusätzlich erfolgt ein manueller Dry-Run, der keine Installer startet und keine Paketaufzeichnung ausführt.

## Bewusste Nichtziele

Keine automatische Reparatur, Tuning-Empfehlung mit Änderungsaktion, dauerhafte Hintergrundüberwachung, Cloud-Upload, automatische Netzwerkpaketaufzeichnung, Passwortspeicherung oder vollautomatische Bedienung unbekannter Installer.
