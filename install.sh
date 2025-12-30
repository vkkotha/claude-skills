#!/usr/bin/env bash

# Claude Developer Skills Kit (cdskit) Installer
#
# Usage:
#   ./install.sh [OPTIONS] [SKILL_NAMES...]
#
# Options:
#   --list              List available skills
#   --prefix PREFIX     Set skill name prefix (default: cdskit-)
#   --global            Install to ~/.claude/skills/ (default)
#   --local             Install to ./.claude/skills/
#   --all               Install all skills
#   --dry-run           Show what would be installed without installing
#   --help              Show this help message
#
# Examples:
#   ./install.sh --list
#   ./install.sh --all
#   ./install.sh bitbucket-pr-reviewer
#   ./install.sh --prefix myteam- --all
#   ./install.sh --prefix "" --local bitbucket-pr-reviewer

set -e

# Default values
DEFAULT_PREFIX="cdskit-"
PREFIX="$DEFAULT_PREFIX"
INSTALL_MODE="global"
DRY_RUN=false
INSTALL_ALL=false
SKILLS_TO_INSTALL=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"
SKILLS_JSON="${SCRIPT_DIR}/skills.json"

# Check if jq is available, otherwise use basic parsing
HAS_JQ=false
if command -v jq >/dev/null 2>&1; then
    HAS_JQ=true
fi

# Print colored output
print_info() { echo -e "${BLUE}$1${NC}"; }
print_success() { echo -e "${GREEN}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }

# Normalize prefix to ensure it ends with '-' (unless empty)
# Allows users to specify "myteam" or "myteam-" and both work
normalize_prefix() {
    local prefix="$1"
    if [ -n "$prefix" ] && [[ "$prefix" != *- ]]; then
        echo "${prefix}-"
    else
        echo "$prefix"
    fi
}

# Show help
show_help() {
    cat << EOF
Claude Developer Skills Kit (cdskit) Installer

Usage:
  ./install.sh [OPTIONS] [SKILL_NAMES...]

Options:
  --list              List available skills
  --prefix PREFIX     Set skill name prefix (default: ${DEFAULT_PREFIX})
  --global            Install to ~/.claude/skills/ (default)
  --local             Install to ./.claude/skills/
  --all               Install all skills
  --dry-run           Show what would be installed without installing
  --help              Show this help message

Examples:
  ./install.sh --list
  ./install.sh --all
  ./install.sh bitbucket-pr-reviewer
  ./install.sh --prefix myteam- --all
  ./install.sh --prefix "" --local bitbucket-pr-reviewer pr-worktree

Skills are installed with the prefix applied to their names:
  mcp-setup -> ${DEFAULT_PREFIX}mcp-setup

EOF
}

# Get target directory based on install mode
get_target_dir() {
    if [ "$INSTALL_MODE" = "local" ]; then
        echo "./.claude/skills"
    else
        echo "$HOME/.claude/skills"
    fi
}

# Get the base skill name (strip default prefix if present)
get_base_skill_name() {
    local name=$1
    echo "$name" | sed "s/^${DEFAULT_PREFIX}//"
}

# Get the source folder name for a skill (with default prefix)
get_source_folder_name() {
    local skill=$1
    # If skill already has default prefix, use as-is; otherwise add it
    if [[ "$skill" == ${DEFAULT_PREFIX}* ]]; then
        echo "$skill"
    else
        echo "${DEFAULT_PREFIX}${skill}"
    fi
}

# List available skills
list_skills() {
    local target_dir
    target_dir=$(get_target_dir)
    local prefixed_target_name
    # Display prefix without trailing dash for cleaner output
    local display_prefix="${PREFIX%-}"

    echo ""
    print_info "Available Skills (prefix: ${display_prefix:-<none>})"
    print_info "Install location: $target_dir"
    echo ""

    for skill_dir in "$SKILLS_DIR"/*/; do
        if [ -d "$skill_dir" ]; then
            folder_name=$(basename "$skill_dir")
            # Display the base name (without default prefix) for cleaner output
            skill_name=$(get_base_skill_name "$folder_name")

            # Check if skill is already installed
            prefixed_target_name="${PREFIX}${skill_name}"
            local installed_marker=""
            if [ -d "${target_dir}/${prefixed_target_name}" ]; then
                installed_marker="${GREEN}[installed]${NC} "
            fi

            # Get description from skill.json if it exists
            skill_json="${skill_dir}skill.json"
            if [ -f "$skill_json" ]; then
                if $HAS_JQ; then
                    description=$(jq -r '.description // "No description"' "$skill_json")
                else
                    description=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$skill_json" | sed 's/.*: *"//' | sed 's/"$//' || echo "No description")
                fi
            else
                description="No description"
            fi

            # Get dependencies
            deps=""
            if [ -f "$skill_json" ]; then
                if $HAS_JQ; then
                    required_deps=$(jq -r '.dependencies.required // [] | join(", ")' "$skill_json")
                    if [ -n "$required_deps" ] && [ "$required_deps" != "" ]; then
                        deps=" [requires: $required_deps]"
                    fi
                fi
            fi

            printf "  ${GREEN}%-25s${NC} ${installed_marker}%s${YELLOW}%s${NC}\n" "$skill_name" "$description" "$deps"
        fi
    done

    echo ""
    print_info "Install with: ./install.sh <skill-name>"
    print_info "Install all:  ./install.sh --all"
    echo ""
}

# Get all skill names (returns base names without default prefix)
get_all_skills() {
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [ -d "$skill_dir" ]; then
            folder_name=$(basename "$skill_dir")
            get_base_skill_name "$folder_name"
        fi
    done
}

# Get required dependencies for a skill
get_dependencies() {
    local skill_name=$1
    local source_folder
    source_folder=$(get_source_folder_name "$skill_name")
    local skill_json="${SKILLS_DIR}/${source_folder}/skill.json"

    if [ -f "$skill_json" ] && $HAS_JQ; then
        jq -r '.dependencies.required // [] | .[]' "$skill_json" 2>/dev/null || true
    fi
}

# Resolve all dependencies (recursive)
# Compatible with bash 3.x (macOS default)
resolve_dependencies() {
    local skills=("$@")
    local tmpfile
    local processed_file

    tmpfile=$(mktemp)
    processed_file=$(mktemp)

    for skill in "${skills[@]}"; do
        resolve_all_deps "$skill" "$tmpfile" "$processed_file"
    done

    # Return unique list in dependency order
    awk '!seen[$0]++' "$tmpfile"

    # Cleanup
    rm -f "$tmpfile" "$processed_file"
}

# Simple dependency resolution without bash 4.3+ features
# Uses a file-based approach for compatibility with older bash versions
resolve_all_deps() {
    local skill=$1
    local tmpfile=$2
    local processed_file=$3

    # Skip if already processed
    if grep -q "^${skill}$" "$processed_file" 2>/dev/null; then
        return
    fi
    echo "$skill" >> "$processed_file"

    # Get dependencies
    local deps
    deps=$(get_dependencies "$skill")

    # Process dependencies first
    for dep in $deps; do
        resolve_all_deps "$dep" "$tmpfile" "$processed_file"
    done

    # Add this skill after its dependencies
    echo "$skill" >> "$tmpfile"
}

# Replace default prefix (cdskit-) with custom prefix in file content
apply_prefix() {
    local content="$1"
    local prefix="$2"
    # Replace the default prefix with the custom one
    echo "$content" | sed "s/cdskit-/${prefix}/g"
}

# Install a single skill
install_skill() {
    local skill_name=$1
    local target_dir=$2
    local prefix=$3

    # Get source folder (with default prefix) and destination name (with custom prefix)
    local source_folder
    source_folder=$(get_source_folder_name "$skill_name")
    local source_dir="${SKILLS_DIR}/${source_folder}"
    local prefixed_name="${prefix}${skill_name}"
    local dest_dir="${target_dir}/${prefixed_name}"

    if [ ! -d "$source_dir" ]; then
        print_error "Skill not found: $skill_name (looked in $source_dir)"
        return 1
    fi

    if $DRY_RUN; then
        print_info "[DRY RUN] Would install: $skill_name -> $dest_dir"
        return 0
    fi

    print_info "Installing: $skill_name -> $prefixed_name"

    # Create destination directory
    mkdir -p "$dest_dir"

    # Copy and transform files
    for file in "$source_dir"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")

            # For text files, apply prefix substitution
            case "$filename" in
                *.md|*.json|*.sh|*.txt)
                    content=$(cat "$file")
                    transformed=$(apply_prefix "$content" "$prefix")
                    echo "$transformed" > "${dest_dir}/${filename}"

                    # Preserve executable permission for scripts
                    if [[ "$filename" == *.sh ]]; then
                        chmod +x "${dest_dir}/${filename}"
                    fi
                    ;;
                *)
                    # Binary or unknown files, just copy
                    cp "$file" "${dest_dir}/${filename}"
                    ;;
            esac
        elif [ -d "$file" ]; then
            # Copy directories (like templates/)
            dirname=$(basename "$file")
            cp -r "$file" "${dest_dir}/${dirname}"
        fi
    done

    print_success "  Installed: $prefixed_name"
}

# Main installation function
do_install() {
    local skills=("$@")
    local target_dir

    # Determine target directory
    if [ "$INSTALL_MODE" = "local" ]; then
        target_dir="./.claude/skills"
    else
        target_dir="$HOME/.claude/skills"
    fi

    # Resolve dependencies
    print_info "Resolving dependencies..."
    local resolved_skills
    resolved_skills=$(resolve_dependencies "${skills[@]}")

    echo ""
    print_info "Skills to install (with dependencies):"
    for skill in $resolved_skills; do
        echo "  - $skill -> ${PREFIX}${skill}"
    done
    echo ""

    # Create target directory
    if ! $DRY_RUN; then
        mkdir -p "$target_dir"
    fi

    # Install each skill
    for skill in $resolved_skills; do
        install_skill "$skill" "$target_dir" "$PREFIX"
    done

    echo ""
    if $DRY_RUN; then
        print_warning "Dry run complete. No files were installed."
    else
        print_success "Installation complete!"
        echo ""
        print_info "Skills installed to: $target_dir"
        echo ""
        print_info "Next steps:"
        echo "  1. Restart Claude Code to load the new skills"
        echo "  2. Check skill documentation in each skill's SKILL.md"

        # Check if mcp-setup was installed
        if echo "$resolved_skills" | grep -q "mcp-setup"; then
            echo ""
            print_info "MCP Setup:"
            echo "  The ${PREFIX}mcp-setup skill was installed."
            echo "  Use it to configure MCP servers for skills that require them."
        fi
    fi
}

# Parse command line arguments
LIST_SKILLS=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                LIST_SKILLS=true
                shift
                ;;
            --prefix)
                PREFIX="$2"
                shift 2
                ;;
            --global)
                INSTALL_MODE="global"
                shift
                ;;
            --local)
                INSTALL_MODE="local"
                shift
                ;;
            --all)
                INSTALL_ALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
            *)
                SKILLS_TO_INSTALL+=("$1")
                shift
                ;;
        esac
    done
}

# Main entry point
main() {
    parse_args "$@"

    # Normalize prefix to ensure it ends with '-' (unless empty)
    PREFIX=$(normalize_prefix "$PREFIX")

    # Check if skills directory exists
    if [ ! -d "$SKILLS_DIR" ]; then
        print_error "Skills directory not found: $SKILLS_DIR"
        exit 1
    fi

    # Handle --list after all args are parsed and prefix is normalized
    if $LIST_SKILLS; then
        list_skills
        exit 0
    fi

    # Determine which skills to install
    if $INSTALL_ALL; then
        # Compatible with bash 3.x (no mapfile)
        while IFS= read -r skill; do
            SKILLS_TO_INSTALL+=("$skill")
        done < <(get_all_skills)
    fi

    if [ ${#SKILLS_TO_INSTALL[@]} -eq 0 ]; then
        print_error "No skills specified."
        echo ""
        echo "Use --list to see available skills, or --all to install all skills."
        echo "Use --help for more options."
        exit 1
    fi

    # Show configuration
    echo ""
    print_info "Claude Developer Skills Kit Installer"
    echo "========================================"
    echo ""
    echo "Configuration:"
    echo "  Prefix:      ${PREFIX:-<none>}"
    echo "  Install to:  $INSTALL_MODE"
    echo "  Dry run:     $DRY_RUN"
    echo ""

    # Run installation
    do_install "${SKILLS_TO_INSTALL[@]}"
}

main "$@"
