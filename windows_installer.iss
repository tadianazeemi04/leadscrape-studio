; Inno Setup Script for WebReven
[Setup]
AppId={{C8E67468-9A2E-47F1-8B35-B18B63F3398D}
AppName=WebReven
AppVersion=2.0.0
AppPublisher=WebReven
DefaultDirName={autopf}\WebReven
DefaultGroupName=WebReven
OutputDir=dist
OutputBaseFilename=WebReven_Setup
Compression=lzma2/max
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\WebReven"; Filename: "{app}\WebReven.exe"
Name: "{group}\{cm:UninstallProgram,WebReven}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\WebReven"; Filename: "{app}\WebReven.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\WebReven.exe"; Description: "{cm:LaunchProgram,WebReven}"; Flags: nowait postinstall skipifsilent
