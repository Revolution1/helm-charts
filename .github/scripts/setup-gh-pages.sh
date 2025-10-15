#!/bin/bash
# Script to create and initialize an empty gh-pages branch
# This script is provided as a reference - review before running

set -e

echo "🚀 Setting up gh-pages branch for Helm Charts repository"
echo ""

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check if gh-pages branch already exists locally
if git show-ref --verify --quiet refs/heads/gh-pages; then
    echo "⚠️  Warning: gh-pages branch already exists locally"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    git branch -D gh-pages
fi

# Check if gh-pages branch exists remotely
if git ls-remote --heads origin gh-pages | grep -q gh-pages; then
    echo "⚠️  Warning: gh-pages branch already exists on remote"
    read -p "Do you want to proceed? This will not delete the remote branch. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Get the repository information
REPO_URL=$(git config --get remote.origin.url)
REPO_NAME=$(basename -s .git "$REPO_URL")
REPO_OWNER=$(basename $(dirname "$REPO_URL") | sed 's/.*://')

echo "📦 Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Save current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "💾 Current branch: $CURRENT_BRANCH"

# Create orphan branch
echo "🌱 Creating orphan gh-pages branch..."
git checkout --orphan gh-pages

# Remove all files
echo "🧹 Cleaning working directory..."
git rm -rf . > /dev/null 2>&1 || true

# Create README.md
echo "📝 Creating README.md..."
cat > README.md << EOF
# Helm Charts Repository

This branch contains the published Helm charts and repository index.

Charts are automatically published here by GitHub Actions when changes are merged to the main branch.

## Usage

Add this Helm repository:

\`\`\`bash
helm repo add $REPO_OWNER https://$REPO_OWNER.github.io/$REPO_NAME
helm repo update
\`\`\`

View available charts:

\`\`\`bash
helm search repo $REPO_OWNER
\`\`\`

## Automated Publishing

This branch is automatically updated by the chart-releaser GitHub Action. Do not manually commit to this branch unless necessary.

## Documentation

For setup instructions and branch protection configuration, see:
- [Setup Guide](https://github.com/$REPO_OWNER/$REPO_NAME/blob/main/SETUP.md)
- [设置指南](https://github.com/$REPO_OWNER/$REPO_NAME/blob/main/SETUP_zh.md)
EOF

# Add and commit
echo "✅ Committing initial README..."
git add README.md
git commit -m "Initialize gh-pages branch for Helm repository"

# Push to remote
echo "🚀 Pushing gh-pages branch to remote..."
if git push origin gh-pages; then
    echo "✅ Successfully created and pushed gh-pages branch!"
else
    echo "❌ Failed to push gh-pages branch"
    echo "You may need to manually push: git push origin gh-pages"
fi

# Return to original branch
echo "🔄 Returning to $CURRENT_BRANCH branch..."
git checkout "$CURRENT_BRANCH"

echo ""
echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure GitHub Pages in repository Settings > Pages"
echo "   - Source: gh-pages branch"
echo "   - Folder: / (root)"
echo ""
echo "2. Set up branch protection for gh-pages branch"
echo "   - Go to Settings > Branches > Add branch protection rule"
echo "   - See SETUP.md for detailed instructions"
echo ""
echo "3. Your Helm repository will be available at:"
echo "   https://$REPO_OWNER.github.io/$REPO_NAME"
echo ""
echo "For detailed setup instructions, see:"
echo "  - SETUP.md (English)"
echo "  - SETUP_zh.md (中文)"
