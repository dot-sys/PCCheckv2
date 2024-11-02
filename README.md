# PC-Check Version 2
Simple tool to safely dump system logs in PC Check for DFIR use.
This will be fully local, no data will be externally collected.
Running PC Checking Programs, including this script, outside of PC Checks may have impact on the outcome.
Tool is open for everybody to look into the code.

### Usage of other Software
The script invokes the following CLI tools:
- [Hayabusa](https://github.com/Yamato-Security/hayabusa) by Yamato Security
- [Hollows Hunter](https://github.com/hasherezade/hollows_hunter) by hasherezade.net
- [strings2](https://github.com/glmcdona/strings2) by Geoff McDonald (more infos at split-code.com)
- [MFTECmd](https://github.com/EricZimmerman/MFTECmd), [RECmd](https://github.com/EricZimmerman/RECmd), [AmCacheParser](https://github.com/EricZimmerman/AmcacheParser), [SRUMECmd](https://github.com/EricZimmerman/Srum), [PECmd](https://github.com/EricZimmerman/PECmd), [SBECmd](https://www.sans.org/tools/sbecmd/), [SQLECmd](https://github.com/EricZimmerman/SQLECmd), [ACC Parser](https://github.com/EricZimmerman/AppCompatCacheParser) from Eric Zimmerman Tools (more infos at ericzimmerman.github.io)
I do not claim any rights to the programs and thank the developers.

### Invoke Script
To directly invoke the script in Powershell use:

```powershell
New-Item -Path "C:\Temp\Scripts" -ItemType Directory -Force | Out-Null 
Set-Location "C:\temp\Scripts"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dot-sys/PCCheckv2/master/Menu.ps1" -OutFile "Menu.ps1"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force
Add-MpPreference -ExclusionPath 'C:\Temp' | Out-Null; .\Menu.ps1
```
