[CmdletBinding()]
param(
    [string]$UpstreamRemote = "upstream",
    [string]$UpstreamBranch = "master",
    [string]$MirrorBranch = "master",
    [string]$IntegrationBranch = "develop"
)

$ErrorActionPreference = "Stop"

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Run this script inside the platform fork."
}

$changes = git status --porcelain
if ($LASTEXITCODE -ne 0) { throw "Unable to inspect the working tree." }
if ($changes) { throw "Working tree is not clean. Commit or stash changes first." }

git remote get-url $UpstreamRemote *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Remote '$UpstreamRemote' is not configured. Add it with: git remote add upstream https://github.com/lsfusion/platform.git"
}

$startBranch = git branch --show-current
if ($LASTEXITCODE -ne 0 -or -not $startBranch) {
    throw "Detached HEAD is not supported."
}

git fetch $UpstreamRemote --prune --tags
if ($LASTEXITCODE -ne 0) { throw "Unable to fetch upstream." }

git switch $MirrorBranch
if ($LASTEXITCODE -ne 0) { throw "Unable to switch to $MirrorBranch." }
git merge --ff-only "$UpstreamRemote/$UpstreamBranch"
if ($LASTEXITCODE -ne 0) { throw "The mirror branch cannot be fast-forwarded." }

git switch $IntegrationBranch
if ($LASTEXITCODE -ne 0) { throw "Unable to switch to $IntegrationBranch." }
git merge --no-ff $MirrorBranch -m "Merge upstream/$UpstreamBranch into $IntegrationBranch"
if ($LASTEXITCODE -ne 0) {
    throw "Merge stopped. Resolve conflicts and commit, or run git merge --abort."
}

git switch $startBranch
if ($LASTEXITCODE -ne 0) { throw "Unable to return to $startBranch." }

Write-Host "Upstream synchronization completed locally. Review and test before pushing."
