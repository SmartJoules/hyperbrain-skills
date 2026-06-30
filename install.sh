#!/bin/bash

################################################################################
# AI-SDLC Skills Library Installer
# Author: Atif Salafi <atif8486@gmail.com>
# Purpose: Install AI-SDLC skills for Claude Code or other AI assistants
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}AI-SDLC Skills Library Installer${NC}                            ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Default values
INSTALL_DIR=""              # resolved per-assistant below if not passed via --dir
INSTALL_DIR_EXPLICIT=false  # set true when the user passes --dir
CLONE_DIR="/tmp/hyperbrain-skills.$$"
SKIP_BACKUP=false
ASSISTANT="claude"

# Help function
show_help() {
    echo -e "${GREEN}AI-SDLC Skills Library Installer${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "    $0 [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "    -d, --dir DIR          Installation directory (default: ~/.claude/skills)"
    echo "    -a, --assistant TYPE   Assistant type: claude, pi, codex, cursor, copilot (default: claude)"
    echo "    -s, --skip-backup      Skip backup of existing skills"
    echo "    -h, --help             Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "    # Install for Claude Code (default)"
    echo "    $0"
    echo ""
    echo "    # Install for Cursor"
    echo "    $0 --assistant cursor"
    echo ""
    echo "    # Install to custom directory"
    echo "    $0 --dir ~/my-skills"
    echo ""
    echo "    # Install without backup"
    echo "    $0 --skip-backup"
    echo ""
    echo -e "${YELLOW}Supported Assistants:${NC}"
    echo "    - claude   Claude Code (default)"
    echo "    - pi       Pi coding agent (pi.dev) — same SKILL.md format as Claude"
    echo "    - codex    OpenAI Codex"
    echo "    - cursor   Cursor AI Editor"
    echo "    - copilot  GitHub Copilot"
    echo ""
    echo -e "${YELLOW}Skills Included:${NC}"
    echo "    - AI Superpowers (Brainstorming & Planning)"
    echo "    - Engineering Standards (SOLID, patterns, Kafka/Redis, resilience)"
    echo "    - TDD Workflow"
    echo "    - Angular, React, Vue, Next.js Patterns"
    echo "    - State Management (Redux, Zustand, Pinia, NgRx)"
    echo "    - Node.js, Python, Go Patterns"
    echo "    - Database Patterns (PostgreSQL, InfluxDB, MongoDB, Redis)"
    echo "    - MQTT, Kafka, InfluxDB, IoT Architecture"
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo "    https://github.com/SmartJoules/hyperbrain-skills"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            INSTALL_DIR="$2"
            INSTALL_DIR_EXPLICIT=true
            shift 2
            ;;
        -a|--assistant)
            ASSISTANT="$2"
            shift 2
            ;;
        -s|--skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main installation flow
main() {
    print_header

    # Resolve the install dir per assistant unless the user passed --dir.
    if [ "$INSTALL_DIR_EXPLICIT" = false ]; then
        case "$ASSISTANT" in
            claude)  INSTALL_DIR="$HOME/.claude/skills" ;;
            pi)      INSTALL_DIR="$HOME/.pi/agent/skills" ;;
            cursor)  INSTALL_DIR="$HOME/.cursor/skills" ;;
            copilot) INSTALL_DIR="$HOME/.copilot/skills" ;;
            codex)   INSTALL_DIR="$HOME/.codex/skills" ;;
            *)       INSTALL_DIR="$HOME/.claude/skills" ;;
        esac
    fi
    BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"

    # Check prerequisites
    print_info "Checking prerequisites..."
    if ! command -v git &> /dev/null; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    print_success "Prerequisites check passed"

    # Show installation plan
    echo ""
    print_info "Installation Plan:"
    echo -e "  Assistant: ${GREEN}$ASSISTANT${NC}"
    echo -e "  Install Dir: ${GREEN}$INSTALL_DIR${NC}"
    echo -e "  Backup: ${YELLOW}$([ "$SKIP_BACKUP" = true ] && echo 'Skipping' || echo 'Yes (to '$BACKUP_DIR')')${NC}"
    echo ""

    # Confirm installation
    echo -e "${YELLOW}Continue? [y/N]: ${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 0
    fi

    # Backup existing skills if directory exists
    if [ -d "$INSTALL_DIR" ] && [ "$SKIP_BACKUP" = false ]; then
        print_info "Backing up existing skills..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$INSTALL_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
        print_success "Backup created at $BACKUP_DIR"
    fi

    # Clone repository
    print_info "Cloning AI-SDLC skills library..."
    git clone --depth 1 https://github.com/SmartJoules/hyperbrain-skills.git "$CLONE_DIR"
    print_success "Repository cloned"

    # Create installation directory
    print_info "Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
    print_success "Directory ready"

    # Install skills based on assistant type
    print_info "Installing skills for $ASSISTANT..."

    case "$ASSISTANT" in
        claude|pi)
            # Claude Code AND Pi (pi.dev) use the SAME skill format: each skill is
            # a directory containing SKILL.md with YAML frontmatter (name +
            # description). Claude discovers under ~/.claude/skills/; Pi discovers
            # directories containing SKILL.md under ~/.pi/agent/skills/. So the same
            # per-skill-directory install works for both. Copy the WHOLE directory
            # so supporting files (README.md, examples/, bin/, *.json) come along.
            local count=0
            local commands_dir
            case "$ASSISTANT" in
                pi) commands_dir="$HOME/.pi/agent/commands" ;;
                *)  commands_dir="$HOME/.claude/commands" ;;
            esac
            while IFS= read -r skill_md; do
                local skill_dir
                skill_dir="$(dirname "$skill_md")"
                local skill_name
                skill_name="$(basename "$skill_dir")"
                rm -rf "$INSTALL_DIR/$skill_name"
                cp -r "$skill_dir" "$INSTALL_DIR/$skill_name"
                # If the skill ships a bin/ CLI, put it on ~/.local/bin; if it
                # ships slash commands/, install them to ~/.claude/commands.
                if [ -d "$skill_dir/bin" ]; then
                    mkdir -p "$HOME/.local/bin"
                    cp "$skill_dir"/bin/* "$HOME/.local/bin/" 2>/dev/null || true
                    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
                    print_info "    + CLI -> ~/.local/bin (ensure it's on PATH)"
                fi
                if [ -d "$skill_dir/commands" ]; then
                    mkdir -p "$commands_dir"
                    cp "$skill_dir"/commands/*.md "$commands_dir/" 2>/dev/null || true
                    print_info "    + slash commands -> $commands_dir"
                fi
                print_success "  installed: $skill_name"
                count=$((count + 1))
            done < <(find "$CLONE_DIR" -name SKILL.md -not -path '*/.git/*' | sort)
            print_success "Installed $count skills for $ASSISTANT"
            ;;

        codex|cursor|copilot)
            # Codex/Cursor/Copilot have no SKILL.md auto-registry. They DO read an
            # AGENTS.md from the working directory. So: install skills cleanly
            # per-folder under <dir>/skills/, then generate an AGENTS.md index that
            # points the agent at the relevant skill and bakes in the mandatory
            # engineering standards.
            local skills_root="$INSTALL_DIR/skills"
            mkdir -p "$skills_root"
            local count=0
            while IFS= read -r skill_md; do
                local skill_dir skill_name
                skill_dir="$(dirname "$skill_md")"
                skill_name="$(basename "$skill_dir")"
                rm -rf "$skills_root/$skill_name"
                cp -r "$skill_dir" "$skills_root/$skill_name"
                count=$((count + 1))
            done < <(find "$CLONE_DIR" -name SKILL.md -not -path '*/.git/*' | sort)

            # Generate AGENTS.md from the actual installed skills + their descriptions.
            {
                echo "# AGENTS.md — HyperBrain Skills (Codex / Cursor / Copilot)"
                echo
                echo "**Purpose:** Instructions for generic AI coding agents that do not have a"
                echo "native skill registry. The reusable knowledge lives in \`skills/<name>/SKILL.md\`."
                echo
                echo "## How to use"
                echo
                echo "1. Before any code task, scan the skill list below and **open the \`SKILL.md\`"
                echo "   of the skill(s) matching the task** (e.g. Angular work -> \`jouletrack-angular\`)."
                echo "2. \`engineering-standards\` applies to **every** change — read it once and follow it."
                echo "3. Follow the skill's conventions instead of inventing your own."
                echo
                echo "## Critical Rules (always)"
                echo
                echo "Follow \`skills/engineering-standards/SKILL.md\` on every change:"
                echo "- OOP + SOLID; use the right design pattern (strategy/factory/builder/observer/decorator); DRY, KISS, minimum diff."
                echo "- No memory leaks, no unhandled promises, error handling at every boundary; handle loading/error/empty/partial-data states."
                echo "- Optimize queries, remove N+1, fewer DB calls; caches MUST have an eviction strategy (TTL/LRU/max-size) + invalidation on write."
                echo "- Kafka: heartbeat, explicit offset commit after processing, monitor lag, idempotency, DLQ, graceful shutdown."
                echo "- Redis: singleton/pool (never per-request), retry+backoff, TTL/eviction, graceful degradation, cleanup."
                echo
                echo "## Available Skills (load only when relevant)"
                echo
                for d in "$skills_root"/*/; do
                    [ -f "$d/SKILL.md" ] || continue
                    local nm ds
                    nm="$(basename "$d")"
                    ds="$(sed -n 's/^description: //p' "$d/SKILL.md" | head -1)"
                    echo "- **\`skills/$nm/SKILL.md\`** — ${ds:-$nm}"
                done
            } > "$INSTALL_DIR/AGENTS.md"

            print_success "Installed $count skills + AGENTS.md for $ASSISTANT"
            print_info "  Point your agent at $INSTALL_DIR/AGENTS.md (or copy it to your repo root)"
            ;;

        *)
            # Default: copy all skills
            cp -r "$CLONE_DIR"/* "$INSTALL_DIR/" 2>/dev/null || true
            print_success "Skills installed (generic format)"
            ;;
    esac

    # Create activation script
    print_info "Creating activation helper..."
    create_activation_script
    print_success "Activation helper created"

    # Cleanup
    print_info "Cleaning up..."
    rm -rf "$CLONE_DIR"
    print_success "Cleanup complete"

    # Show success message
    echo ""
    print_header
    print_success "Installation complete!"
    echo ""
    print_info "Next Steps:"
    echo -e "  1. ${GREEN}Restart your AI assistant${NC}"
    echo "  2. Skills will be automatically available"
    echo "  3. Ask any question to activate AI Superpowers brainstorming"
    echo ""
    print_info "Documentation:"
    echo -e "  ${BLUE}https://github.com/SmartJoules/hyperbrain-skills${NC}"
    echo ""
    print_info "Skills installed:"
    list_installed_skills
    echo ""
}

# Create activation helper script
create_activation_script() {
    cat > "$INSTALL_DIR/../activate-skills.sh" << 'EOF'
#!/bin/bash

# AI-SDLC Skills Activation Helper

echo "AI-SDLC Skills Library Status:"
echo "================================"
echo ""

# Check if skills directory exists
if [ -d "$HOME/.claude/skills" ]; then
    echo "✓ Skills directory exists"
    echo ""
    echo "Installed Skills:"
    found=0
    for d in "$HOME/.claude/skills"/*/; do
        [ -f "$d/SKILL.md" ] && { echo "  ✓ $(basename "$d")"; found=1; }
    done
    [ "$found" -eq 0 ] && echo "  No skills found"
else
    echo "✗ Skills directory not found"
    echo "  Run install.sh to install skills"
fi

echo ""
echo "Usage:"
echo "  Just ask your AI assistant any question!"
echo "  The AI Superpowers skill will activate automatically."
echo ""
echo "Examples:"
echo "  - 'Add user authentication to my app'"
echo "  - 'Create a REST API for user management'"
echo "  - 'Build a real-time dashboard with charts'"
echo ""
EOF

    chmod +x "$INSTALL_DIR/../activate-skills.sh"
}

# List installed skills (reads actual installed directories + their descriptions)
list_installed_skills() {
    for d in "$INSTALL_DIR"/*/; do
        [ -f "$d/SKILL.md" ] || continue
        local name desc
        name="$(basename "$d")"
        # Pull the frontmatter description (first sentence) if present.
        desc="$(sed -n 's/^description: //p' "$d/SKILL.md" | head -1 | cut -d. -f1)"
        echo -e "  ${GREEN}✓${NC} ${BLUE}${name}${NC}${desc:+ - ${desc}}"
    done
}

# Run main function
main
