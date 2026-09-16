#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap local du jour 5 — création des 5 repos Git locaux (modules + deploy).

.DESCRIPTION
    Ce script prépare les repos locaux `globalbank-modules-*` et `globalbank-deploy`
    à partir des sources de la formation. Il ne pousse PAS sur Azure DevOps :
    l'utilisateur exécute les `git push` manuellement quand il le souhaite.

.PARAMETER Org
    Organisation Azure DevOps (par défaut : data2ai-tn).

.PARAMETER Project
    Nom du projet Azure DevOps (par défaut : GlobalBank-DataPlatform).

.PARAMETER SourceModules
    Chemin des modules sources (par défaut : day-04/terraform/modules).

.PARAMETER SourceDeploy
    Chemin du dépôt de déploiement source (par défaut : day-05).

.PARAMETER Root
    Dossier de création des repos (par défaut : parent de day-05).

.EXAMPLE
    .\bootstrap-day5.ps1
#>
[CmdletBinding()]
param(
    [string]$Org = 'data2ai-tn',
    [string]$Project = 'GlobalBank-DataPlatform',
    [string]$SourceModules = 'D:\Data2AI Academy\Snowflake-terraform\courses\initiation\day-04\terraform\modules',
    [string]$SourceDeploy  = 'D:\Data2AI Academy\Snowflake-terraform\courses\initiation\day-05',
    [string]$Root          = 'D:\Data2AI Academy\Snowflake-terraform'
)

$ErrorActionPreference = 'Stop'

# Mapping équipe -> modules
$moduleMap = [ordered]@{
    'globalbank-modules-platform'          = @('rbac', 'compute')
    'globalbank-modules-data-engineering'  = @('landing-zone')
    'globalbank-modules-business-data'     = @('data-domain')
    'globalbank-modules-bi-analytics'      = @('data-mart')
}

function New-ModuleRepo {
    param(
        [string]$RepoName,
        [string[]]$ModuleNames
    )

    $repoPath = Join-Path $Root $RepoName
    if (Test-Path $repoPath) {
        Remove-Item $repoPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $repoPath | Out-Null

    foreach ($m in $ModuleNames) {
        $src = Join-Path $SourceModules $m
        if (-not (Test-Path $src)) {
            throw "Module source introuvable : $src"
        }
        Copy-Item -Path $src -Destination $repoPath -Recurse -Force
    }

    cd $repoPath
    git init -b main 2>&1 | Out-Null
    git config user.email "learner@data2ai.local" 2>&1 | Out-Null
    git config user.name "Learner" 2>&1 | Out-Null
    git config core.autocrlf false 2>&1 | Out-Null
    git add . 2>&1 | Out-Null
    git commit -m "Modules GlobalBank v1.0.0" 2>&1 | Out-Null
    git tag -a v1.0.0 -m "Release initiale modules GlobalBank" 2>&1 | Out-Null
    git remote add origin "https://$Org@dev.azure.com/$Org/$Project/_git/$RepoName" 2>&1 | Out-Null

    return $repoPath
}

function New-DeployRepo {
    $repoPath = Join-Path $Root 'globalbank-deploy'
    if (Test-Path $repoPath) {
        Remove-Item $repoPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $repoPath | Out-Null

    Copy-Item -Path "$SourceDeploy\*" -Destination $repoPath -Recurse -Force
    if (Test-Path (Join-Path $repoPath '.terraform')) {
        Remove-Item (Join-Path $repoPath '.terraform') -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Nettoyer les répertoires .terraform / états locaux dans les envs (évite les sous-modules Git et secrets dans le repo)
    Get-ChildItem -Path (Join-Path $repoPath 'envs') -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $tfDir = Join-Path $_.FullName '.terraform'
        if (Test-Path $tfDir) { Remove-Item $tfDir -Recurse -Force -ErrorAction SilentlyContinue }
        Get-ChildItem -Path $_.FullName -Filter 'terraform.tfstate*' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path $_.FullName -Filter '*.tfplan' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    # Adapter readme.md aux chemins relatifs de la racine du deploy repo
    $rm = Join-Path $repoPath 'readme.md'
    if (Test-Path $rm) {
        $content = Get-Content $rm -Raw -Encoding UTF8
        $content = $content -replace 'cd courses/initiation/day-05/envs/dev', 'cd envs/dev'
        $content = $content -replace 'cd courses/initiation/day-05', 'cd .'
        $content = $content -replace 'courses/initiation/day-05/envs/dev', 'envs/dev'
        $content = $content -replace 'courses/initiation/day-05/envs/uat', 'envs/uat'
        $content = $content -replace 'courses/initiation/day-05', '.'
        Set-Content -Path $rm -Value $content -Encoding UTF8 -NoNewline
    }

    cd $repoPath
    git init -b main 2>&1 | Out-Null
    git config user.email "learner@data2ai.local" 2>&1 | Out-Null
    git config user.name "Learner" 2>&1 | Out-Null
    git config core.autocrlf false 2>&1 | Out-Null
    git add . 2>&1 | Out-Null
    git commit -m "Initial GlobalBank deploy repo" 2>&1 | Out-Null
    git remote add origin "https://$Org@dev.azure.com/$Org/$Project/_git/globalbank-deploy" 2>&1 | Out-Null

    return $repoPath
}

# --- Exécution ---

Write-Host "`n==> Création des 4 repos de modules..." -ForegroundColor Cyan
foreach ($entry in $moduleMap.GetEnumerator()) {
    $path = New-ModuleRepo -RepoName $entry.Key -ModuleNames $entry.Value
    Write-Host "  OK  $path  (modules : $($entry.Value -join ', '))" -ForegroundColor Green
}

Write-Host "`n==> Création du repo de déploiement..." -ForegroundColor Cyan
$deployPath = New-DeployRepo
Write-Host "  OK  $deployPath" -ForegroundColor Green

Write-Host "`n==> Récapitulatif des chemins" -ForegroundColor Cyan
foreach ($entry in $moduleMap.GetEnumerator()) {
    Write-Host "  $(Join-Path $Root $entry.Key)"
}
Write-Host "  $deployPath"

Write-Host "`n==> Commandes à exécuter pour pousser sur Azure DevOps" -ForegroundColor Cyan
foreach ($entry in $moduleMap.GetEnumerator()) {
    $repo = $entry.Key
    Write-Host @"

cd "$Root\$repo"
git push -u origin main
git push origin v1.0.0
"@
}

Write-Host @"

cd "$deployPath"
git push -u origin main
"@

Write-Host "`n==> Validation locale possible" -ForegroundColor Cyan
Write-Host "  cd $deployPath\envs\dev"
Write-Host "  terraform init -backend=false"
Write-Host "  terraform validate"
