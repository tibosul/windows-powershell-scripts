# 🛠️ System Toolkit - Documentație Completă

**Versiune:** 1.0
**Autor:** Script PowerShell pentru optimizarea și mentenanța Windows
**Compatibilitate:** Windows 10/11

---

## 📋 **Cuprins**

1. [Prezentare Generală](#prezentare-generală)
2. [Instalare și Rulare](#instalare-și-rulare)
3. [Funcții Detaliate](#funcții-detaliate)
4. [Ghid de Utilizare](#ghid-de-utilizare)
5. [Probleme Cunoscute și Soluții](#probleme-cunoscute-și-soluții)
6. [Backup și Siguranță](#backup-și-siguranță)

---

## 🎯 **Prezentare Generală**

**System Toolkit** este un script PowerShell complet pentru optimizarea, curățarea și mentenanța sistemelor Windows. Oferă 15 funcții specializate pentru diferite aspecte ale administrării sistemului.

### ✨ **Caracteristici Principale:**
- Interface interactivă cu meniu colorat
- Funcții de curățare și optimizare automată
- Diagnosticare și raportare completă
- Suport pentru SQL Server Express și Standard
- Mod Gaming pentru performanță maximă
- Backup automat și restore points

---

## 🚀 **Instalare și Rulare**

### **Cerințe Sistem:**
- Windows 10/11
- PowerShell 5.1+ (preinstalat)
- Drepturi de Administrator (pentru majoritatea funcțiilor)

### **Instalare:**
1. Copiază `SystemToolkit.ps1` în directorul `C:\Scripts\`
2. Deschide PowerShell ca Administrator
3. Navighează la directorul script-urilor:
   ```powershell
   cd C:\Scripts
   ```
4. Rulează script-ul:
   ```powershell
   .\SystemToolkit.ps1
   ```

### **Setări Execution Policy (dacă e necesar):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🔧 **Funcții Detaliate**

### **[1] 🧹 Curățare Rapidă (Temp + Cache)**

**Descriere:** Șterge fișiere temporare și cache pentru eliberarea spațiului pe disk.

**Ce face exact:**
- Șterge conținutul din `$env:TEMP\*`
- Curăță `C:\Windows\Temp\*`
- Șterge `C:\Windows\Prefetch\*`
- Golește Recycle Bin
- Calculează și afișează spațiul eliberat

**Când să folosești:**
- ✅ Zilnic sau săptămânal pentru mentenanță de rutină
- ✅ Când rămâi fără spațiu pe disk
- ✅ După instalarea/dezinstalarea multor programe

**Risc:** 🟢 **Minim** - Șterge doar fișiere temporare sigure

**Durată:** 1-2 minute

---

### **[2] 🚀 Optimizare Completă Sistem**

**Descriere:** Rulează script-ul `WindowsFullOptimization.ps1` pentru optimizare avansată.

**Ce face exact:**
- Execută script-ul de optimizare externă
- Optimizări complexe pentru performanță
- Curățare avansată registry și servicii

**Când să folosești:**
- ✅ Lunar pentru mentenanță completă
- ✅ Când sistemul devine lent
- ✅ După upgrade-uri majore Windows

**Risc:** 🟡 **Mediu** - Poate necesita repornire, modifică setări sistem

**Durată:** 10-30 minute

**⚠️ Atenție:** Creează restore point înainte!

---

### **[3] 📦 Actualizare Toate Aplicațiile**

**Descriere:** Actualizează toate aplicațiile din sistem folosind multiple managere de pachete.

**Ce face exact:**
- **Winget:** `winget upgrade --all --silent`
- **Chocolatey:** `choco upgrade all -y` (dacă e instalat)
- **Microsoft Store:** Declanșează actualizări automate

**Când să folosești:**
- ✅ Săptămânal pentru securitate
- ✅ Înainte de proiecte importante
- ✅ După patch Tuesday (a doua marți din lună)

**Risc:** 🟢 **Minim** - Poate necesita reporniri pentru unele aplicații

**Durată:** 5-20 minute (depinde de numărul de actualizări)

---

### **[4] 🛡️ Scanare Securitate Completă**

**Descriere:** Scanare antivirus completă folosind Windows Defender.

**Ce fade exact:**
- Actualizează definițiile antivirus: `Update-MpSignature`
- Pornește scan complet în background: `Start-MpScan -ScanType FullScan -AsJob`
- Verifică amenințările existente: `Get-MpThreatDetection`

**Când să folosești:**
- ✅ Săptămânal pentru rutină
- ✅ La suspiciuni de malware
- ✅ După descărcarea de fișiere dubioase
- ✅ Înainte de backup-uri importante

**Risc:** 🟢 **Minim** - Rulează în background

**Durată:** 30-120 minute (în background)

**💡 Tip:** Lasă computerul pornit pentru finalizarea scanării

---

### **[5] 🔧 Reparare Fișiere Sistem (SFC + DISM)**

**Descriere:** Repară fișierele de sistem corupte folosind utilitare Windows native.

**Ce face exact:**
- **SFC:** `sfc /scannow` - Verifică integritatea fișierelor sistem
- **DISM:** `DISM /Online /Cleanup-Image /RestoreHealth` - Repară imaginea Windows

**Când să folosești:**
- ✅ La erori BSOD (Blue Screen of Death)
- ✅ Fișiere sistem corupte
- ✅ Windows Update eșuează
- ✅ Aplicații se blochează frequent

**Risc:** 🟡 **Mediu-Ridicat** - Poate dura mult, poate necesita repornire

**Durată:** 15-60 minute

**⚠️ Atenție:** Rulează DOAR ca Administrator!

---

### **[6] 🌐 Reset Complet Rețea**

**Descriere:** Resetează complet toate setările de rețea la valorile implicite.

**Ce face exact:**
- Reset Winsock: `netsh winsock reset`
- Reset TCP/IP: `netsh int ip reset`
- Flush DNS: `ipconfig /flushdns`
- Release IP: `ipconfig /release`
- Renew IP: `ipconfig /renew`
- Reset Windows Firewall: `netsh advfirewall reset`

**Când să folosești:**
- ✅ Probleme de conexiune la internet
- ✅ Erori DNS sau IP conflict
- ✅ După infecții cu malware de rețea
- ✅ VPN-uri rămase "agățate"

**Risc:** 🔴 **Ridicat** - Resetează TOATE setările de rețea

**Durată:** 2-5 minute + repornire OBLIGATORIE

**⚠️ ATENȚIE:**
- Vei pierde setările de rețea personalizate
- IP-uri statice vor fi resetate
- Repornirea este obligatorie

---

### **[7] 💾 Backup Registry + Restore Point**

**Descriere:** Creează punct de restaurare pentru protecție înainte de modificări.

**Ce face exact:**
- Activează System Restore: `Enable-ComputerRestore -Drive "C:\"`
- Creează restore point: `Checkpoint-Computer -Description "Manual Backup"`

**Când să folosești:**
- ✅ Înainte de instalarea software-ului suspect
- ✅ Înainte de modificări majore în sistem
- ✅ Lunar pentru backup preventiv
- ✅ Înainte de rularea altor funcții riscante

**Risc:** 🟢 **Zero** - Doar creează backup

**Durată:** 1-3 minute

**Spațiu folosit:** 300MB - 1GB (depinde de modificările sistemului)

---

### **[8] 📊 Raport Complet Sistem**

**Descriere:** Generează raport detaliat cu informații complete despre sistem.

**Ce include:**
- **Hardware:** CPU, RAM, Storage, Temperaturi
- **Sistem:** Versiune Windows, servicii importante
- **Rețea:** Adaptoare active, viteze conexiune
- **Securitate:** Status Windows Defender
- **Performanță:** Top 10 procese după CPU
- **Storage:** Utilizare disk pe drive-uri

**Când să folosești:**
- ✅ Pentru diagnostic probleme
- ✅ Înainte de service/suport tehnic
- ✅ Documentare sistem pentru IT
- ✅ Monitorizare performanță în timp

**Risc:** 🟢 **Zero** - Doar citește informații

**Durată:** 30 secunde

**Output:** Fișier TXT pe Desktop cu timestamp

---

### **[9] ⚡ Optimizare SQL Server**

**Descriere:** Optimizează performanța SQL Server (Standard sau Express).

**Ce face exact:**
- Detectează servicii: `MSSQLSERVER` sau `MSSQL$SQLEXPRESS`
- Pornește serviciul dacă e oprit
- Setează prioritate HIGH pentru procesul `sqlservr`
- Șterge log-uri vechi (>30 zile) din directorul SQL

**Când să folosești:**
- ✅ SQL Server rulează lent
- ✅ Query-uri durează mult
- ✅ După instalarea SQL Server
- ✅ Probleme de performanță baze de date

**Risc:** 🟡 **Mediu** - Prioritatea mare poate afecta alte aplicații

**Durată:** 1-2 minute

**⚠️ Note:**
- Funcționează cu SQL Server Express și Standard
- Necesită SQL Server instalat
- Poate afecta performanța altor aplicații (prioritate HIGH)

---

### **[10] 🔍 Găsește Fișiere Mari (>1GB)**

**Descriere:** Scanează toate drive-urile pentru fișiere mari care ocupă spațiu.

**Ce face exact:**
- Scanează toate drive-urile disponibile
- Găsește fișiere mai mari de 1GB
- Sortează descrescător după mărime
- Afișează top 20 cele mai mari fișiere

**Când să folosești:**
- ✅ Când rămâi fără spațiu pe disk
- ✅ Pentru curățare înainte de backup
- ✅ Pentru identificarea fișierelor uitate
- ✅ Audit utilizare spațiu

**Risc:** 🟢 **Zero** - Doar scanează, nu șterge nimic

**Durată:** 2-10 minute (depinde de cantitatea de date)

**💡 Tip:** Poți șterge manual fișierele identificate după verificare

---

### **[11] 🎮 Mod Gaming (Optimizare pentru jocuri)**

**Descriere:** Optimizează sistemul pentru performanță maximă în jocuri.

**Ce face exact:**
- **Oprește servicii inutile:**
  - `SysMain` (Superfetch)
  - `WSearch` (Windows Search)
  - `DiagTrack` (Telemetry)
  - `MapsBroker`, `RemoteRegistry`, `Spooler`
- **Prioritate HIGH pentru gaming:**
  - Steam, Origin, Epic Games, Battle.net, GOG
- **Optimizare NVIDIA:**
  - Oprește NVIDIA Telemetry
- **Windows Game Mode:** Activare automată

**Când să folosești:**
- ✅ Înainte de sesiuni gaming
- ✅ Pentru jocuri competitive (FPS, esports)
- ✅ Când jocurile se lagă
- ✅ Sisteme cu resurse limitate

**Risc:** 🟡 **Mediu** - Dezactivează funcții Windows, poate afecta alte aplicații

**Durată:** 1 minut

**⚠️ Efecte secundare:**
- Windows Search nu va funcționa temporar
- Printarea poate fi afectată
- Unele funcții Windows vor fi mai lente

---

### **[12] 📝 Verificare și Instalare C++ Redistributables**

**Descriere:** Verifică și instalează Microsoft Visual C++ Redistributable packages.

**Ce instalează:**
- Visual C++ 2015-2022 (x64 și x86)
- Visual C++ 2013 (x64 și x86)
- Folosește Winget cu ID-uri alternative

**Când să folosești:**
- ✅ Erori "MSVCR120.dll is missing"
- ✅ "VCRUNTIME140.dll not found"
- ✅ Jocuri sau aplicații nu pornesc
- ✅ După instalarea Windows fresh

**Risc:** 🟢 **Minim** - Instalează doar componente Microsoft oficiale

**Durată:** 3-10 minute

**💡 Tip:** Rezolvă majoritatea problemelor de "DLL missing"

---

### **[13] 🔄 Repornire Servicii Windows Blocat**

**Descriere:** Repornește servicii Windows critice care s-au blocat.

**Servicii restartat:**
- **Windows Update** (`wuauserv`)
- **BITS** (`BITS`) - Background transfers
- **Cryptographic Services** (`CryptSvc`)
- **Windows Modules Installer** (`TrustedInstaller`)
- **Print Spooler** (`spooler`)
- **Windows Audio** (`AudioSrv`)
- **Themes** (`Themes`)
- **Event Log** (`EventLog`)

**Când să folosești:**
- ✅ Windows Update blocat
- ✅ Probleme cu printarea
- ✅ Audio nu funcționează
- ✅ Teme Windows nu se aplică

**Risc:** 🟡 **Mediu** - Poate întrerupe temporar funcțiile respective

**Durată:** 2-3 minute

**💡 Tip:** Rezolvă majoritatea problemelor cu servicii blocate

---

### **[14] 🗑️ Uninstall Bloatware Windows 11**

**Descriere:** Elimină aplicațiile preinstalate nedorite din Windows 11.

**Aplicații eliminate:**
- **Microsoft:** Bing News, Bing Weather, Solitaire, Mixed Reality Portal
- **Social Media:** TikTok, Facebook
- **Entertainment:** Spotify preinstalat, Disney+
- **Productivity:** Office Hub (fără Office complet)
- **Other:** Skype, Your Phone, Wallet

**Setări dezactivate:**
- Sugestii Start Menu
- Reclame în sistem
- Content Delivery Manager

**Când să folosești:**
- ✅ Windows 11 fresh install
- ✅ Cleanup sistem pentru performanță
- ✅ Îndepărtarea aplicațiilor nedorite
- ✅ Sisteme corporate/business

**Risc:** 🟢 **Minim** - Șterge doar aplicații nedorite

**Durată:** 2-5 minute

**⚠️ Note:**
- Nu afectează funcționalitatea Windows
- Aplicațiile pot fi reinstalate din Microsoft Store

---

### **[15] 📸 Screenshot Toate Erorile din Event Log**

**Descriere:** Exportă și documentează toate erorile din Event Log pentru diagnostic.

**Ce exportă:**
- **System Errors:** Ultimele 100 erori System (CSV)
- **Application Errors:** Ultimele 100 erori Application (CSV)
- **Summary:** Statistici și top 5 surse de erori (TXT)

**Când să folosești:**
- ✅ Pentru suport tehnic sau service
- ✅ Diagnostic probleme sistem
- ✅ Documentare erori recurente
- ✅ Troubleshooting avanced

**Risc:** 🟢 **Zero** - Doar exportă informații

**Durată:** 1-2 minutes

**Output:** Folder pe Desktop cu timestamp și fișiere CSV/TXT

---

## 📅 **Ghid de Utilizare**

### **Programare Recomandată:**

#### **📅 ZILNIC:**
- **[1]** Curățare rapidă (1-2 min)

#### **📅 SĂPTĂMÂNAL:**
- **[3]** Actualizare aplicații (5-20 min)
- **[4]** Scanare securitate (30-120 min background)

#### **📅 LUNAR:**
- **[2]** Optimizare completă (10-30 min)
- **[7]** Backup/Restore point (1-3 min)
- **[8]** Raport sistem pentru monitorizare

#### **🚨 LA PROBLEME SPECIFICE:**

| Problemă | Soluție Recomandată |
|----------|-------------------|
| **Sistem lent** | [1] → [2] → [11] → [9] |
| **Erori BSOD** | [7] → [5] → [15] → [8] |
| **Probleme rețea** | [6] (⚠️ repornire) |
| **Spațiu disk plin** | [1] → [10] → [14] |
| **Gaming performance** | [11] + [1] |
| **Windows Update blocat** | [13] → [5] |
| **Aplicații nu pornesc** | [12] → [13] |

---

## ⚠️ **Probleme Cunoscute și Soluții**

### **1. "Execution Policy" Error**
**Problemă:** Script-ul nu rulează din cauza policy-ului
**Soluție:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **2. "Access Denied" Errors**
**Problemă:** Lipsa permisiunilor de Administrator
**Soluție:** Rulează PowerShell ca Administrator (Click-dreapta → "Run as Administrator")

### **3. SQL Server nu este detectat**
**Problemă:** Detectează greșit SQL Server Express
**Soluție:** ✅ **REZOLVAT** - Script-ul detectează acum și Express (`MSSQL$SQLEXPRESS`)

### **4. Winget nu funcționează**
**Problemă:** Winget nu este instalat sau actualizat
**Soluție:**
- Actualizează Windows la ultima versiune
- Instalează "App Installer" din Microsoft Store

### **5. Servicii nu se repornesc**
**Problemă:** Unele servicii sunt dependente de altele
**Soluție:** Repornește computerul după funcția [13]

---

## 🛡️ **Backup și Siguranță**

### **⚠️ ÎNAINTE DE FOLOSIRE:**

1. **Creează Restore Point:**
   ```powershell
   # Rulează manual sau folosește [7]
   Checkpoint-Computer -Description "Before SystemToolkit"
   ```

2. **Backup Date Importante:**
   - Documentele personale
   - Configurări aplicații
   - Lista software-ului instalat

3. **Verifică Spațiul Disponibil:**
   - Minim 10GB liberi pentru operațiuni sigure
   - 20GB+ pentru optimizare completă

### **🔐 SIGURANȚA DATELOR:**

| Funcție | Risc Pierdere Date | Recomandare |
|---------|-------------------|-------------|
| [1] Curățare rapidă | 🟢 Foarte mic | Sigur de folosit |
| [2] Optimizare completă | 🟡 Mic | Restore point recomandat |
| [5] Reparare SFC/DISM | 🟡 Mic | Backup importante |
| [6] Reset rețea | 🟢 Zero | Notează setările custom |
| [14] Uninstall bloatware | 🟢 Zero | Apps pot fi reinstalate |

### **📋 CHECKLIST PRE-OPTIMIZARE:**

- [ ] ✅ Backup date importante realizat
- [ ] ✅ Restore point creat ([7])
- [ ] ✅ Noteaza setările custom importante
- [ ] ✅ Închide aplicațiile critice
- [ ] ✅ Verifică spațiul disponibil (>10GB)
- [ ] ✅ Planifică timp suficient pentru operațiuni

---

## 📞 **Suport și Întrebări Frecvente**

### **❓ FAQ:**

**Q: Pot rula script-ul pe Windows Server?**
**A:** Da, majoritatea funcțiilor sunt compatibile, dar testează pe un sistem non-production.

**Q: Cât de des să rulez optimizarea completă?**
**A:** Lunar pentru sisteme normale, săptămânal pentru gaming/heavy usage.

**Q: Script-ul poate să îmi "strice" Windows-ul?**
**A:** Riscul este minimal. Funcțiile [5] și [6] au risc mai mare, dar sunt reversibile cu restore point.

**Q: Ce fac dacă o funcție se blochează?**
**A:** Închide PowerShell cu Ctrl+C, repornește calculatorul, rulează restore point dacă e necesar.

**Q: Pot automatiza script-ul să ruleze singur?**
**A:** Da, poți crea task-uri Windows Task Scheduler pentru funcții specifice.

---

## 📝 **Changelog și Versiuni**

### **Versiunea 1.0:**
- ✅ 15 funcții complete de optimizare
- ✅ Support SQL Server Express fix
- ✅ Gaming mode optimization
- ✅ Comprehensive error handling
- ✅ Multi-package manager updates
- ✅ Advanced system reporting

### **Funcții Planificate (v1.1):**
- [ ] Registry optimization advanced
- [ ] Driver update automation
- [ ] System temperature monitoring
- [ ] Scheduled maintenance mode
- [ ] Remote system management

---

## 🏷️ **Licență și Responsabilitate**

**Utilizare:** Acest script este oferit "as-is" pentru uz personal și educațional.
**Responsabilitate:** Utilizatorul este responsabil pentru testarea pe sisteme non-production.
**Backup:** Recomandarea de backup înainte de utilizare este OBLIGATORIE.

---

**© 2024 System Toolkit - PowerShell Optimization Suite**
*Pentru actualizări și suport, consultă documentația acestui fișier.*