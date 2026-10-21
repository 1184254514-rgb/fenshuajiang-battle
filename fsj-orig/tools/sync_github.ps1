param(
    [string]$RepositoryPath = 'E:\gpt\game\_handoff_tmp\fenshuajiang-battle-sync',
    [switch]$Commit,
    [switch]$Push,
    [string]$Message = 'Sync verified Godot and Lua project changes'
)
$ErrorActionPreference = 'Stop'
$expectedRemote = 'https://github.com/1184254514-rgb/fenshuajiang-battle.git'
$sourcePath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$repositoryFull = (Resolve-Path -LiteralPath $RepositoryPath).Path.TrimEnd('\')
$topLevel = (& git -C $repositoryFull rev-parse --show-toplevel).Trim().Replace('/', '\').TrimEnd('\')
if ($LASTEXITCODE -ne 0 -or $topLevel -ne $repositoryFull) { throw 'RepositoryPath must be the exact Git checkout root.' }
$remote = (& git -C $repositoryFull remote get-url origin).Trim()
if ($remote -ne $expectedRemote) { throw 'The remote is not the user-authorized GitHub repository.' }
$destination = [IO.Path]::GetFullPath((Join-Path $repositoryFull 'fsj-orig')).TrimEnd('\')
if ($destination -ne ($repositoryFull + '\fsj-orig') -or $destination -eq $sourcePath) { throw 'Refusing an unexpected mirror target.' }
# MIR removes stale files only in this verified fsj-orig copy. The repository
# root and its existing documentation are never mirror targets.
& robocopy $sourcePath $destination /MIR /XD .godot .git __pycache__ /XF *.log export_credentials.cfg override.cfg .env .env.* /NJH /NJS /NDL /NFL /NP
if ($LASTEXITCODE -ge 8) { throw 'Source synchronization failed.' }
& git -C $repositoryFull add -- fsj-orig
if ($LASTEXITCODE -ne 0) { throw 'Could not stage the synchronized source.' }
if ($Commit) {
    & git -C $repositoryFull diff --cached --quiet
    if ($LASTEXITCODE -eq 1) {
        & git -C $repositoryFull commit -m $Message
        if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
    }
}
if ($Push) {
    & git -C $repositoryFull push origin HEAD:main
    if ($LASTEXITCODE -ne 0) { throw 'GitHub push failed; do not report a completed sync.' }
    $localHead = (& git -C $repositoryFull rev-parse HEAD).Trim()
    $remoteHead = ((& git -C $repositoryFull ls-remote origin refs/heads/main) -split '\s+')[0]
    if ($localHead -ne $remoteHead) { throw 'Remote verification failed.' }
    Write-Output ('Verified GitHub commit: ' + $localHead)
}
