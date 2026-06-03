# --- GLOBAL CONFIGURATION AND HELPERS ---

<#
.SYNOPSIS
A shared configuration object for defining glob-based exclusion criteria.
#>
$SnapshotBundleConfig = @{
  # Supports .gitignore style glob patterns (e.g., 'bin', '*.log', '**/temp/*')
  ExcludedPatterns = @(
    'bin/', 'obj/', 'out/', 'tmp/', 'temp/', 'dist/', 'build/', '__pycache__/', 
    '.git/', '.vs/', '.vscode/', '.venv/', 'node_modules/', 'site-packages/', 'packages/', '*.egg-info/', '.DS_Store/', 
    
    '*.dll', '*.bin', '*.hex', '*.obj', '*.o', '*.lib', '*.exe', '*.py[codz]', 
    '*.img', '*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.svg', '*.ico', '*.mp4', '*.mov', '*.avi', '*.mp3', '*.wav', '*.mat', '*.drawio', 
    '*.iso', '*.zip', '*.tar', '*.gz', '*.7z', '*.rar', 
    '*.pdf', '*.xps', '*.thmx', '*.o[dt][tsp]', '*.do[ct]', '*.do[ct][mx]', '*.xl[st]', '*.xl[st][mx]', '*.xla', '*.xlam', '*.xlsb', '*.pp[st]', '*.pp[st][mx]', '*.pot', '*.pot[mx]', '*.ppa', '*.ppam', 
    '*.log', '*.bak', '*.tmp', '*.ttf', '*ignore', '*.lock', '*.prompt.md'
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
    [Parameter(Mandatory=$true)] [string]$BasePhysicalPath,
    [string[]]$Patterns = @()
  )
  
  if ($null -eq $Patterns -or $Patterns.Count -eq 0) { return $false }

  $segments = $Path -split '[\\/]'
  
  foreach ($pattern in $Patterns) {
    if ([string]::IsNullOrWhiteSpace($pattern)) { continue }
    
    $isDirMatch = $pattern -like "*[/\\]"
    $patternName = $pattern.TrimEnd('\/')
    $wildcard = [System.Management.Automation.WildcardPattern]::new($patternName, 'IgnoreCase')
    
    # Track current path relative to BasePhysicalPath for directory checking
    $currentPathPart = ""
    foreach ($seg in $segments) {
      $currentPathPart = if ($currentPathPart) { Join-Path $currentPathPart $seg } else { $seg }
      
      if ($wildcard.IsMatch($seg)) {
        if ($isDirMatch) {
            # Only exclude if the segment is a directory
            if (Test-Path (Join-Path $BasePhysicalPath $currentPathPart) -PathType Container) {
                return $true
            }
        } else {
            # General match: exclude if it matches
            return $true
        }
      }
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
    'psm1'  { 'powershell' }
    'psd1'  { 'powershell' }
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
    [string[]]$ExcludedPatterns = @(),
    [string[]]$IgnorePaths = @()
  )

  try {
    $physicalPath = (Get-Item -LiteralPath $Path -ErrorAction Stop).FullName.TrimEnd('\', '/')
  } catch {
    Write-Error "Error: Path '$Path' not found."
    return @()
  }

  $physicalPathLength = $physicalPath.Length
  
  $effectivePatterns = [string[]]$SnapshotBundleConfig.ExcludedPatterns + [string[]]$ExcludedPatterns

  foreach ($file in $IgnorePaths) {
    if (Test-Path $file) {
      Get-Content $file | ForEach-Object {
        $line = $_.Trim()
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
          $effectivePatterns += $line
        }
      }
    }
  }

  Get-ChildItem -LiteralPath $physicalPath -Recurse -File | Where-Object {
    $relativePath = $_.FullName.Substring($physicalPathLength).TrimStart('\', '/')
    -not (Test-PathMatchPattern -Path $relativePath -BasePhysicalPath $physicalPath -Patterns $effectivePatterns)
  }
}

# --- EXPORT FUNCTIONS ---

function Invoke-SnapshotBundleToMarkdown {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)] [string]$Path = ".",
    [string[]]$ExcludedPatterns = @(),
    [string[]]$IgnorePaths = @()
  )

  $processPath = if ([string]::IsNullOrEmpty($Path)) { "." } else { $Path }
  $physicalPath = (Get-Item -Path $processPath -ErrorAction Stop).FullName.TrimEnd('\', '/')
  $physicalPathLength = $physicalPath.Length
  $exportRootName = if ([string]::IsNullOrEmpty($Path)) { "" } else { $Path.Replace('\', '/').TrimEnd('/') }

  $files = Get-SnapshotBundleFiles -Path $processPath -ExcludedPatterns $ExcludedPatterns -IgnorePaths $IgnorePaths
  
  $markdownOutput = "# Directory: ``$exportRootName```n`n- Export Time: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')"
  
  foreach ($file in $files) {
    $internalRelativePath = $file.FullName.Substring($physicalPathLength).TrimStart('\', '/')
    $finalRelativePath = if ([string]::IsNullOrEmpty($exportRootName)) { $internalRelativePath.Replace('\', '/') } else { "$exportRootName/$internalRelativePath".Replace('\', '/').Replace('//', '/') }

    $valueToPass = if ([string]::IsNullOrEmpty($file.Extension)) { $file.BaseName } else { $file.Extension }
    $languageHint = Get-FileLanguageHint -NameOrExtension $valueToPass
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

    
    $markdownOutput += "`n`n## File: ``$finalRelativePath```n`n````````$languageHint`n$content`n````````" 
  }
  Write-Output $markdownOutput
}

function Invoke-SnapshotBundleToXml {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)] [string]$Path = ".",
    [string[]]$ExcludedPatterns = @(),
    [string[]]$IgnorePaths = @()
  )

  $processPath = if ([string]::IsNullOrEmpty($Path)) { "." } else { $Path }
  $physicalPath = (Get-Item -Path $processPath -ErrorAction Stop).FullName.TrimEnd('\', '/')
  $physicalPathLength = $physicalPath.Length
  $exportRootName = if ([string]::IsNullOrEmpty($Path)) { "" } else { $Path.Replace('\', '/').TrimEnd('/') }

  $files = Get-SnapshotBundleFiles -Path $processPath -ExcludedPatterns $ExcludedPatterns -IgnorePaths $IgnorePaths
  
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
