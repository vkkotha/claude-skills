#!/usr/bin/env bash

# Claude Developer Skills Kit (cdskit) Uninstaller
#
# Usage:
#   ./uninstall.sh [OPTIONS] [SKILL_NAMES...]
#
# Options:
#   --list              List installed skills
#   --prefix PREFIX     Set skill name prefix (default: cdskit-)
#   --global            Uninstall from ~/.claude/skills/ (default)
#   --local             Uninstall from ./.claude/skills/
#   --all               Uninstall all skills with the given prefix
#   --dry-run           Show what would be uninstalled without uninstalling
#   --yes, -y           Skip confirmation prompt
#   --help              Show this help message
#
# Examples:
#   ./uninstall.sh --list
#   ./uninstall.sh --all
#   ./uninstall.sh bitbucket-pr-reviewer
#   ./uninstall.sh --prefix myteam- --all

set -e

# Default values
DEFAULT_PREFIX="cdskit-"
PREFIX="$DEFAULT_PREFIX"
INSTALL_MODE="global"
DRY_RUN=false
UNINSTALL_ALL=false
SKIP_CONFIRM=false
SKILLS_TO_UNINSTALL=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get the target directory based on install mode
get_target_dir() {
    if [ "$INSTALL_MODE" = "local" ]; then
        echo "./.claude/skills"
    else
        echo "$HOME/.claude/skills"
    fi
}

# Show help
show_help() {
    cat << EOF
Claude Developer Skills Kit (cdskit) Uninstaller

Usage:
  ./uninstall.sh [OPTIONS] [SKILL_NAMES...]

Options:
  --list              List installed skills (with current prefix)
  --prefix PREFIX     Set skill name prefix (default: ${DEFAULT_PREFIX})
  --global            Uninstall from ~/.claude/skills/ (default)
  --local             Uninstall from ./.claude/skills/
  --all               Uninstall all skills with the given prefix
  --dry-run           Show what would be uninstalled without uninstalling
  --yes, -y           Skip confirmation prompt
  --help              Show this help message

Examples:
  ./uninstall.sh --list
  ./uninstall.sh --all
  ./uninstall.sh bitbucket-pr-reviewer mcp-setup
  ./uninstall.sh --prefix myteam- --all
  ./uninstall.sh --local --all
  ./uninstall.sh --yes --all        # Skip confirmation

Skills are identified by their base name (without prefix):
  ./uninstall.sh mcp-setup    # Removes ${DEFAULT_PREFIX}mcp-setup

EOF
}

# List installed skills with the current prefix
list_installed_skills() {
    local target_dir
    target_dir=$(get_target_dir)
    # Display prefix without trailing dash for cleaner output
    local display_prefix="${PREFIX%-}"

    echo ""
    print_info "Installed Skills (prefix: ${display_prefix:-<none>})"
    print_info "Location: $target_dir"
    echo ""

    if [ ! -d "$target_dir" ]; then
        print_warning "Skills directory does not exist: $target_dir"
        return
    fi

    local found=false
    for skill_dir in "$target_dir"/${PREFIX}*/; do
        if [ -d "$skill_dir" ]; then
            found=true
            folder_name=$(basename "$skill_dir")
            # Strip prefix to show base name
            base_name="${folder_name#$PREFIX}"

            # Get description from SKILL.md if it exists
            skill_md="${skill_dir}SKILL.md"
            if [ -f "$skill_md" ]; then
                description=$(grep -m1 "^description:" "$skill_md" 2>/dev/null | sed 's/description: *//' | sed 's/"//g' || echo "No description")
            else
                description="No description"
            fi

            printf "  ${GREEN}%-25s${NC} -> %s\n" "$base_name" "$folder_name"
        fi
    done

    if ! $found; then
        print_warning "No skills found with prefix '${display_prefix:-<none>}'"
    fi

    echo ""
    print_info "Uninstall with: ./uninstall.sh <skill-name>"
    print_info "Uninstall all:  ./uninstall.sh --all"
    echo ""
}

# Get all installed skill names with the current prefix
get_installed_skills() {
    local target_dir
    target_dir=$(get_target_dir)

    if [ ! -d "$target_dir" ]; then
        return
    fi

    for skill_dir in "$target_dir"/${PREFIX}*/; do
        if [ -d "$skill_dir" ]; then
            folder_name=$(basename "$skill_dir")
            # Return base name (without prefix)
            echo "${folder_name#$PREFIX}"
        fi
    done
}

# Get required dependencies for an installed skill
get_skill_dependencies() {
    local skill_name=$1
    local target_dir
    target_dir=$(get_target_dir)
    local skill_json="${target_dir}/${PREFIX}${skill_name}/skill.json"

    if [ -f "$skill_json" ]; then
        # Try jq first, fall back to grep
        if command -v jq >/dev/null 2>&1; then
            jq -r '.dependencies.required // [] | .[]' "$skill_json" 2>/dev/null || true
        else
            # Basic grep fallback - extract required deps
            grep -o '"required"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$skill_json" 2>/dev/null | \
                grep -o '"[^"]*"' | grep -v '"required"' | tr -d '"' || true
        fi
    fi
}

# Find skills that depend on a given skill
find_dependents() {
    local skill_name=$1
    local target_dir
    target_dir=$(get_target_dir)
    local dependents=()

    # Check each installed skill's dependencies
    while IFS= read -r installed_skill; do
        [ -z "$installed_skill" ] && continue
        local deps
        deps=$(get_skill_dependencies "$installed_skill")
        for dep in $deps; do
            if [ "$dep" = "$skill_name" ]; then
                dependents+=("$installed_skill")
                break
            fi
        done
    done < <(get_installed_skills)

    # Output dependents
    for d in "${dependents[@]}"; do
        echo "$d"
    done
}

# Check for dependency conflicts and prompt user
check_dependency_conflicts() {
    local skills=("$@")
    local target_dir
    target_dir=$(get_target_dir)
    local conflicts_found=false
    local affected_skills=()
    local skills_to_add=()

    # Build a map of skills being removed and their dependents
    for skill in "${skills[@]}"; do
        local dependents
        dependents=$(find_dependents "$skill")
        for dep in $dependents; do
            # Check if dependent is NOT already in removal list
            local in_list=false
            for s in "${skills[@]}"; do
                if [ "$s" = "$dep" ]; then
                    in_list=true
                    break
                fi
            done
            if ! $in_list; then
                conflicts_found=true
                affected_skills+=("$dep (depends on $skill)")
                # Track unique skills to potentially add
                local already_added=false
                for a in "${skills_to_add[@]}"; do
                    if [ "$a" = "$dep" ]; then
                        already_added=true
                        break
                    fi
                done
                if ! $already_added; then
                    skills_to_add+=("$dep")
                fi
            fi
        done
    done

    if $conflicts_found; then
        echo ""
        print_warning "Dependency Warning!"
        echo ""
        print_warning "The following installed skills depend on skills you're removing:"
        for affected in "${affected_skills[@]}"; do
            echo -e "  ${YELLOW}• ${PREFIX}${affected}${NC}"
        done
        echo ""

        if ! $SKIP_CONFIRM; then
            echo "Options:"
            echo "  1) Remove dependent skills too (recommended)"
            echo "  2) Continue anyway (dependent skills may not work)"
            echo "  3) Cancel"
            echo ""
            echo -n "Choose [1/2/3]: "
            read -r choice
            case "$choice" in
                1)
                    # Add dependent skills to removal list
                    for s in "${skills_to_add[@]}"; do
                        SKILLS_TO_UNINSTALL+=("$s")
                    done
                    print_info "Added dependent skills to removal list."
                    echo ""
                    ;;
                2)
                    print_warning "Continuing without removing dependent skills."
                    echo ""
                    ;;
                *)
                    print_info "Uninstallation cancelled."
                    exit 0
                    ;;
            esac
        else
            print_warning "Skipping dependency prompt (--yes specified). Dependent skills will remain."
        fi
    fi
}

# Uninstall a single skill
uninstall_skill() {
    local skill_name=$1
    local target_dir
    target_dir=$(get_target_dir)

    local prefixed_name="${PREFIX}${skill_name}"
    local skill_dir="${target_dir}/${prefixed_name}"

    if [ ! -d "$skill_dir" ]; then
        print_warning "Skill not found: $prefixed_name (looked in $skill_dir)"
        return 1
    fi

    if $DRY_RUN; then
        print_info "[DRY RUN] Would remove: $skill_dir"
        return 0
    fi

    print_info "Removing: $prefixed_name"
    rm -rf "$skill_dir"
    print_success "  Removed: $prefixed_name"
}

# Main uninstallation function
do_uninstall() {
    local skills=("$@")
    local target_dir
    target_dir=$(get_target_dir)

    if [ ! -d "$target_dir" ]; then
        print_error "Skills directory does not exist: $target_dir"
        exit 1
    fi

    # Build list of folders to remove with full paths
    echo ""
    print_info "The following folders will be removed:"
    echo ""
    local valid_skills=()
    for skill in "${skills[@]}"; do
        local prefixed_name="${PREFIX}${skill}"
        local skill_dir="${target_dir}/${prefixed_name}"
        if [ -d "$skill_dir" ]; then
            echo -e "  ${RED}$skill_dir${NC}"
            valid_skills+=("$skill")
        else
            print_warning "  Skill not found: $skill_dir (skipping)"
        fi
    done
    echo ""

    # Check if there are any valid skills to uninstall
    if [ ${#valid_skills[@]} -eq 0 ]; then
        print_error "No valid skills found to uninstall."
        exit 1
    fi

    # Skip confirmation for dry-run mode
    if $DRY_RUN; then
        print_warning "Dry run mode - no files will be removed."
        echo ""
        for skill in "${valid_skills[@]}"; do
            local prefixed_name="${PREFIX}${skill}"
            local skill_dir="${target_dir}/${prefixed_name}"
            print_info "[DRY RUN] Would remove: $skill_dir"
        done
        echo ""
        print_warning "Dry run complete. No files were removed."
        return 0
    fi

    # Ask for confirmation unless --yes is specified
    if ! $SKIP_CONFIRM; then
        echo -n "Are you sure you want to remove these ${#valid_skills[@]} skill(s)? [y/N] "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                ;;
            *)
                print_info "Uninstallation cancelled."
                exit 0
                ;;
        esac
        echo ""
    fi

    # Uninstall each skill
    local removed=0
    for skill in "${valid_skills[@]}"; do
        if uninstall_skill "$skill"; then
            ((removed++)) || true
        fi
    done

    echo ""
    print_success "Uninstallation complete! Removed $removed skill(s)."
    echo ""
    print_info "Note: Restart Claude Code to apply changes."
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
                UNINSTALL_ALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes|-y)
                SKIP_CONFIRM=true
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
                SKILLS_TO_UNINSTALL+=("$1")
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

    # Handle --list after all args are parsed and prefix is normalized
    if $LIST_SKILLS; then
        list_installed_skills
        exit 0
    fi

    # Determine which skills to uninstall
    if $UNINSTALL_ALL; then
        # Get all installed skills with the current prefix
        while IFS= read -r skill; do
            [ -n "$skill" ] && SKILLS_TO_UNINSTALL+=("$skill")
        done < <(get_installed_skills)
    fi

    if [ ${#SKILLS_TO_UNINSTALL[@]} -eq 0 ]; then
        print_error "No skills specified."
        echo ""
        echo "Use --list to see installed skills, or --all to uninstall all skills."
        echo "Use --help for more options."
        exit 1
    fi

    # Show configuration
    echo ""
    print_info "Claude Developer Skills Kit Uninstaller"
    echo "=========================================="
    echo ""
    echo "Configuration:"
    echo "  Prefix:        ${PREFIX:-<none>}"
    echo "  Uninstall from: $INSTALL_MODE"
    echo "  Dry run:       $DRY_RUN"

    # Check for dependency conflicts (may add to SKILLS_TO_UNINSTALL)
    check_dependency_conflicts "${SKILLS_TO_UNINSTALL[@]}"

    # Run uninstallation
    do_uninstall "${SKILLS_TO_UNINSTALL[@]}"
}

main "$@"
