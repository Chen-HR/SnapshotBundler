# SnapshotBundler

[![PowerShell](https://img.shields.io/badge/PowerShell-5.0%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)

**SnapshotBundler** is a lightweight PowerShell module designed to consolidate an entire project directory into a single, structured file (**Markdown** or **XML**).

It intelligently filters out binary files and build artifacts, creating a clean, readable snapshot of your source code. This tool is ideal for code reviews, project archiving, creating technical documentation appendices, or simply sharing a codebase in a portable format.

---

## Features

* **Project Consolidation**: Merges scattered source files into one comprehensive document.
* **Advanced Filtering**: 
  * Supports `.gitignore` style glob patterns.
  * Use trailing slash (e.g., `bin/`) to specifically exclude directories, while allowing files named `bin`.
* **Readable Markdown Output**: Generates Markdown with auto-detected syntax highlighting hints (e.g., `python`, `csharp`, `json`) for optimal readability.
* **Structured XML Output**: Provides a strictly structured XML format suitable for programmatic processing, reporting, or integration with other tools.

---

## Getting Started

### Prerequisites

* **PowerShell 5.0** or newer (Compatible with Windows, macOS, and Linux).

### Installation

1. Download the `SnapshotBundler` folder containing `.psd1` and `.psm1` files.
2. Place the folder into your PowerShell modules path:
   * **Windows**: `C:\Users\<User>\Documents\PowerShell\Modules\`
   * **macOS/Linux**: `~/.local/share/powershell/Modules/`

Alternatively, you can import it manually from any location:

```powershell
Import-Module ".\Path\To\SnapshotBundler\SnapshotBundler.psd1"
```

---

## Usage

### 1. Export to Markdown (`.md`)

```powershell
# Export the current directory to a Markdown file
Invoke-SnapshotBundleToMarkdown | Out-File -FilePath "SourceSnapshot.md" -Encoding UTF8

# Export with custom patterns and gitignore files
Invoke-SnapshotBundleToMarkdown -ExcludedPatterns @("temp/") -IgnorePaths @(".gitignore") > "SourceSnapshot.md"
```

### 2. Export to XML (`.xml`)

```powershell
# Export the current directory to an XML file
Invoke-SnapshotBundleToXml | Out-File -FilePath "SourceSnapshot.xml" -Encoding UTF8
```

---

## Configuration

The module exposes a global configuration variable `$SnapshotBundleConfig`. You can modify `ExcludedPatterns` to change global exclusion rules.

### Exclusion Syntax

* **Glob Patterns**: Use wildcards (e.g., `*.log`, `*.tmp`).
* **Directory-Specific**: Use a trailing slash (e.g., `bin/`) to exclude only directories. If a file is named `bin`, it will be preserved.

### Modifying Exclusion Rules

```powershell
# Add a new pattern to the global configuration
$SnapshotBundleConfig.ExcludedPatterns += "dist/"
```

### Dynamic Parameters

You can also pass rules at runtime without modifying the global config:

```powershell
# Pass dynamic patterns and external gitignore files
Invoke-SnapshotBundleToMarkdown -ExcludedPatterns @("temp/") -IgnorePaths @(".gitignore", "my_rules.ignore")
```
