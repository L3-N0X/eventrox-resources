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
# Separate items with a comma.
# Example: "assets", "pack.mcmeta", "pack.png"
$FilesToZip = @("assets", "pack.mcmeta", "pack.png")

################################################################################
# SCRIPT LOGIC - DO NOT EDIT BELOW THIS LINE
################################################################################

Write-Host "🚀 Starting resource pack deployment..." -ForegroundColor Cyan

# 1. VERSIONING
# Check if .version file exists, create it if not.
if (-not (Test-Path ".version")) {
    "1.0.0" | Out-File .version
    Write-Host "Created initial .version file."
}

# Read, increment, and save the version.
$currentVersion = Get-Content .version
$major, $minor, $patch = $currentVersion.Split('.')
$patch = [int]$patch + 1
$newVersion = "$major.$minor.$patch"
$newVersion | Out-File .version
Write-Host "⬆️  Version updated from $currentVersion to $newVersion" -ForegroundColor Green

# 2. ZIPPING
Write-Host "📦 Creating zip archive: $ZipFileName..." -ForegroundColor Cyan
# Remove the old zip file if it exists to prevent errors
if (Test-Path $ZipFileName) {
    Remove-Item $ZipFileName
}
# Create the new zip archive
Compress-Archive -Path $FilesToZip -DestinationPath $ZipFileName

# 3. GIT OPERATIONS
Write-Host "📡 Committing and pushing changes to GitHub..." -ForegroundColor Cyan
# Add, commit, and push the changes
git add $ZipFileName
git add .version
git commit -m "chore: release version $newVersion"
git push origin $BranchName

# 4. OUTPUT
Write-Host "✅ Push successful! Generating links..." -ForegroundColor Green
# Get commit hash and file's SHA-1 hash
$commitHash = git rev-parse HEAD
$fileSha1 = (Get-FileHash $ZipFileName -Algorithm SHA1).Hash.ToLower()

# Construct the CDN URL
$cdnUrl = "https://cdn.jsdelivr.net/gh/$GithubUser/$GithubRepo@$commitHash/$ZipFileName"

# Print the final report
Write-Host ""
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Version:      $newVersion"
Write-Host "  Commit Hash:  $commitHash"
Write-Host "  File SHA-1:   $fileSha1"
Write-Host ""
Write-Host "  CDN URL:      $cdnUrl"
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host ""