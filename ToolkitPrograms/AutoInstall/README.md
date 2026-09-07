# AutoInstall

Lege hier die freigegebenen Dateien fuer den `Performance Test` ab.

## Zweck

Alle in `Config/tools.json` bekannten und fuer `AutoInstall` freigegebenen Programme werden aus diesem Ordner bevorzugt verarbeitet.

## Aktueller Support-Triage-Fokus

Besonders sinnvoll im aktuellen Projektstand:

- CPU-Z
- CrystalDiskInfo
- Autoruns
- Process Explorer
- Process Monitor
- Unigine Heaven

## Verhalten

- klassische Installer werden mit ihren festen Silent-Parametern ausgefuehrt
- portable EXE-Tools werden als `Prepared` behandelt und fuer den Lauf bereitgestellt
- wenn eine Datei hier nicht gefunden wird, nutzt das Toolkit weiterhin `Installers/` als Rueckfall

## Hinweise

- Unbekannte oder bewusst blockierte Programme werden nicht automatisch gestartet.
- HWiNFO und HWMonitor sind fachlich nuetzlich, werden aktuell aber nicht blind automatisiert installiert, solange keine verifizierten Silent-/Logparameter im Projekt hinterlegt sind.
