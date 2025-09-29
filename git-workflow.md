# Git Workflow Commands

This document provides useful Git commands for working with the Jenkins Ansible Automation project.

## Repository Status

```bash
# Check repository status
git status

# View commit history
git log --oneline --decorate --graph

# View tags
git tag -l

# Show current branch
git branch --show-current
```

## Development Workflow

### Creating a Feature Branch

```bash
# Create and switch to a new feature branch
git checkout -b feature/your-feature-name

# Or use the newer syntax
git switch -c feature/your-feature-name
```

### Making Changes

```bash
# Stage specific files
git add file1.yml file2.yml

# Stage all changes
git add .

# Commit with descriptive message
git commit -m "feat: add new functionality for Jenkins plugin management"

# Amend the last commit (if needed)
git commit --amend -m "Updated commit message"
```

### Pushing Changes

```bash
# Push feature branch to remote
git push origin feature/your-feature-name

# Set upstream branch for future pushes
git push -u origin feature/your-feature-name
```

### Merging Changes

```bash
# Switch back to main branch
git switch main

# Pull latest changes
git pull origin main

# Merge feature branch
git merge feature/your-feature-name

# Delete merged feature branch
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```

## Release Management

### Creating a Release

```bash
# Update VERSION file
echo "1.1.0" > VERSION

# Update CHANGELOG.md with new version information
# Then commit changes
git add VERSION CHANGELOG.md
git commit -m "release: version 1.1.0"

# Create annotated tag
git tag -a v1.1.0 -m "Release version 1.1.0

New features:
- Feature 1
- Feature 2

Bug fixes:
- Fix 1
- Fix 2"

# Push commits and tags
git push origin main
git push origin --tags
```

### Viewing Releases

```bash
# List all tags
git tag -l

# Show tag details
git show v1.0.0

# List commits since last tag
git log v1.0.0..HEAD --oneline
```

## Maintenance Commands

### Cleaning Up

```bash
# Remove untracked files (dry run first)
git clean -n

# Actually remove untracked files
git clean -f

# Remove untracked directories too
git clean -fd
```

### Viewing Changes

```bash
# Show unstaged changes
git diff

# Show staged changes
git diff --staged

# Show changes between commits
git diff v1.0.0..HEAD

# Show files changed in last commit
git diff --name-only HEAD~1
```

### Branch Management

```bash
# List all branches
git branch -a

# Delete local branch
git branch -d branch-name

# Delete remote branch
git push origin --delete branch-name

# Rename current branch
git branch -m new-branch-name
```

## Advanced Operations

### Stashing Changes

```bash
# Stash current changes
git stash

# Stash with message
git stash save "Work in progress on feature X"

# List stashes
git stash list

# Apply last stash
git stash pop

# Apply specific stash
git stash apply stash@{1}
```

### Cherry-picking

```bash
# Cherry-pick a specific commit
git cherry-pick <commit-hash>

# Cherry-pick without committing
git cherry-pick --no-commit <commit-hash>
```

### Undoing Changes

```bash
# Undo last commit (keeping changes)
git reset --soft HEAD~1

# Undo last commit (discarding changes)
git reset --hard HEAD~1

# Revert a commit (creates new commit)
git revert <commit-hash>
```

## Remote Repository Setup

If you want to push to a remote repository (GitHub, GitLab, etc.):

```bash
# Add remote origin
git remote add origin https://github.com/yourusername/jenkins-ansible-automation.git

# Verify remote
git remote -v

# Push to remote
git push -u origin main

# Push all tags
git push origin --tags
```

## Pre-commit Hook

The repository includes a pre-commit hook that runs automatically. To bypass it (not recommended):

```bash
# Skip pre-commit hook
git commit --no-verify -m "emergency fix"

# Test pre-commit hook manually
.git/hooks/pre-commit
```

## Useful Aliases

Add these to your Git config for faster workflow:

```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'
git config --global alias.graph 'log --oneline --decorate --graph --all'
```

## Project-Specific Commands

### Testing Before Commit

```bash
# Run syntax check
make test-syntax

# Run full Molecule tests
make test-molecule-full

# Run specific role test
make test-jenkins-role
```

### Deployment Commands

```bash
# Deploy entire stack
make deploy-all

# Deploy individual components
make install-jenkins
make setup-nginx-proxy
make install-ssl-cert
```

This workflow ensures code quality and maintains project standards while enabling efficient development and collaboration.
