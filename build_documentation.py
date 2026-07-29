from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.enum.style import WD_STYLE_TYPE
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "PC-Performance-Diagnose-Dokumentation.docx"
BLUE, DARK, LIGHT, GRAY, MUTED = "2E74B5", "1F4D78", "E8EEF5", "F2F4F7", "666666"

def set_font(run, name="Calibri", size=11, color="000000", bold=None, italic=None):
    run.font.name = name
    rpr = run._element.get_or_add_rPr()
    rpr.rFonts.set(qn("w:ascii"), name); rpr.rFonts.set(qn("w:hAnsi"), name)
    run.font.size = Pt(size); run.font.color.rgb = RGBColor.from_string(color)
    if bold is not None: run.bold = bold
    if italic is not None: run.italic = italic

def shade(cell, fill):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = tcPr.find(qn("w:shd"))
    if shd is None: shd = OxmlElement("w:shd"); tcPr.append(shd)
    shd.set(qn("w:fill"), fill)

def cell_margins(cell):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = tcPr.first_child_found_in("w:tcMar")
    if tcMar is None: tcMar = OxmlElement("w:tcMar"); tcPr.append(tcMar)
    for name, value in (("top",80),("start",120),("bottom",80),("end",120)):
        node = tcMar.find(qn(f"w:{name}"))
        if node is None: node=OxmlElement(f"w:{name}"); tcMar.append(node)
        node.set(qn("w:w"), str(value)); node.set(qn("w:type"), "dxa")

def set_table_geometry(table, widths):
    table.alignment = WD_TABLE_ALIGNMENT.LEFT; table.autofit = False
    tblPr = table._tbl.tblPr
    tblW = tblPr.find(qn("w:tblW"))
    if tblW is None: tblW=OxmlElement("w:tblW"); tblPr.append(tblW)
    tblW.set(qn("w:w"), str(sum(widths))); tblW.set(qn("w:type"), "dxa")
    ind = tblPr.find(qn("w:tblInd"))
    if ind is None: ind=OxmlElement("w:tblInd"); tblPr.append(ind)
    ind.set(qn("w:w"), "120"); ind.set(qn("w:type"), "dxa")
    grid = table._tbl.tblGrid
    for child in list(grid): grid.remove(child)
    for width in widths:
        col=OxmlElement("w:gridCol"); col.set(qn("w:w"), str(width)); grid.append(col)
    for row in table.rows:
        for i, cell in enumerate(row.cells):
            cell.width=Inches(widths[i]/1440); cell.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER; cell_margins(cell)
            tcPr=cell._tc.get_or_add_tcPr(); tcW=tcPr.find(qn("w:tcW"))
            if tcW is None: tcW=OxmlElement("w:tcW"); tcPr.append(tcW)
            tcW.set(qn("w:w"), str(widths[i])); tcW.set(qn("w:type"), "dxa")

def add_table(doc, headers, rows, widths):
    table=doc.add_table(rows=1, cols=len(headers)); set_table_geometry(table,widths)
    for i, header in enumerate(headers):
        cell=table.rows[0].cells[i]; shade(cell,LIGHT); p=cell.paragraphs[0]; p.paragraph_format.space_after=Pt(0); set_font(p.add_run(header),size=10,color=DARK,bold=True)
    for row in rows:
        cells=table.add_row().cells
        for i, value in enumerate(row):
            p=cells[i].paragraphs[0]; p.paragraph_format.space_after=Pt(0); set_font(p.add_run(str(value)),size=9.5)
    doc.add_paragraph().paragraph_format.space_after=Pt(2)
    return table

def add_bullet(doc,text):
    p=doc.add_paragraph(style="List Bullet"); p.paragraph_format.space_after=Pt(4); p.paragraph_format.line_spacing=1.25; set_font(p.add_run(text)); return p

def add_number(doc,text):
    p=doc.add_paragraph(style="List Number"); p.paragraph_format.space_after=Pt(4); p.paragraph_format.line_spacing=1.25; set_font(p.add_run(text)); return p

def add_code(doc,text):
    p=doc.add_paragraph(style="Code Block"); set_font(p.add_run(text),name="Consolas",size=9,color="222222"); return p

def add_note(doc,label,text,fill=GRAY):
    t=doc.add_table(rows=1,cols=1); set_table_geometry(t,[9360]); c=t.cell(0,0); shade(c,fill); p=c.paragraphs[0]; p.paragraph_format.space_after=Pt(0)
    set_font(p.add_run(label+" "),size=10.5,color=DARK,bold=True); set_font(p.add_run(text),size=10.5); doc.add_paragraph().paragraph_format.space_after=Pt(2)

doc=Document(); sec=doc.sections[0]
sec.page_width=Inches(8.5); sec.page_height=Inches(11); sec.top_margin=sec.bottom_margin=sec.left_margin=sec.right_margin=Inches(1); sec.header_distance=sec.footer_distance=Inches(.492)
styles=doc.styles; normal=styles["Normal"]; normal.font.name="Calibri"; normal._element.rPr.rFonts.set(qn("w:ascii"),"Calibri"); normal._element.rPr.rFonts.set(qn("w:hAnsi"),"Calibri"); normal.font.size=Pt(11); normal.paragraph_format.space_after=Pt(6); normal.paragraph_format.line_spacing=1.25
for name,size,color,before,after in [("Heading 1",16,BLUE,18,10),("Heading 2",13,BLUE,14,7),("Heading 3",12,DARK,10,5)]:
    st=styles[name]; st.font.name="Calibri"; st._element.rPr.rFonts.set(qn("w:ascii"),"Calibri"); st._element.rPr.rFonts.set(qn("w:hAnsi"),"Calibri"); st.font.size=Pt(size); st.font.bold=True; st.font.color.rgb=RGBColor.from_string(color); st.paragraph_format.space_before=Pt(before); st.paragraph_format.space_after=Pt(after); st.paragraph_format.keep_with_next=True
st=styles.add_style("Code Block",WD_STYLE_TYPE.PARAGRAPH); st.font.name="Consolas"; st.font.size=Pt(9); st.paragraph_format.left_indent=Inches(.2); st.paragraph_format.space_before=Pt(3); st.paragraph_format.space_after=Pt(8); st.paragraph_format.line_spacing=1.0
hp=sec.header.paragraphs[0]; hp.alignment=WD_ALIGN_PARAGRAPH.LEFT; set_font(hp.add_run("PC Performance Diagnose  |  Dokumentation"),size=9,color=MUTED)
fp=sec.footer.paragraphs[0]; fp.alignment=WD_ALIGN_PARAGRAPH.RIGHT; set_font(fp.add_run("Interne Arbeitsunterlage  |  28. Juli 2026"),size=8.5,color=MUTED)

p=doc.add_paragraph(); p.paragraph_format.space_before=Pt(70); p.paragraph_format.space_after=Pt(8); set_font(p.add_run("PC PERFORMANCE DIAGNOSE"),size=25,color=DARK,bold=True)
p=doc.add_paragraph(); p.paragraph_format.space_after=Pt(18); set_font(p.add_run("Vollständige Dokumentation und Bedienungsanleitung"),size=15,color=BLUE)
p=doc.add_paragraph(); p.paragraph_format.space_after=Pt(28); set_font(p.add_run("Windows 10/11 x64  |  PowerShell  |  Read-only Diagnose mit HTML-, CSV- und ZIP-Ausgabe"),size=10.5,color=MUTED)
add_note(doc,"Kurzfassung:","Dieses Paket sammelt technische Hinweise zu typischen Performance-Ursachen, ohne automatisch zu bereinigen, zu tunen, Treiber zu ändern oder Netzwerkpakete mitzuschneiden.",LIGHT)
add_table(doc,["Dokument","Stand","Projektordner"],[["Bedienungs- und Referenzanleitung","28.07.2026","Performance Issues PC"]],[2100,1800,5460])
doc.add_page_break()

doc.add_heading("Inhalt",1)
for item in ["1. Zweck und Grenzen","2. Voraussetzungen und Ordnerstruktur","3. Installation und erster Start","4. Bedienung des Diagnosepakets","5. Diagnoseablauf und erfasste Daten","6. Tool-Allowlist und Sicherheitsregeln","7. Berichte lesen und Ursachen eingrenzen","8. Fehlerbehebung","9. Wartung und Erweiterung","10. Abschluss-Checkliste"]: add_bullet(doc,item)

doc.add_heading("1. Zweck und Grenzen",1)
doc.add_paragraph("Das Diagnosepaket unterstützt bei der strukturierten Untersuchung von langsamen oder instabilen Windows-PCs. Es erzeugt pro Ausführung einen eigenen Laufordner und führt Messungen sowie Abfragen zusammen, damit Ergebnisse zwischen mehreren Zeitpunkten verglichen oder an einen Support weitergegeben werden können.")
add_note(doc,"Wichtig:","Das Paket ist ein Diagnosewerkzeug, kein automatisches Reparatur- oder Tuningprogramm. Ein Bericht liefert Hinweise und Messwerte; er ersetzt keine technische Bewertung.","FFF8E8")
doc.add_heading("Was das Paket nicht tut",2)
for x in ["keine automatische Bereinigung oder Deinstallation","keine Registry-, Treiber- oder Energieplanänderung","keine gespeicherten Administratorpasswörter","keine automatische Wireshark-Paketaufzeichnung","keine vollautomatische Bedienung unbekannter Installer","keine automatische Reparatur aufgrund eines Messwertes"]: add_bullet(doc,x)

doc.add_heading("2. Voraussetzungen und Ordnerstruktur",1)
doc.add_heading("Voraussetzungen",2)
for x in ["Windows 10 oder Windows 11, 64-Bit","PowerShell 5.1 oder höher","ausreichend freier Speicher für Berichte und optional PCMark 10","Administratorfreigabe nur dann, wenn Windows oder ein Installer sie verlangt","für vollständige Sensor-/CIM-Abfragen kann eine erhöhte PowerShell erforderlich sein"]: add_bullet(doc,x)
doc.add_heading("Ordnerstruktur",2)
add_table(doc,["Ordner/Datei","Bedeutung"],[["Start-Diagnose.cmd","Doppelklick-Einstieg; reicht Parameter an PowerShell weiter."],["Start-Diagnose.ps1","Orchestriert Installation, Datensammlung, Tests und Bericht."],["Config\\diagnostics.json","Grenzwerte, Dauer und Sicherheitsoptionen."],["Config\\tools.json","Allowlist, Dateinamen, Hashes und Installationsschalter."],["Scripts\\","Getrennte Module für Collector, Installer, Sensoren und Report."],["Installers\\","Kopierte freigegebene Toolquellen; keine Ausführung beim Kopieren."],["Reports\\","HTML, CSV und ZIP je Lauf."],["Logs\\ / Raw\\","Rohprotokolle und normalisierte JSONL-Datensätze."],["Tests\\","Pester-Tests für Sicherheits- und Funktionsverhalten."]],[2700,6660])

doc.add_heading("3. Installation und erster Start",1)
doc.add_heading("3.1 Paket bereitstellen",2)
doc.add_paragraph("Der Projektordner enthält die kopierten Diagnosequellen. Beim Kopieren werden keine EXE-Dateien gestartet. Vor einer Weitergabe sollte der komplette Ordner in ein lokales Verzeichnis kopiert werden, nicht in einen synchronisierten Ordner mit eingeschränkten Rechten.")
doc.add_heading("3.2 Sicherer Probelauf",2)
doc.add_paragraph("Der erste Lauf sollte immer als Dry-Run erfolgen. Damit werden Pfade, Konfiguration, Berichtserzeugung und Allowlist geprüft, ohne Installer oder Stresstestprogramme zu starten.")
add_code(doc,'cd "C:\\Pfad\\Performance Issues PC"\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\Start-Diagnose.ps1 -DryRun -InstallTools -RunStressTests')
doc.add_heading("3.3 Normale Diagnose",2)
add_code(doc,'powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\Start-Diagnose.ps1')
add_note(doc,"UAC-Hinweis:","Das Skript speichert kein Passwort. Je nach Installer können mehrere Windows-UAC-Abfragen erscheinen; eine einzige Passwortabfrage für alle unterschiedlichen Installationsprogramme kann Windows nicht zuverlässig garantieren.","FFF8E8")

doc.add_heading("4. Bedienung des Diagnosepakets",1)
doc.add_heading("Startparameter",2)
add_table(doc,["Parameter","Wirkung"],[["-DryRun","Prüft Ablauf und erzeugt Berichte, startet aber keine Installer oder Stressprogramme."],["-InstallTools","Versucht die in tools.json als AutoInstall markierten Tools aus Installers\\ zu installieren."],["-RunStressTests","Fordert den Stress-Test-Abschnitt an; bei fehlender Sensorik wird sicher übersprungen."],["-OutputRoot <Pfad>","Legt den Root-Ordner für Reports, Logs und Raw fest."]],[2600,6760])
doc.add_heading("Empfohlene Reihenfolge",2)
for x in ["Dry-Run ausführen und die erzeugten Pfade prüfen.","Normale Diagnose ohne Stresstest durchführen.","HTML-Bericht auf Warnungen und fehlende Sensoren prüfen.","Nur wenn erforderlich: Installer-Allowlist mit -InstallTools verwenden.","Stresstest nur an einem beaufsichtigten, ausreichend gekühlten PC starten.","ZIP-Archiv erst nach Sichtprüfung der Datenschutzinhalte weitergeben."]: add_number(doc,x)
doc.add_heading("Ausgaben eines Laufs",2)
doc.add_paragraph("Nach erfolgreichem Lauf gibt PowerShell die drei Ergebnisdateien aus. Der Ordnername enthält eine Run-ID im Format YYYYMMDD-HHMMSS-fff.")
add_code(doc,'HTML: ...\\Reports\\<RunId>\\Report.html\nCSV:  ...\\Reports\\<RunId>\\Records.csv\nZIP:  ...\\Reports\\<RunId>\\Run.zip')

doc.add_heading("5. Diagnoseablauf und erfasste Daten",1)
add_table(doc,["Phase","Erfasste Hinweise","Typische Aussage"],[["Voraussetzungen","Windows-/PowerShell-Kontext, Pfade, Konfiguration","Kann der Lauf vollständig und sicher ausgeführt werden?"],["Windows","OS, Build, Uptime, Modell, RAM, Prozesse, Systemereignisse","Gibt es hohe Prozesslast, lange Laufzeit oder Fehlerereignisse?"],["Storage","Volumes, freier Speicher, PhysicalDisk-Health, Disk-Time","Ist ein Laufwerk voll, langsam oder auffällig?"],["Network","Adapter, IPv4, Gateway, DNS; kein Mitschnitt","Gibt es lokale Konfigurations- oder Erreichbarkeitsprobleme?"],["Sensoren","Temperatur-/Lastwerte, soweit zuverlässig verfügbar","Ist eine thermische Bewertung möglich?"],["Stress","begrenzte CPU-/GPU-Anforderung, bei fehlender Sensorik sicher übersprungen","Wie reagiert das System unter Last?"]],[1700,3750,3910])
add_note(doc,"Messwertqualität:","Nicht verfügbare Sensoren werden als Unavailable/Warning protokolliert. Ein fehlender Messwert darf nicht als 0 interpretiert werden.",LIGHT)

doc.add_heading("6. Tool-Allowlist und Sicherheitsregeln",1)
doc.add_heading("Kopierte Toolquellen",2)
add_table(doc,["Tool/Datei","Verwendung","Automatischer Installationsversuch"],[["CPU-Z","CPU, Mainboard, Speicherinformationen","Ja, fester Schalter /S"],["PCMark 10 ZIP","Gesamtbenchmark; manuell entpacken/prüfen","Nein"],["ProcessMonitor ZIP","Prozess-/Dateiaktivität; manuell starten","Nein"],["TreeSize Free","Speicherplatzanalyse","Ja, fester Schalter /S"],["Unigine Heaven","GPU-Test; beaufsichtigt","Ja, fester Schalter /silent"],["WiFi Analyzer","WLAN-Basisdiagnose","Nein"],["WinfrGUI","Dateiwiederherstellungs-Frontend; nicht für Performance nötig","Nein"],["Wireshark","Netzwerkdiagnose; kein automatischer Mitschnitt","Ja, fester Schalter /S"]],[2550,4200,2610])
doc.add_heading("Bewusst ausgeschlossene Dateien",2)
for x in ["PC-Putzer_ONLINE-setup.exe","revosetup.exe","GPU-Z - CHIP Installer _tWjyv.exe","Prime95 - CHIP Installer _i0jyv.exe"]: add_bullet(doc,x)
doc.add_paragraph("CHIP-Installer werden nicht verwendet, weil sie zusätzliche Bundles, Werbung oder unklare Installationsschritte enthalten können. Für GPU-/CPU-Diagnose sollten bei Bedarf offizielle Originalquellen beschafft und nach Prüfung separat in die Allowlist aufgenommen werden.")

doc.add_heading("7. Berichte lesen und Ursachen eingrenzen",1)
doc.add_heading("7.1 Erste Sichtung",2)
for x in ["Beginne mit Severity Critical/Warning.","Prüfe, ob die Warnung aus einem echten Messwert oder aus fehlender Berechtigung/Sensorik stammt.","Vergleiche Uptime, Speicher, freie Kapazität und Prozesslast mit dem Zeitpunkt, an dem die Störung auftrat.","Nutze das CSV für Zeitreihen oder Vergleiche mehrerer Läufe.","Öffne das ZIP erst lokal und entferne sensible Rohdaten, bevor es weitergegeben wird."]: add_number(doc,x)
doc.add_heading("7.2 Typische Hinweise",2)
add_table(doc,["Hinweis im Bericht","Mögliche Ursache","Nächster Prüfschritt"],[["Freier Speicher sehr niedrig","Temporäre Dateien, große Profile, Update-/Pagefile-Druck","TreeSize Free manuell prüfen; keine automatische Löschung durch das Paket."],["Hohe Disk-Time","I/O-intensive Prozesse, langsames Laufwerk, Paging","Prozess- und Datenträgerwerte zeitlich vergleichen."],["RAM knapp / Commit hoch","Viele Prozesse, Speicherleck, zu wenig RAM","Top-Prozesse und Pagefile prüfen; betroffene Anwendung isolieren."],["Viele Systemereignisse","Treiber-, Datenträger-, Dienst- oder WHEA-Hinweise","Ereignisdetails und Zeitpunkt mit der Störung abgleichen."],["Sensor Unavailable","Berechtigung, WMI/CIM, Tool nicht installiert oder Sensor nicht unterstützt","Lauf als Administrator wiederholen; Sensorquelle separat prüfen."],["Netzwerk Unavailable","CIM-/NetTCPIP-Berechtigung oder Adapterproblem","Adapter und DNS manuell in Windows prüfen."]],[2200,3150,4010])

doc.add_heading("8. Fehlerbehebung",1)
add_table(doc,["Problem","Ursache/Wirkung","Lösung"],[["Script execution disabled","PowerShell-Richtlinie blockiert Tests oder Start","Verwende den dokumentierten Einstieg mit -ExecutionPolicy Bypass; lokale Unternehmensrichtlinien nicht eigenmächtig ändern."],["Access denied bei CIM/WMI","Nicht erhöhte Sitzung oder eingeschränkter Dienst","PowerShell als Administrator starten und Lauf wiederholen."],["Installer wird nicht gestartet","Datei fehlt, Hash/Manifest passt nicht oder AutoInstall=false","Pfad/Dateiname prüfen; unbekannte Installer nicht blind freischalten."],["ZIP/HTML fehlt","Schreibrechte oder OutputRoot nicht erreichbar","Lokalen, beschreibbaren OutputRoot verwenden."],["Stresstest übersprungen","Keine zuverlässige Temperatursensorik","Sensorquelle prüfen; Stresstest nicht ohne Überwachung erzwingen."],["Bericht enthält sensible Daten","Rohlogs enthalten System-/Netzwerkinformationen","Vor Weitergabe prüfen, kopieren oder redigieren."]],[2200,3150,4010])

doc.add_heading("9. Wartung und Erweiterung",1)
for x in ["Neue Tools nur nach Quellenprüfung, SHA256-Erfassung und Eintrag in Config\\tools.json hinzufügen.","Silent-Schalter niemals aus Benutzereingaben zusammensetzen; nur feste Argumentarrays im Manifest verwenden.","Jede neue Funktion mit einem Dry-Run und einem Pester-Test absichern.","Bei Änderungen an Reportformat oder Grenzwerten die Dokumentation und diagnostics.json gemeinsam aktualisieren.","Vor einer Freigabe die vollständige Testsuite sowie einen Dry-Run ausführen."]: add_bullet(doc,x)
doc.add_heading("Konfiguration der Grenzwerte",2)
add_table(doc,["Einstellung","Standard","Bedeutung"],[["CpuDurationSeconds","600","Maximale CPU-Testdauer in Sekunden."],["GpuDurationSeconds","600","Maximale GPU-Testdauer in Sekunden."],["SampleIntervalSeconds","5","Messintervall während eines Tests."],["WarningTemperatureC","85","Warnschwelle in °C."],["AbortTemperatureC","95","Abbruchschwelle in °C."],["AutoPacketCapture","false","Muss false bleiben, wenn keine bewusste Paketaufnahme beauftragt ist."]],[2800,1500,5060])

doc.add_heading("10. Abschluss-Checkliste",1)
for x in ["[ ] Dry-Run erfolgreich ausgeführt","[ ] Keine ausgeschlossenen Installer im Projektordner","[ ] Reports-, Logs- und Raw-Verzeichnisse beschreibbar","[ ] Diagnose ohne automatische Reparatur durchgeführt","[ ] Warnungen und fehlende Sensorwerte bewertet","[ ] ZIP vor Weitergabe auf sensible Inhalte geprüft","[ ] Bericht und CSV zusammen mit Run-ID archiviert"]: add_bullet(doc,x)
add_note(doc,"Support-Hinweis:","Für eine belastbare Ursachenanalyse immer Zeitpunkt, konkrete Symptome, aktive Anwendung und Energie-/Netzsituation zusammen mit dem Run-Archiv dokumentieren.",LIGHT)

doc.save(OUT)
print(OUT)

