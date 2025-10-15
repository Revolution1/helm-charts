# Repository Setup Guide

This guide explains how to set up the GitHub Pages (gh-pages) branch for hosting Helm charts and configure branch protection.

## Prerequisites

- GitHub repository with admin access
- Git installed locally
- Understanding of GitHub Pages and branch protection

## Creating the gh-pages Branch

The `gh-pages` branch is used by GitHub Pages to host the Helm chart repository index and packaged charts. The chart-releaser GitHub Action automatically publishes charts to this branch.

### Method 1: Using the Setup Script (Easiest)

A convenience script is provided to automate the branch creation:

```bash
# Run the setup script
.github/scripts/setup-gh-pages.sh
```

The script will:
- Create an empty orphan gh-pages branch
- Add an initial README.md
- Push the branch to GitHub
- Return you to your original branch

### Method 2: Using Git Commands (Manual)

Create an empty orphan branch for gh-pages:

```bash
# Navigate to your local repository
cd helm-charts

# Create an empty orphan branch
git checkout --orphan gh-pages

# Remove all files from the working tree
git rm -rf .

# Create an initial commit with a README
cat > README.md << 'EOF'
# Helm Charts Repository

This branch contains the published Helm charts and repository index.

Charts are automatically published here by GitHub Actions when changes are merged to the main branch.

## Usage

Add this Helm repository:

```bash
helm repo add revolution1 https://revolution1.github.io/helm-charts
helm repo update
```

View available charts:

```bash
helm search repo revolution1
```

## Automated Publishing

This branch is automatically updated by the chart-releaser GitHub Action. Do not manually commit to this branch.
EOF

# Add and commit the README
git add README.md
git commit -m "Initialize gh-pages branch"

# Push the branch to GitHub
git push origin gh-pages

# Switch back to main branch
git checkout main
```

### Method 3: Using GitHub Web Interface

1. Go to your repository on GitHub
2. Click on the branch dropdown (shows "main" by default)
3. Type `gh-pages` in the text field
4. Click "Create branch: gh-pages from 'main'"
5. Then follow the cleanup steps below using Git commands

After creating via web interface, clean up the branch:

```bash
git fetch origin
git checkout gh-pages
git rm -rf .
git commit -m "Clean gh-pages branch"
git push origin gh-pages
git checkout main
```

## Configuring GitHub Pages

After creating the gh-pages branch:

1. Go to your repository **Settings** on GitHub
2. Navigate to **Pages** in the left sidebar
3. Under **Source**, select:
   - Branch: `gh-pages`
   - Folder: `/ (root)`
4. Click **Save**
5. GitHub Pages will be published at: `https://<username>.github.io/<repository>`

Wait a few minutes for the initial deployment. You'll see a success message with your site URL.

## Protecting the gh-pages Branch

To prevent accidental modifications and ensure only GitHub Actions can update the branch:

### Basic Protection

1. Go to repository **Settings** > **Branches**
2. Click **Add branch protection rule**
3. Enter `gh-pages` as the branch name pattern
4. Enable the following settings:
   - ✅ **Require a pull request before merging**
     - Uncheck "Require approvals" (since this is automated)
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   - ✅ **Do not allow bypassing the above settings**
   - ✅ **Restrict who can push to matching branches**
     - Only allow GitHub Actions or specific users/teams
5. Click **Create** or **Save changes**

### Advanced Protection (Recommended)

For additional security:

1. In the same branch protection rule, also enable:
   - ✅ **Require linear history** - Prevents merge commits
   - ✅ **Include administrators** - Apply rules to admins too
   - ✅ **Allow force pushes** - Only for specific actors
     - Add exception for `github-actions[bot]`
   - ✅ **Allow deletions** - Disable to prevent branch deletion

2. Consider using **Rulesets** (newer GitHub feature):
   - Go to **Settings** > **Rules** > **Rulesets**
   - Create a new ruleset targeting the `gh-pages` branch
   - Configure enforcement status: **Active**
   - Add rules:
     - Restrict creations
     - Restrict updates (allow only GitHub Actions)
     - Restrict deletions
     - Block force pushes (with exceptions for Actions)

### Allow GitHub Actions to Push

Ensure your GitHub Actions workflow has permission to push to gh-pages:

In your `.github/workflows/release.yaml`, the job should have:

```yaml
permissions:
  contents: write  # Required to push to gh-pages
```

This is already configured in the existing release workflow.

## Verifying the Setup

### Check GitHub Pages Status

1. Go to **Settings** > **Pages**
2. Verify the site is published
3. Visit your Helm repository URL: `https://revolution1.github.io/helm-charts`

### Test Helm Repository

```bash
# Add the Helm repository
helm repo add revolution1 https://revolution1.github.io/helm-charts

# Update repositories
helm repo update

# Search for charts
helm search repo revolution1

# View repository index
curl https://revolution1.github.io/helm-charts/index.yaml
```

## Workflow Integration

The chart-releaser action (`.github/workflows/release.yaml`) automatically:

1. Detects changed charts
2. Packages new chart versions
3. Creates GitHub releases
4. Updates the gh-pages branch with:
   - Packaged chart files (`.tgz`)
   - Updated `index.yaml` file
5. GitHub Pages serves these files

## Troubleshooting

### GitHub Pages Not Publishing

- Check **Settings** > **Pages** for error messages
- Verify the gh-pages branch exists and has content
- Ensure GitHub Pages source is set correctly
- Wait 1-2 minutes after pushing for deployment

### Charts Not Appearing

- Check the release workflow run in **Actions** tab
- Verify chart versions were bumped in `Chart.yaml`
- Check that `index.yaml` exists in gh-pages branch
- Review workflow logs for errors

### Permission Errors

- Verify `GITHUB_TOKEN` has `contents: write` permission
- Check branch protection rules don't block GitHub Actions
- Ensure Actions are allowed in repository settings

## Maintenance

### Cleaning Up Old Releases

The gh-pages branch will accumulate chart versions over time. To clean up:

```bash
git checkout gh-pages
# Remove old chart versions (keep recent ones)
# Update index.yaml accordingly
git add .
git commit -m "Clean up old chart versions"
git push origin gh-pages
git checkout main
```

Note: Be careful when cleaning up, as users may still reference old versions.

## References

- [Helm Chart Releaser Action](https://github.com/helm/chart-releaser-action)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Helm Repository Documentation](https://helm.sh/docs/topics/chart_repository/)

## Security Considerations

- Never commit sensitive data to gh-pages
- Use branch protection to prevent unauthorized changes
- Regularly review GitHub Actions workflow permissions
- Monitor repository access logs
- Consider using deployment environments for additional control
