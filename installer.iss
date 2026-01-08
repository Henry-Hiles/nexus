[Setup]
AppName=Nexus
AppVersion=1.0.0
DefaultDirName={pf}\Nexus
DefaultGroupName=Nexus
OutputDir=dist
OutputBaseFilename=Nexus-Setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Nexus"; Filename: "{app}\nexus.exe"
Name: "{commondesktop}\Nexus"; Filename: "{app}\nexus.exe"