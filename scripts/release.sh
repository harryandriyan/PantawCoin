#!/bin/bash

# Check if a version was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.0.1"
  exit 1
fi

VERSION=$1
VERSION_TAG="v$VERSION"

# Update version in main.swift
sed -i '' "s/let APP_VERSION = \".*\"/let APP_VERSION = \"$VERSION\"/" Sources/PantawCoin/main.swift

# Commit the version change
git add Sources/PantawCoin/main.swift
git commit -m "Bump version to $VERSION"

# Create a tag
git tag -a "$VERSION_TAG" -m "Release $VERSION_TAG"

# Push changes and tag
echo "Changes committed and tag created. Run the following commands to push:"
echo "git push origin main"
echo "git push origin $VERSION_TAG"
echo ""
echo "After pushing the tag, GitHub Actions will automatically build and create a release." 