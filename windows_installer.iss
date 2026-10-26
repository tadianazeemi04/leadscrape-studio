; Inno Setup Script for LeadScrape Studio
[Setup]
AppId={{C8E67468-9A2E-47F1-8B35-B18B63F3398D}
AppName=LeadScrape Studio
AppVersion=1.0.0
AppPublisher=LeadScrape
DefaultDirName={autopf}\LeadScrape Studio
DefaultGroupName=LeadScrape Studio
OutputDir=dist
OutputBaseFilename=LeadScrapeStudio_Setup
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
Name: "{group}\LeadScrape Studio"; Filename: "{app}\LeadScrapeStudio.exe"
Name: "{group}\{cm:UninstallProgram,LeadScrape Studio}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\LeadScrape Studio"; Filename: "{app}\LeadScrapeStudio.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\LeadScrapeStudio.exe"; Description: "{cm:LaunchProgram,LeadScrape Studio}"; Flags: nowait postinstall skipifsilent
