#!/usr/bin/env bash

# VA Repositories Setup Script
# Clones all repositories needed for VA development environment
# Used by the va-tmux session template

set -e

# Color codes for output (using tput for system colors)
if command -v tput &> /dev/null && [ -t 1 ]; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    BLUE=$(tput setaf 4)
    BOLD=$(tput bold)
    NC=$(tput sgr0) # No Color
else
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    BOLD='\033[1m'
fi

# Configuration
BASE_DIR="$HOME/code/department-of-veterans-affairs"
GITHUB_ORG="department-of-veterans-affairs"

# Define repositories to clone
declare -A REPOS=(
    ["vets-website"]="git@github.com:${GITHUB_ORG}/vets-website.git"
    ["next-build"]="git@github.com:${GITHUB_ORG}/next-build.git"
    ["vets-api"]="git@github.com:${GITHUB_ORG}/vets-api.git"
    ["component-library"]="git@github.com:${GITHUB_ORG}/component-library.git"
    ["va.gov-cms"]="git@github.com:${GITHUB_ORG}/va.gov-cms.git"
)

# Arrays to track what needs to be cloned
declare -a EXISTING_REPOS=()
declare -a MISSING_REPOS=()

echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}VA Development Repositories Setup${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""

# Create base directory if it doesn't exist
if [ ! -d "$BASE_DIR" ]; then
    echo -e "${YELLOW}Creating base directory: ${BASE_DIR}${NC}"
    mkdir -p "$BASE_DIR"
    echo ""
fi

# Check which repos exist and which are missing
echo -e "${BLUE}Checking existing repositories...${NC}"
echo ""

for repo in "${!REPOS[@]}"; do
    if [ -d "$BASE_DIR/$repo" ]; then
        echo -e "  ${GREEN}✓${NC} $repo (already exists)"
        EXISTING_REPOS+=("$repo")
    else
        echo -e "  ${YELLOW}○${NC} $repo (missing)"
        MISSING_REPOS+=("$repo")
    fi
done

echo ""

# If all repos exist, exit
if [ ${#MISSING_REPOS[@]} -eq 0 ]; then
    echo -e "${GREEN}All repositories are already cloned!${NC}"
    echo -e "${GREEN}Nothing to do.${NC}"
    exit 0
fi

# Display summary and ask for confirmation
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""
echo -e "  ${GREEN}Existing repositories:${NC} ${#EXISTING_REPOS[@]}"
echo -e "  ${YELLOW}Repositories to clone:${NC} ${#MISSING_REPOS[@]}"
echo ""

if [ ${#MISSING_REPOS[@]} -gt 0 ]; then
    echo -e "${YELLOW}The following repositories will be cloned:${NC}"
    for repo in "${MISSING_REPOS[@]}"; do
        echo -e "  - $repo"
    done
    echo ""
fi

# Ask for confirmation
read -p "Do you want to proceed with cloning? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Cancelled by user.${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}Cloning Repositories${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""

# Clone missing repositories
CLONED_COUNT=0
FAILED_COUNT=0
declare -a FAILED_REPOS=()

for repo in "${MISSING_REPOS[@]}"; do
    echo -e "${BLUE}Cloning ${repo}...${NC}"

    if git clone "${REPOS[$repo]}" "$BASE_DIR/$repo"; then
        echo -e "${GREEN}✓ Successfully cloned ${repo}${NC}"
        CLONED_COUNT=$((CLONED_COUNT + 1))
    else
        echo -e "${RED}✗ Failed to clone ${repo}${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_REPOS+=("$repo")
    fi
    echo ""
done

# Display final summary
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""
echo -e "  ${GREEN}Successfully cloned:${NC} $CLONED_COUNT"
echo -e "  ${YELLOW}Already existed:${NC} ${#EXISTING_REPOS[@]}"

if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "  ${RED}Failed to clone:${NC} $FAILED_COUNT"
    echo ""
    echo -e "${RED}Failed repositories:${NC}"
    for repo in "${FAILED_REPOS[@]}"; do
        echo -e "  - $repo"
    done
    echo ""
    echo -e "${YELLOW}Note: Make sure your SSH keys are properly configured for GitHub.${NC}"
    echo -e "${YELLOW}Run: ssh -T git@github.com to test your connection.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All repositories are ready!${NC}"
echo -e "${GREEN}You can now run 'va-tmux' to start your development environment.${NC}"
