# --- GLOBAL CONFIGURATION AND HELPERS ---

<#
.SYNOPSIS
A shared configuration object for defining file and directory exclusion criteria.
#>
$SnapshotBundleConfig = @{
  # Defines file extensions (including the dot) for which content will be excluded from output.
  ExcludedExtensions = @(
    '.dll', '.exe', '.pdb', '.bin', '.hex', '.obj', '.o', '.lib',
    '.iso', '.img', '.zip', '.tar', '.gz', '.7z', '.rar',
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.ico',
    '.mp4', '.mov', '.avi', '.mp3', '.wav', '.mat',
    '.log', '.bak', '.tmp', '.DS_Store'
  )
  
  # Defines directory names (case-insensitive during filtering) that, if encountered
  # as any segment in a file's relative path, will cause the file to be excluded.
  ExcludedDirectories = @(
    'node_modules', 'site-packages', 'bin', 'ref', 'fonts', 'obj', '.git', '.vs', '.vscode', '.venv', 'packages', 'dist', 'lib', 'build', 'out', 'tmp', '__pycache__', '*.egg-info'
  )
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
    'sh'  { 'bash' }
    'js'  { 'javascript' }
    'ts'  { 'typescript' }
    'jsx'   { 'jsx' }
    'tsx'   { 'tsx' }
    'json'  { 'json' }
    'html'  { 'html' }
    'htm'   { 'html' }
    'css'   { 'css' }
    'scss'  { 'scss' }
    'less'  { 'less' }
    'py'  { 'python' }
    'pyi'   { 'python' }
    'cs'  { 'csharp' }
    'java'  { 'java' }
    'c'   { 'c' }
    'h'   { 'c' }
    'cpp'   { 'cpp' }
    'hpp'   { 'cpp' }
    'php'   { 'php' }
    'rb'  { 'ruby' }
    'go'  { 'go' }
    'yaml'  { 'yaml' }
    'yml'   { 'yaml' }
    'toml'  { 'toml' }
    'xml'   { 'xml' }
    'md'  { 'markdown' }
    'tex'   { 'latex' }
    'lua'   { 'lua' }
    
    # --- Handle dotless files (BaseName) ---
    'makefile' { 'makefile' }
    'dockerfile' { 'dockerfile' }
    'readme' { 'markdown' }
    'license' { 'text' }

    default { 'text' }
  }
}

<#
.SYNOPSIS
Retrieves a list of file objects from a path after applying directory exclusions.

.DESCRIPTION
This function is responsible for navigating the directory structure defined by $Path,
resolving the absolute path, and recursively collecting file objects. Files are
excluded if any segment of their relative path matches an entry in 
$SnapshotBundleConfig.ExcludedDirectories. File extension exclusion is handled
by the calling functions.

.PARAMETER Path
The starting directory path from which to begin file collection.
.RETURNS
An array of System.IO.FileInfo objects that passed the directory exclusion filter.
#>
function Get-SnapshotBundleFiles {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [string]$Path
  )

  # Resolve the input path to its absolute FullName for accurate comparison and length calculation.
  try {
    $physicalPath = (Get-Item -Path $Path -ErrorAction Stop).FullName.TrimEnd('\', '/')
  }
  catch {
    Write-Error "Error: The specified path is not a valid directory or does not exist: '$Path'"
    return @()
  }

  $physicalPathLength = $physicalPath.Length
  $excludedDirectories = $SnapshotBundleConfig.ExcludedDirectories

  # Retrieve all files recursively and apply filtering
  $files = Get-ChildItem -Path $physicalPath -Recurse -File | Where-Object {
    
    # Calculate the relative path from the absolute root.
    $relativePath = $_.FullName.Substring($physicalPathLength).TrimStart('\' , '/')
    $isInsideExcludedDir = $false
    
    # Check if any path segment matches an excluded directory name.
    foreach ($segment in ($relativePath -split '[\\/]')) {
      if ($excludedDirectories -contains $segment) {
        $isInsideExcludedDir = $true
        break
      }
    }
    
    # Only include the file if it is NOT inside an excluded directory.
    -not $isInsideExcludedDir
  }
  
  return $files
}


# --- EXPORT FUNCTIONS ---

<#
.SYNOPSIS
Generates a single Markdown-formatted string containing the file structure and content of a directory.

.DESCRIPTION
This function recursively processes files within the specified directory, applies configured
directory exclusions via Get-SnapshotBundleFiles, and then applies file extension exclusion.
For included files, the content is embedded within Markdown code blocks, with a language
hint derived from Get-FileLanguageHint. For excluded files, the content is omitted, and 
a notation is included.

.PARAMETER Path
The full path to the source directory. If omitted, the current directory ('.') is used.
.EXAMPLE
Invoke-SnapshotBundleToMarkdown $Directory
.EXAMPLE
Invoke-SnapshotBundleToMarkdown | Out-File export.md
#>
function Invoke-SnapshotBundleToMarkdown {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)] 
    [string]$Path = "" 
  )

  # Determine the actual path for processing ('.') and the path for display.
  $processPath = if ([string]::IsNullOrEmpty($Path)) { "." } else { $Path }
  
  # Resolve the physical path for file filtering and relative path calculation.
  $physicalPath = (Get-Item -Path $processPath -ErrorAction Stop).FullName.TrimEnd('\', '/')
  $physicalPathLength = $physicalPath.Length

  # Determine the root name for the output header and file path prefix.
  $exportRootName = if ([string]::IsNullOrEmpty($Path)) { 
    "" 
  } else { 
    $Path.Replace('\', '/').TrimEnd('/')
  }

  $files = Get-SnapshotBundleFiles -Path $processPath
  if ($files.Count -eq 0 -and (Test-Path -Path $processPath -PathType Container)) {
     Write-Host "No files found for processing after filtering in '$processPath'."
     return
  }

  # Initialize the Markdown output string with the header.
  $markdownOutput = "# Directory: ``$exportRootName```n`n- Export Time: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')`n`n---"
  
  try {
    foreach ($file in $files) {
      # Calculate the relative path within the physical root.
      $internalRelativePath = $file.FullName.Substring($physicalPathLength).TrimStart('\' , '/')
      
      # Construct the final path with the export root name prefix (if applicable).
      if ([string]::IsNullOrEmpty($exportRootName)) {
        $finalRelativePath = $internalRelativePath.Replace('\', '/')
      } else {
        $finalRelativePath = "$exportRootName/$internalRelativePath".Replace('\', '/').Replace('//', '/')
      }

      # Check for file extension exclusion.
      $extension = $file.Extension.ToLower()
      $isExcludedExtension = $SnapshotBundleConfig.ExcludedExtensions -contains $extension
      
      # Get language hint for all files.
      $valueToPass = if ([string]::IsNullOrEmpty($file.Extension)) { $file.BaseName } else { $file.Extension }
      $languageHint = Get-FileLanguageHint -NameOrExtension $valueToPass

      # Append file information header.
      $markdownOutput += "`n`n## File: ``$finalRelativePath```n`n" 
      
      if (-not $isExcludedExtension) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Handle potential triple backticks in Markdown content to prevent block breakage.
        if (-not [string]::IsNullOrEmpty($content)) {
          $content = $content.Replace("``````", "\``\``\``")
        }

        $markdownOutput += "``````$languageHint`n$content`n``````"
      } else {
        # Notation for excluded content.
        $markdownOutput += "Content Omitted (Extension: $extension)."
      }
      $markdownOutput += "`n`n---" # File separator
    }

    Write-Output $markdownOutput

  } catch {
    Write-Error "An unexpected error occurred during Markdown export: $($_.Exception.Message)"
  }
}

<#
.SYNOPSIS
Generates a structured XML document string containing the file structure and content of a directory.

.DESCRIPTION
This function recursively processes files within the specified directory, applies configured
directory exclusions via Get-SnapshotBundleFiles, and then applies file extension exclusion.
For included files, the content is embedded within a CDATA section inside the <File> element.
For excluded files, an attribute is added to the <File> element indicating content omission.
The final output is the XML document's outer XML string.

.PARAMETER Path
The full path to the source directory. If omitted, the current directory ('.') is used.
.EXAMPLE
Invoke-SnapshotBundleToMarkdown $Directory
.EXAMPLE
Invoke-SnapshotBundleToMarkdown | Out-File export.md
#>
function Invoke-SnapshotBundleToXml {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)] 
    [string]$Path = "" 
  )

  # Determine the actual path for processing ('.') and the path for display.
  $processPath = if ([string]::IsNullOrEmpty($Path)) { "." } else { $Path }
  
  # Resolve the physical path for file filtering and relative path calculation.
  $physicalPath = (Get-Item -Path $processPath -ErrorAction Stop).FullName.TrimEnd('\', '/')
  $physicalPathLength = $physicalPath.Length

  # Determine the root name for the output attribute and file path prefix.
  $exportRootName = if ([string]::IsNullOrEmpty($Path)) { 
    "" 
  } else { 
    $Path.Replace('\', '/').TrimEnd('/')
  }

  $files = Get-SnapshotBundleFiles -Path $processPath
  if ($files.Count -eq 0 -and (Test-Path -Path $processPath -PathType Container)) {
     Write-Host "No files found for processing after filtering in '$processPath'."
     return
  }
  
  # Initialize the XML document.
  $xmlDoc = New-Object -TypeName System.Xml.XmlDocument
  
  # Create the root element: <Directory>.
  $rootElement = $xmlDoc.CreateElement("Directory")
  $rootElement.SetAttribute("ExportTime", (Get-Date -Format 'yyyy/MM/dd HH:mm:ss'))
  $rootElement.SetAttribute("SourcePath", $exportRootName) 
  [void]$xmlDoc.AppendChild($rootElement) 

  try {
    foreach ($file in $files) {
      # Calculate the relative path within the physical root.
      $internalRelativePath = $file.FullName.Substring($physicalPathLength).TrimStart('\' , '/')
      
      # Construct the final path with the export root name prefix (if applicable).
      if ([string]::IsNullOrEmpty($exportRootName)) {
        $finalRelativePath = $internalRelativePath.Replace('\', '/')
      } else {
        $finalRelativePath = "$exportRootName/$internalRelativePath".Replace('\', '/').Replace('//', '/')
      }
      
      # Check for file extension exclusion.
      $extension = $file.Extension.ToLower()
      $isExcludedExtension = $SnapshotBundleConfig.ExcludedExtensions -contains $extension
      
      # Get language hint for all files.
      $valueToPass = if ([string]::IsNullOrEmpty($file.Extension)) { $file.BaseName } else { $file.Extension }
      $languageHint = Get-FileLanguageHint -NameOrExtension $valueToPass

      # Create <File> element.
      $fileElement = $xmlDoc.CreateElement("File")
      
      # Add attributes
      $fileElement.SetAttribute("RelativePath", $finalRelativePath)
      $fileElement.SetAttribute("LanguageHint", $languageHint)
      
      if (-not $isExcludedExtension) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Create CDATA section for content to avoid XML parsing issues.
        $cdataSection = $xmlDoc.CreateCDataSection($content)
        [void]$fileElement.AppendChild($cdataSection)
      } else {
        # Add attributes to indicate content omission.
        $fileElement.SetAttribute("ContentOmitted", "True")
        $fileElement.SetAttribute("OmittedReason", "Extension excluded: $extension")
      }
      
      # Append elements.
      [void]$rootElement.AppendChild($fileElement)
    }

    # Output the final XML document as a string ONLY.
    Write-Output $xmlDoc.OuterXml
    
  } catch {
    Write-Error "An unexpected error occurred during XML export: $($_.Exception.Message)"
  }
}

# --- MODULE EXPORTS ---
# Explicitly export the functions and the configuration variable
Export-ModuleMember -Function Invoke-SnapshotBundleToMarkdown, Invoke-SnapshotBundleToXml, Get-SnapshotBundleFiles, Get-FileLanguageHint -Variable SnapshotBundleConfig
