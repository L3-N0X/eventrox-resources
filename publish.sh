#!/usr/bin/env bash
#
# Resource pack deployment script.
# Bumps the patch version, rebuilds server_textures.zip, then commits, tags,
# pushes and creates the GitHub release the plugin's ResourcepackManager fetches.
#
# Usage: ./publish.sh

set -euo pipefail

cd "$(dirname "$0")"

################################################################################
# CONFIGURATION - CHANGE THESE VALUES
################################################################################

# Your GitHub username
GITHUB_USER="L3-N0X"

# Your GitHub repository name
GITHUB_REPO="eventrox-resources"

# The name of the branch you are pushing to
BRANCH_NAME="main"

# The final name for your zip file
ZIP_FILE_NAME="server_textures.zip"

# List of files and folders to include in the zip.
# Separate items with a space.
FILES_TO_ZIP=(assets pack.mcmeta pack.png)

################################################################################
# SCRIPT LOGIC - DO NOT EDIT BELOW THIS LINE
################################################################################

if [ -t 1 ]; then
    RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

info()  { echo "${CYAN}$*${RESET}"; }
ok()    { echo "${GREEN}$*${RESET}"; }
warn()  { echo "${YELLOW}$*${RESET}"; }
fail()  { echo "${RED}$*${RESET}" >&2; exit 1; }

# PRE-FLIGHT CHECKS
command -v gh  >/dev/null 2>&1 || { fail "❌ ERROR: GitHub CLI ('gh') not found.";      warn "Install it from https://cli.github.com/ and run 'gh auth login'."; }
command -v git >/dev/null 2>&1 || fail "❌ ERROR: git not found."
command -v zip >/dev/null 2>&1 || fail "❌ ERROR: zip not found. Install it with 'sudo apt install zip'."
command -v sha1sum >/dev/null 2>&1 || fail "❌ ERROR: sha1sum not found (coreutils)."

git rev-parse --git-dir >/dev/null 2>&1 || fail "❌ ERROR: $(pwd) is not a git repository."

echo ""
info "🚀 Starting resource pack deployment..."

# 1. VERSIONING
[ -f .version ] || echo "1.0.0" > .version
CURRENT_VERSION=$(tr -d '[:space:]' < .version)

if ! [[ $CURRENT_VERSION =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    fail "❌ ERROR: .version contains '$CURRENT_VERSION', expected 'major.minor.patch'."
fi

MAJOR=${BASH_REMATCH[1]}
MINOR=${BASH_REMATCH[2]}
PATCH=${BASH_REMATCH[3]}
NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
echo "$NEW_VERSION" > .version
ok "⬆️  Version updated from $CURRENT_VERSION to $NEW_VERSION"

# Update pack.mcmeta description with the new version
if [ -f pack.mcmeta ]; then
    sed -E -i "s/(v)[0-9]+\.[0-9]+\.[0-9]+/\1$NEW_VERSION/g" pack.mcmeta
    ok "📝 Updated pack.mcmeta description with new version."
else
    warn "⚠️  Warning: pack.mcmeta not found. Skipping description update."
fi

# The Git tag will be prefixed with 'v' (e.g., v1.0.3)
TAG_NAME="v$NEW_VERSION"

# 2. ZIPPING
info "📦 Creating zip archive: $ZIP_FILE_NAME..."
rm -f "$ZIP_FILE_NAME"
zip -r -q "$ZIP_FILE_NAME" "${FILES_TO_ZIP[@]}"

# 3. GIT & GITHUB OPERATIONS
info "📡 Committing, tagging, and pushing to GitHub..."

# Commit everything, not just the zip, so the assets stay in sync with the release.
git add -A
if git diff --cached --quiet; then
    fail "❌ ERROR: nothing to commit."
fi
git commit -q -m "chore: release version $NEW_VERSION"
git push -q origin "$BRANCH_NAME"

# Create and push the new tag
git tag "$TAG_NAME"
git push -q origin "$TAG_NAME"

# Calculate the SHA-1 hash for integrity checks
FILE_SHA1=$(sha1sum "$ZIP_FILE_NAME" | cut -d' ' -f1)

# Create the GitHub Release and upload the zip file as an asset
info "🎉 Creating GitHub Release for tag $TAG_NAME..."

NOTES=$(printf 'SHA-1: %s\nAutomated release for version %s.\n' "$FILE_SHA1" "$NEW_VERSION")

gh release create "$TAG_NAME" --title "Version $NEW_VERSION" --notes "$NOTES" "$ZIP_FILE_NAME"

# 4. OUTPUT
ok "✅ Push and release successful! Generating links..."

# Construct the new jsDelivr URL pointing to the tag
CDN_URL="https://cdn.jsdelivr.net/gh/$GITHUB_USER/$GITHUB_REPO@$TAG_NAME/$ZIP_FILE_NAME"

echo ""
echo "${YELLOW}========================================================${RESET}"
ok "✅ Deployment Complete!"
echo ""
echo "  Version:      $NEW_VERSION"
echo "  Tag:          $TAG_NAME"
echo "  File SHA-1:   $FILE_SHA1"
echo ""
echo "  CDN URL:      $CDN_URL"
echo "${YELLOW}========================================================${RESET}"
echo ""
