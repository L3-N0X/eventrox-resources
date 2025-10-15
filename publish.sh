#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

################################################################################
# CONFIGURATION - CHANGE THESE VALUES
################################################################################

# Your GitHub username
GITHUB_USER="L3-N0X"

# Your GitHub repository name
GITHUB_REPO="eventrox-resources"

# The name of the branch you are pushing to (e.g., main, master)
BRANCH_NAME="main"

# The final name for your zip file
ZIP_FILE_NAME="server_textures.zip"

# List of files and folders to include in the zip.
# Use spaces to separate items. Folders should end with a '/'.
# Example: "assets/ pack.mcmeta pack.png"
FILES_TO_ZIP="assets/ pack.mcmeta pack.png"

################################################################################
# SCRIPT LOGIC - DO NOT EDIT BELOW THIS LINE
################################################################################

echo "🚀 Starting resource pack deployment..."

# 1. VERSIONING
# Check if .version file exists, create it if not.
if [ ! -f .version ]; then
    echo "1.0.0" > .version
    echo "Created initial .version file."
fi

# Read the current version, increment the patch number, and save it back.
current_version=$(cat .version)
IFS='.' read -r major minor patch <<< "$current_version"
patch=$((patch + 1))
new_version="$major.$minor.$patch"
echo "$new_version" > .version
echo "⬆️  Version updated from $current_version to $new_version"

# 2. ZIPPING
echo "📦 Creating zip archive: $ZIP_FILE_NAME..."
# Create the zip archive, overwriting if it exists.
# The '-x' flag excludes files/patterns from the zip.
zip -r "$ZIP_FILE_NAME" $FILES_TO_ZIP -x "*.git*" "deploy.sh" ".version"

# 3. GIT OPERATIONS
echo "📡 Committing and pushing changes to GitHub..."
# Add the updated files to git
git add "$ZIP_FILE_NAME" .version

# Commit the changes with the new version number
git commit -m "chore: release version $new_version"

# Push the commit to the remote repository
git push origin "$BRANCH_NAME"

# 4. OUTPUT
echo "✅ Push successful! Generating links..."
# Get the full hash of the new commit
commit_hash=$(git rev-parse HEAD)

# Calculate the SHA-1 hash of the zip file
file_sha1=$(sha1sum "$ZIP_FILE_NAME" | awk '{print $1}')

# Construct the jsDelivr URL
cdn_url="https://cdn.jsdelivr.net/gh/$GITHUB_USER/$GITHUB_REPO@$commit_hash/$ZIP_FILE_NAME"

# Print the final results in a clean format
echo ""
echo "========================================================"
echo "✅ Deployment Complete!"
echo ""
echo "  Version:      $new_version"
echo "  Commit Hash:  $commit_hash"
echo "  File SHA-1:   $file_sha1"
echo ""
echo "  CDN URL:      $cdn_url"
echo "========================================================"
echo ""