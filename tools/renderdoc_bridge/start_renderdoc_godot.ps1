param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExe,

    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$RenderDocCmd = "",

    [switch]$ResolveOnly
)

$ErrorActionPreference = "Stop"

function Resolve-RenderDocCmd {
    param([string]$ExplicitPath)

    if ($ExplicitPath -and (Test-Path -LiteralPath $ExplicitPath)) {
        $resolvedExplicit = (Resolve-Path -LiteralPath $ExplicitPath).Path
        if (Test-Path -LiteralPath $resolvedExplicit -PathType Container) {
            $candidate = Join-Path $resolvedExplicit "renderdoccmd.exe"
            if (Test-Path -LiteralPath $candidate) {
                return $candidate
            }
        }
        return $resolvedExplicit
    }

    $fromPath = Get-Command renderdoccmd.exe -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }

    $candidates = @(
        "C:\Program Files\RenderDoc\renderdoccmd.exe",
        "C:\Program Files (x86)\RenderDoc\renderdoccmd.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $registryRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($root in $registryRoots) {
        $items = Get-ItemProperty $root -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "RenderDoc*"
        }
        foreach ($item in $items) {
            if ($item.InstallLocation) {
                $candidate = Join-Path $item.InstallLocation "renderdoccmd.exe"
                if (Test-Path -LiteralPath $candidate) {
                    return $candidate
                }
            }
        }
    }

    $fromMsi = Resolve-RenderDocCmdFromMsi $registryRoots
    if ($fromMsi) {
        return $fromMsi
    }

    throw "renderdoccmd.exe was not found. Install RenderDoc or pass -RenderDocCmd."
}

function Resolve-RenderDocCmdFromMsi {
    param([string[]]$RegistryRoots)

    try {
        $installer = New-Object -ComObject WindowsInstaller.Installer
    }
    catch {
        return ""
    }

    foreach ($root in $RegistryRoots) {
        $items = Get-ItemProperty $root -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "RenderDoc*" -and $_.UninstallString -match "\{[0-9A-Fa-f-]{36}\}"
        }
        foreach ($item in $items) {
            $productCode = [regex]::Match($item.UninstallString, "\{[0-9A-Fa-f-]{36}\}").Value
            $candidate = Resolve-RenderDocCmdFromProduct $installer $productCode
            if ($candidate -and (Test-Path -LiteralPath $candidate)) {
                return $candidate
            }
        }
    }

    return ""
}

function Resolve-RenderDocCmdFromProduct {
    param(
        $Installer,
        [string]$ProductCode
    )

    try {
        $localPackage = $Installer.ProductInfo($ProductCode, "LocalPackage")
        if (-not $localPackage -or -not (Test-Path -LiteralPath $localPackage)) {
            return ""
        }

        $db = $Installer.OpenDatabase($localPackage, 0)
        $view = $db.OpenView("SELECT ``Component_`` FROM ``File`` WHERE ``File``='RenderDocCMD'")
        $view.Execute()
        $fileRecord = $view.Fetch()
        if (-not $fileRecord) {
            return ""
        }

        $componentName = $fileRecord.StringData(1)
        $view = $db.OpenView("SELECT ``ComponentId`` FROM ``Component`` WHERE ``Component``='$componentName'")
        $view.Execute()
        $componentRecord = $view.Fetch()
        if (-not $componentRecord) {
            return ""
        }

        $componentId = $componentRecord.StringData(1)
        return $Installer.ComponentPath($ProductCode, $componentId)
    }
    catch {
        return ""
    }
}

$resolvedGodot = (Resolve-Path -LiteralPath $GodotExe).Path
$resolvedProject = (Resolve-Path -LiteralPath $ProjectRoot).Path
$resolvedRenderDoc = Resolve-RenderDocCmd $RenderDocCmd

if ($ResolveOnly) {
    Write-Host $resolvedRenderDoc
    exit 0
}

$env:RENDERDOC_BRIDGE_BOOTSTRAPPED = "1"
$env:RENDERDOC_BRIDGE_PROJECT = $resolvedProject

Push-Location $resolvedProject
try {
    Write-Host "RenderDoc command: $resolvedRenderDoc"
    Write-Host "Godot executable: $resolvedGodot"
    Write-Host "Project root: $resolvedProject"
    & $resolvedRenderDoc capture --working-dir $resolvedProject --opt-hook-children $resolvedGodot -e --path $resolvedProject
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
