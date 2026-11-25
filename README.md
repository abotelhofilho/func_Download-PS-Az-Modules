# Download-PS-Az-Modules

A PowerShell function that downloads the Az PowerShell modules from the PowerShell Gallery as `.nupkg` files so they can be installed manually or offline. It is meant for machines where `Install-Module` does not work — for example when the NuGet provider cannot be installed, or when TLS or proxy settings block PowerShell's built-in downloader.

## Features

- Downloads the full set of Az modules (`Az.Accounts`, `Az.Storage`, `Az.Compute`, and so on)
- Uses `curl.exe` first, which often works where `Invoke-WebRequest` is blocked
- Retries with `--ssl-no-revoke` when certificate revocation checks are blocked by the network
- Falls back to `Invoke-WebRequest` if `curl.exe` fails
- Forces TLS 1.2 for the session
- Checks that each file is a real package (zip signature), so proxy error pages are not saved as packages
- Saves each module in its own subfolder
- Lists the browser download URL for every module that failed

## Requirements

- **OS:** Windows 10 (1803 or later) or Windows 11 — `curl.exe` is included
- **PowerShell:** 5.1 or later
- **Network:** access to `www.powershellgallery.com` (from PowerShell or `curl.exe`)
- **Privileges:** no administrator rights needed

## Installation

1. Clone the repository or download the script:
   ```powershell
   git clone https://github.com/abotelhofilho/func_Download-PS-Az-Modules.git
   ```
2. Dot-source the function into your PowerShell session:
   ```powershell
   . .\func_Download-PS-Az-Modules.ps1
   ```

## Parameters

| Parameter | Required | Default                              | Description                                                                 |
| --------- | -------- | ------------------------------------ | --------------------------------------------------------------------------- |
| `OutDir`  | No       | `$HOME\Downloads\powershellModule`   | Base folder for the downloads. Each module is saved in its own subfolder.   |

## Usage

### Basic — download all Az modules to the default folder

```powershell
Download-PS-Az-Modules
```

### Custom output folder

```powershell
Download-PS-Az-Modules -OutDir "D:\Packages"
```

## Output

Each package is saved as `<OutDir>\<ModuleName>\<ModuleName>.nupkg`:

```
powershellModule\
├── Az.Accounts\Az.Accounts.nupkg
├── Az.Storage\Az.Storage.nupkg
└── ...
```

- Each module shows `OK` (green) or `FAILED` (red) as it downloads.
- At the end, every failed module is listed with its PowerShell Gallery URL so it can be downloaded in a browser instead.
- Failed downloads leave no partial files or empty folders behind.

## Notes

- The latest version of each module is downloaded.
- The module list is hard-coded and may drift from the current Az release. The authoritative list is in the **Dependencies** section of the [Az package page](https://www.powershellgallery.com/packages/Az).
- To install the downloaded packages, use [`Install-NupkgModule`](https://github.com/abotelhofilho/func_Install-NupkgModule):
  ```powershell
  Install-NupkgModule -SourcePath "$HOME\Downloads\powershellModule"
  ```
- `Download` is not an approved PowerShell verb. This only matters if the function is put in a module, where `Import-Module` shows a warning.
