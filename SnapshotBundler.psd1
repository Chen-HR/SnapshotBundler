@{
ModuleVersion = '1.0.0'
GUID = 'ee3364bf-e693-42dd-a4c7-dd27e4008cc8'
Author = 'Chen-HuangRen'
Copyright = '(c) 2025/12 Chen-HuangRen. All rights reserved.'
Description = 'A PowerShell utility to create a single, filtered source code snapshot (bundle) of a directory, optimized for AI context feeding or code review.'
RootModule = 'SnapshotBundler.ps1'
PowerShellVersion = '5.0'
RequiredModules = @()
CmdletsToExport = @(
  'Invoke-SnapshotBundleToMarkdown',
  'Invoke-SnapshotBundleToXml'
)
FunctionsToExport = @(
  'Get-SnapshotBundleFiles',
  'Get-FileLanguageHint'
)
VariablesToExport = @(
  'SnapshotBundleConfig'
)
AliasesToExport = '*'
FileList = @(
  'SnapshotBundler.ps1'
)
}