; Inno Setup script to package Kanji Athletes Release folder
[Setup]
AppName=Kanji Athletes
AppVersion=1.0.0
DefaultDirName={pf}\Kanji Athletes
DefaultGroupName=Kanji Athletes
OutputDir=..\build\windows
OutputBaseFilename=KanjiAthletesInstaller_x64_v1
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
Uninstallable=yes

[Files]
; Copy entire Release folder contents into the installation directory
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Kanji Athletes"; Filename: "{app}\kanji_athletes.exe"
Name: "{userdesktop}\Kanji Athletes"; Filename: "{app}\kanji_athletes.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\kanji_athletes.exe"; Description: "Launch Kanji Athletes"; Flags: nowait postinstall skipifsilent

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
