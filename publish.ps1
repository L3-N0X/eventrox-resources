# Stop the script if any command fails
$ErrorActionPreference = "Stop"

################################################################################
# CONFIGURATION - CHANGE THESE VALUES
################################################################################

# Your GitHub username
$GithubUser = "L3-N0X"

# Your GitHub repository name
$GithubRepo = "eventrox-resources"

# The name of the branch you are pushing to
$BranchName = "main"

# The final name for your zip file
$ZipFileName = "server_textures.zip"

# List of files and folders to include in the zip.
# Separate items with a comma. Example: "assets", "pack.mcmeta"
$FilesToZip = @("assets", "pack.mcmeta")

################################################################################
# SCRIPT LOGIC - DO NOT EDIT BELOW THIS LINE
################################################################################

# PRE-FLIGHT CHECK: Verify that the GitHub CLI is installed.
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ ERROR: GitHub CLI ('gh') not found." -ForegroundColor Red
    Write-Host "Please install it from https://cli.github.com/ and authenticate with 'gh auth login'." -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Starting resource pack deployment..." -ForegroundColor Cyan

# 1. VERSIONING
if (-not (Test-Path ".version")) { "1.0.0" | Out-File .version }
$currentVersion = Get-Content .version
$major, $minor, $patch = $currentVersion.Split('.')
$patch = [int]$patch + 1
$newVersion = "$major.$minor.$patch"
$newVersion | Out-File .version
Write-Host "⬆️  Version updated from $currentVersion to $newVersion" -ForegroundColor Green

# The Git tag will be prefixed with 'v' (e.g., v1.0.3)
$tagName = "v$newVersion"

# 2. ZIPPING
Write-Host "📦 Creating zip archive: $ZipFileName..." -ForegroundColor Cyan
if (Test-Path $ZipFileName) { Remove-Item $ZipFileName }
Compress-Archive -Path $FilesToZip -DestinationPath $ZipFileName

# 3. GIT & GITHUB OPERATIONS
Write-Host "📡 Committing, tagging, and pushing to GitHub..." -ForegroundColor Cyan

# Commit the changes
git add $ZipFileName
git add .version
git commit -m "chore: release version $newVersion"
git push origin $BranchName

# Create and push the new tag
git tag $tagName
git push origin $tagName

# Create the GitHub Release and upload the zip file as an asset
Write-Host "🎉 Creating GitHub Release for tag $tagName..." -ForegroundColor Cyan
gh release create $tagName --title "Version $newVersion" --notes "Automated release for version $newVersion." "$ZipFileName"

# 4. OUTPUT
Write-Host "✅ Push and release successful! Generating links..." -ForegroundColor Green

# Calculate the SHA-1 hash for integrity checks
$fileSha1 = (Get-FileHash $ZipFileName -Algorithm SHA1).Hash.ToLower()

# Construct the new jsDelivr URL pointing to the tag
$cdnUrl = "https://cdn.jsdelivr.net/gh/$GithubUser/$GithubRepo@$tagName/$ZipFileName"

# Print the final report
Write-Host ""
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Version:      $newVersion"
Write-Host "  Tag:          $tagName"
Write-Host "  File SHA-1:   $fileSha1"
Write-Host ""
Write-Host "  CDN URL:      $cdnUrl"
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host ""