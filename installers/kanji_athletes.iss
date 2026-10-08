; Inno Setup script to package Kanji Athletes Release folder
[Setup]
AppName=Kanji Athletes
AppVersion=1.1.0
; Installs into this user's own AppData instead of Program Files, and
; PrivilegesRequired=lowest stops Inno Setup asking Windows to elevate -
; no admin/UAC prompt on install, reinstall, or uninstall. The one
; "Windows protected your PC" SmartScreen click-through (since this isn't
; code-signed) is the only prompt left.
DefaultDirName={localappdata}\Kanji Athletes
PrivilegesRequired=lowest
DefaultGroupName=Kanji Athletes
OutputDir=..\build\windows
OutputBaseFilename=KanjiAthletesInstaller_x64
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
; Kanji Athletes Mini is the same .exe, just launched with --mini (see the
; comment in lib/main.dart) - no separate install, just a second shortcut
; pointed at it with that argument.
Name: "{group}\Kanji Athletes Mini"; Filename: "{app}\kanji_athletes.exe"; Parameters: "--mini"
Name: "{userdesktop}\Kanji Athletes Mini"; Filename: "{app}\kanji_athletes.exe"; Parameters: "--mini"; Tasks: minidesktopicon

[Run]
Filename: "{app}\kanji_athletes.exe"; Description: "Launch Kanji Athletes"; Flags: nowait postinstall skipifsilent

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: minidesktopicon; Description: "Create a desktop icon for Kanji Athletes &Mini"; GroupDescription: "Additional icons:"; Flags: unchecked
