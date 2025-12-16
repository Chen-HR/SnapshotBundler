# SnapshotBundler

[![PowerShell](https://img.shields.io/badge/PowerShell-5.0%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A lightweight PowerShell utility designed to create a single, comprehensive, and filtered **code snapshot** (bundle) of a project directory. This tool is especially useful for **AI context feeding**, code review, or documentation generation by consolidating all relevant source files into a single structured output format (Markdown or XML).

---

## ✨ Features

* **Single-File Output:** Consolidate an entire project's source code into a single `Markdown` or `XML` file.
* **Intelligent Filtering:** Supports exclusion of specified file extensions (e.g., `.dll`, `.jpg`) and common development directories (e.g., `node_modules`, `.git`, `bin`).
* **Language Hinting:** Markdown output automatically includes language hints for syntax highlighting (e.g., `powershell`, `python`, `csharp`).
* **Structured Output:** Markdown uses file headers (`## File:`) and code blocks, while XML uses structured `<File>` elements nested under a `<Directory>` root.

## 🚀 Getting Started

### Prerequisites

* PowerShell 5.0 or newer (Windows, macOS, Linux).

### Installation (As a Script)

1. Download the `SnapshotBundler.ps1` script to your system.
2. Import the functions into your current session:

    ```powershell
    . .\SnapshotBundler.ps1
    ```

### Usage

#### 1. Export to Markdown (`.md`)

This is the recommended format for AI prompts (e.g., LLMs) or general human readability. The output header uses `# Path`.

```powershell
# Example 1: Export the current directory to a Markdown file
Invoke-SnapshotBundleToMarkdown | Out-File -FilePath "ProjectSnapshot.md" -Encoding UTF8

# Example 2: Export a specific path
Invoke-SnapshotBundleToMarkdown -Path "C:\MySourceCode\BackendService" | Out-File "BackendSnapshot.md" -Encoding UTF8
```

#### 2. Export to XML (`.xml`)

This format is suitable for programmatic consumption, structured data processing, or integration with specific toolchains. The root element is `<Directory>`.

```powershell
# Export the current directory to a structured XML file
Invoke-SnapshotBundleToXml | Out-File -FilePath "ProjectSnapshot.xml" -Encoding UTF8
```

## ⚙️ Configuration

The exclusion logic is managed by the global hashtable `$SnapshotBundleConfig` defined at the top of the script.

* **`ExcludedExtensions`**: Files to skip content inclusion (content is replaced with an omission note).
* **`ExcludedDirectories`**: Directories that, if encountered in the file path, will exclude the entire file.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
