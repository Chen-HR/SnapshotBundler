# SnapshotBundler

[![PowerShell](https://img.shields.io/badge/PowerShell-5.0%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)

**SnapshotBundler** is a lightweight PowerShell module designed to consolidate an entire project directory into a single, structured file (**Markdown** or **XML**). 

It intelligently filters out binary files and build artifacts, creating a clean, readable "snapshot" of your source code. This tool is ideal for **code reviews**, **project archiving**, **creating technical documentation appendices**, or simply sharing a codebase in a portable format.

---

## ✨ Features

* **Project Consolidation**: Merges scattered source files into one comprehensive document.
* **Smart Filtering**: Automatically excludes compiled binaries (e.g., `.dll`, `.exe`), media files, and heavy directories (e.g., `node_modules`, `.git`, `bin`) to keep the snapshot lightweight.
* **Readable Markdown Output**: Generates Markdown with auto-detected syntax highlighting hints (e.g., `python`, `csharp`, `json`) for optimal readability.
* **Structured XML Output**: Provides a strictly structured XML format suitable for programmatic processing, reporting, or integration with other tools.

---

## 🚀 Getting Started

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

## 💻 Usage

### 1. Export to Markdown (`.md`)

Best for human readability, documentation, or code reviews. The output includes file paths as headers and code fences for content.

```powershell
# Export the current directory to a Markdown file
Invoke-SnapshotBundleToMarkdown | Out-File -FilePath "SourceSnapshot.md" -Encoding UTF8

# Export a specific project path
Invoke-SnapshotBundleToMarkdown -Path "C:\Projects\BackendAPI" | Out-File "BackendAPI.md" -Encoding UTF8

```

### 2. Export to XML (`.xml`)

Best for data processing or when a strict schema is required.

```powershell
# Export the current directory to an XML file
Invoke-SnapshotBundleToXml | Out-File -FilePath "SourceSnapshot.xml" -Encoding UTF8

```

---

## ⚙️ Configuration

The module exposes a global configuration variable `$SnapshotBundleConfig`, allowing you to customize exclusion rules dynamically in your session.

### modifying Exclusion Rules

You can add specific extensions or directory names to ignore during the bundling process.

```powershell
# Example: Exclude temporary folder and TIFF images
$SnapshotBundleConfig.ExcludedDirectories += "temp_output"
$SnapshotBundleConfig.ExcludedExtensions += ".tiff"

```

### Default Exclusions

By default, the tool excludes:

* **Directories**: `node_modules`, `.git`, `bin`, `obj`, `dist`, `build`, `.vscode`, etc.
* **Extensions**: `.exe`, `.dll`, `.zip`, `.png`, `.jpg`, `.log`, etc.
