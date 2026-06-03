# --- GLOBAL CONFIGURATION AND HELPERS ---

<#
.SYNOPSIS
A shared configuration object for defining glob-based exclusion criteria.
#>
$SnapshotBundleConfig = @{
  # Supports .gitignore style glob patterns (e.g., 'bin', '*.log', '**/temp/*')
  ExcludedPatterns = @(
    'bin', 'obj', 'out', 'tmp', 'dist', 'build', '__pycache__', 
    '.git', '.vs', '.vscode', '.venv', 'node_modules',
    '*.dll', '*.exe', '*.log', '*.tmp', '*.DS_Store', '*.py[codz]'
  )
}

<#
.SYNOPSIS
Helper function to test if a path matches any of the provided glob patterns.
Checks full path and individual directory segments.
#>
function Test-PathMatchPattern {
  param(
    [Parameter(Mandatory=$true)] [string]$Path,
    [Parameter(Mandatory=$true)] [string[]]$Patterns
  )
  # Split path into segments to check directory levels
  $segments = $Path -split '[\\/]'
  
  foreach ($pattern in $Patterns) {
    $wildcard = [System.Management.Automation.WildcardPattern]::new($pattern, 'IgnoreCase')
    
    # Check if the full path matches
    if ($wildcard.IsMatch($Path)) { return $true }
    
    # Check if any part of the path matches (e.g., if 'bin' matches any directory in the path)
    foreach ($seg in $segments) {
      if ($wildcard.IsMatch($seg)) { return $true }
    }
  }
  return $false
}

<#
.SYNOPSIS
Maps a file's extension or base name to a corresponding language identifier string.

.DESCRIPTION
This function determines a language hint based on the input string, which can be
a standard file extension (e.g., '.py') or a dotless file name (e.g., 'Makefile').
If no specific mapping is found, it defaults to 'text'.

.PARAMETER NameOrExtension
The file extension string (e.g., ".js") or the file's base name (e.g., "Dockerfile").
.RETURNS
A string containing the identified language hint.
#>
function Get-FileLanguageHint {
  param(
    [string]$NameOrExtension 
  )
  
  # Trim leading dot if it's an extension; the key is used for the switch comparison.
  $key = $NameOrExtension.ToLower().TrimStart('.')

  # The switch statement implicitly returns the output.
  switch ($key) {
    # --- Standard Extensions ---
    'ps1'   { 'powershell' }
    'cmd'   { 'cmd' }
    'sh'    { 'bash' }
    'js'    { 'javascript' }
    'ts'    { 'typescript' }
    'jsx'   { 'jsx' }
    'tsx'   { 'tsx' }
    'json'  { 'json' }
    'html'  { 'html' }
    'htm'   { 'html' }
    'css'   { 'css' }
    'scss'  { 'scss' }
    'less'  { 'less' }
    'py'    { 'python' }
    'pyi'   { 'python' }
    'cs'    { 'csharp' }
    'java'  { 'java' }
    'c'     { 'c' }
    'h'     { 'c' }
    'cpp'   { 'cpp' }
    'hpp'   { 'cpp' }
    'php'   { 'php' }
    'rb'    { 'ruby' }
    'go'    { 'go' }
    'yaml'  { 'yaml' }
    'yml'   { 'yaml' }
    'toml'  { 'toml' }
    'xml'   { 'xml' }
    'md'    { 'markdown' }
    'tex'   { 'latex' }
    'lua'   { 'lua' }
    'm'     { 'matlab' }
    'csv'   { 'csv' }
    'tsv'   { 'tsv' }

    # --- Handle dotless files (BaseName) ---
    'makefile'   { 'makefile' }
    'dockerfile' { 'dockerfile' }
    'readme'     { 'markdown' }
    'license'    { 'text' }

    default { 'text' }
  }
}

<#
.SYNOPSIS
Retrieves a list of file objects from a path after applying pattern-based exclusions.
#>
function Get-SnapshotBundleFiles {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)] [string]$Path,
    [string[]]$ExcludedPatterns = @()
  )

  try {
    $physicalPath = (Get-Item -LiteralPath $Path -ErrorAction Stop).FullName.TrimEnd('\', '/')
  } catch {
    Write-Error "Error: Path '$Path' not found."
    return @()
  }

  $physicalPathLength = $physicalPath.Length
  
  # Merge global config with dynamic parameters
  $effectivePatterns = $SnapshotBundleConfig.ExcludedPatterns + $ExcludedPatterns

  Get-ChildItem -LiteralPath $physicalPath -Recurse -File | Where-Object {
    $relativePath = $_.FullName.Substring($physicalPathLength).TrimStart('\', '/')
    -not (Test-PathMatchPattern -Path $relativePath -Patterns $effectivePatterns)
  }
}
function Invoke-SnapshotBundleToMarkdown {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)] [string]$Path = "",
    [string[]]$ExcludedPatterns = @()
  )

  $processPath = if ([string]::IsNullOrEmpty($Path)) { "." } else { $Path }
  $physicalPath = (Get-Item -Path $processPath -ErrorAction Stop).FullName.TrimEnd('\', '/')
  $physicalPathLength = $physicalPath.Length
  $exportRootName = if ([string]::IsNullOrEmpty($Path)) { "" } else { $Path.Replace('\', '/').TrimEnd('/') }

  $files = Get-SnapshotBundleFiles -Path $processPath -ExcludedPatterns $ExcludedPatterns
  
  $markdownOutput = "# Directory: ``$exportRootName```n`n- Export Time: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')`n`n"
  
  foreach ($file in $files) {
    $internalRelativePath = $file.FullName.Substring($physicalPathLength).TrimStart('\', '/')
    $finalRelativePath = if ([string]::IsNullOrEmpty($exportRootName)) { $internalRelativePath.Replace('\', '/') } else { "$exportRootName/$internalRelativePath".Replace('\', '/').Replace('//', '/') }

    $valueToPass = if ([string]::IsNullOrEmpty($file.Extension)) { $file.BaseName } else { $file.Extension }
    $languageHint = Get-FileLanguageHint -NameOrExtension $valueToPass

    $markdownOutput += "## File: ``$finalRelativePath```n`n" 
    
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $markdownOutput += "````````$languageHint`n$content`n`````````n`n"
  }
  Write-Output $markdownOutput
}

function Invoke-SnapshotBundleToXml {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)] [string]$Path = "",
    [string[]]$ExcludedPatterns = @()
  )

  $processPath = if ([string]::IsNullOrEmpty($Path)) { "." } else { $Path }
  $physicalPath = (Get-Item -Path $processPath -ErrorAction Stop).FullName.TrimEnd('\', '/')
  $physicalPathLength = $physicalPath.Length
  $exportRootName = if ([string]::IsNullOrEmpty($Path)) { "" } else { $Path.Replace('\', '/').TrimEnd('/') }

  $files = Get-SnapshotBundleFiles -Path $processPath -ExcludedPatterns $ExcludedPatterns
  
  $xmlDoc = New-Object -TypeName System.Xml.XmlDocument
  $rootElement = $xmlDoc.CreateElement("Directory")
  $rootElement.SetAttribute("ExportTime", (Get-Date -Format 'yyyy/MM/dd HH:mm:ss'))
  $rootElement.SetAttribute("SourcePath", $exportRootName) 
  [void]$xmlDoc.AppendChild($rootElement) 

  foreach ($file in $files) {
    $internalRelativePath = $file.FullName.Substring($physicalPathLength).TrimStart('\', '/')
    $finalRelativePath = if ([string]::IsNullOrEmpty($exportRootName)) { $internalRelativePath.Replace('\', '/') } else { "$exportRootName/$internalRelativePath".Replace('\', '/').Replace('//', '/') }
    
    $languageHint = Get-FileLanguageHint -NameOrExtension $(if ([string]::IsNullOrEmpty($file.Extension)) { $file.BaseName } else { $file.Extension })

    $fileElement = $xmlDoc.CreateElement("File")
    $fileElement.SetAttribute("RelativePath", $finalRelativePath)
    $fileElement.SetAttribute("LanguageHint", $languageHint)
    
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    [void]$fileElement.AppendChild($xmlDoc.CreateCDataSection($content))
    
    [void]$rootElement.AppendChild($fileElement)
  }
  Write-Output $xmlDoc.OuterXml
}

# --- MODULE EXPORTS ---
Export-ModuleMember -Function Invoke-SnapshotBundleToMarkdown, Invoke-SnapshotBundleToXml, Get-SnapshotBundleFiles, Get-FileLanguageHint -Variable SnapshotBundleConfig
