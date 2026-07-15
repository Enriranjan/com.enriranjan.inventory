<#
.SYNOPSIS
    One-shot initializer for a package generated from unity-package-template.

.DESCRIPTION
    Replaces the __PACKAGE_ID__ / __PACKAGE_NAME__ / __DISPLAY_NAME__ /
    __DESCRIPTION__ tokens across the repo, renames the files that carry a
    token in their name, then deletes the tools/ folder (including itself).

.PARAMETER PackageId
    Lowercase UPM id, e.g. "mypackage" (used as com.enriranjan.<PackageId>).

.PARAMETER PackageName
    PascalCase name, e.g. "MyPackage" (used in asmdefs and namespaces).

.PARAMETER DisplayName
    Human-readable name, e.g. "My Package".

.PARAMETER Description
    Short package description.

.PARAMETER Yes
    Skip the confirmation prompt.

.EXAMPLE
    tools/init-package.ps1 mypackage MyPackage "My Package" "Does a thing." -Yes
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)] [string] $PackageId,
    [Parameter(Position = 1)] [string] $PackageName,
    [Parameter(Position = 2)] [string] $DisplayName,
    [Parameter(Position = 3)] [string] $Description,
    [switch] $Yes
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

if ([string]::IsNullOrWhiteSpace($PackageId)) {
    $PackageId = Read-Host "package-id (lowercase, no spaces, e.g. 'mypackage')"
}
if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $PackageName = Read-Host "PackageName (PascalCase, e.g. 'MyPackage')"
}
if ([string]::IsNullOrWhiteSpace($DisplayName)) {
    $DisplayName = Read-Host "Display Name (e.g. 'My Package')"
}
if ([string]::IsNullOrWhiteSpace($Description)) {
    $Description = Read-Host "Short description"
}

if ($PackageId -notmatch '^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*)*$') {
    Write-Error "package-id must be lowercase letters/digits/hyphens, with optional dot-separated segments, each starting with a letter (got '$PackageId')."
}
if ($PackageName -notmatch '^[A-Z][A-Za-z0-9]*(\.[A-Z][A-Za-z0-9]*)*$') {
    Write-Error "PackageName must be PascalCase, starting with an uppercase letter, with optional dot-separated segments (got '$PackageName')."
}
if ([string]::IsNullOrWhiteSpace($DisplayName)) {
    Write-Error "Display Name cannot be empty."
}
if ([string]::IsNullOrWhiteSpace($Description)) {
    Write-Error "Description cannot be empty."
}

Write-Host ""
Write-Host "About to initialize:"
Write-Host "  package id    : com.enriranjan.$PackageId"
Write-Host "  PackageName   : $PackageName"
Write-Host "  Display Name  : $DisplayName"
Write-Host "  Description   : $Description"
Write-Host "  Repo root     : $RootDir"
Write-Host ""
Write-Host "This will rewrite files under the repo root and permanently delete tools/."

if (-not $Yes) {
    $confirm = Read-Host "Continue? [y/N]"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Host "Aborted."
        exit 1
    }
}

function Replace-TokensInFile([string] $Path) {
    $content = Get-Content -Raw -LiteralPath $Path
    $updated = $content.Replace('__PACKAGE_ID__', $PackageId).
                          Replace('__PACKAGE_NAME__', $PackageName).
                          Replace('__DISPLAY_NAME__', $DisplayName).
                          Replace('__DESCRIPTION__', $Description)
    if ($updated -ne $content) {
        [System.IO.File]::WriteAllText($Path, $updated)
    }
}

Write-Host ""
Write-Host "Replacing tokens in file contents..."
$files = Get-ChildItem -LiteralPath $RootDir -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.DirectoryName -ne $ScriptDir -and -not $_.FullName.StartsWith($ScriptDir) }

foreach ($file in $files) {
    Replace-TokensInFile -Path $file.FullName
}

Write-Host "Renaming files with tokens in their name..."
foreach ($file in $files) {
    $newName = $file.Name.Replace('__PACKAGE_ID__', $PackageId).Replace('__PACKAGE_NAME__', $PackageName)
    if ($newName -ne $file.Name) {
        $destination = Join-Path $file.DirectoryName $newName
        Rename-Item -LiteralPath $file.FullName -NewName $newName
        Write-Host "  $($file.Name) -> $newName"
    }
}

Write-Host "Removing tools/ (self-cleanup)..."
Remove-Item -LiteralPath $ScriptDir -Recurse -Force -Confirm:$false

@"

Done. com.enriranjan.$PackageId ("$DisplayName") is ready.

Next steps:

1) Commit the result:
     git add -A
     git commit -m "chore: initialize $PackageName from unity-package-template"

2) Tag your first release (required for Git URL installs to pin a version):
     git tag v0.1.0
     git push origin main --tags

3) Install it in a Unity project:

   a) As a Git dependency (recommended for consumers), add to the
      project's Packages/manifest.json:
        "com.enriranjan.$PackageId": "https://github.com/enriranjan/$PackageId.git#v0.1.0"
      Bump the #v0.1.0 tag whenever you cut a new release.

   b) As an embedded package (recommended while developing the package
      itself), clone this repo directly into the target project's
      Packages/ folder:
        Packages/com.enriranjan.$PackageId/
      Unity auto-detects any folder under Packages/ that contains a
      package.json as an embedded, editable package - no manifest.json
      entry needed.
"@ | Write-Host
