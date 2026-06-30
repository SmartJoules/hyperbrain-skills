---
name: mcp-installer
description: One-command installation of all MCP servers from the HyperBrain repository. Use when the user wants to install, set up, or configure the HyperBrain MCP servers for their AI assistant.
---

# MCP Installer - Automated MCP Server Setup

**Part of HyperBrain Skills Library**

**Purpose:** One-command installation of all MCP servers from the HyperBrain repository

**Version:** 1.0.0
**Last Updated:** 2026-05-04

---

## 🎯 Overview

The MCP Installer automates the setup of all Model Context Protocol (MCP) servers defined in the HyperBrain Skills Library, eliminating manual configuration and ensuring consistent setups across all environments.

### Key Benefits

✅ **One-Command Setup** - Install all MCP servers with a single command  
✅ **Automatic Detection** - Discovers all MCP configurations in the repository  
✅ **Dependency Resolution** - Installs required packages automatically  
✅ **Configuration Management** - Handles all Claude settings  
✅ **Validation** - Verifies each MCP server after installation  
✅ **Rollback Support** - Easy uninstallation if needed  
✅ **Cross-Platform** - Works on macOS, Linux, Windows (WSL)

---

## 🚀 Quick Start

### Basic Usage

```bash
# Navigate to HyperBrain skills directory
cd ~/.claude/skills/hyperbrain-skills

# Install all MCP servers
/mcp-installer install

# Or with specific options
/mcp-installer install --include "morpheus,data-proxy"

# Install with auto-confirmation
/mcp-installer install --yes
```

### Verify Installation

```bash
# Check installed MCP servers
/mcp-installer status

# Test each MCP server
/mcp-installer test

# View configuration
/mcp-installer list
```

---

## 📚 Available MCP Servers

### Always-On MCPs (3 servers)

| MCP Server | Purpose | Type | Status |
|------------|---------|------|--------|
| **Notion** | Documentation integration | HTTP | ✅ Always On |
| **GitHub** | Repository operations | HTTP | ✅ Always On |
| **Slack** | Team communication | HTTP | ✅ Always On |

### On-Demand MCPs (4 servers)

| MCP Server | Purpose | Type | Trigger Keywords |
|------------|---------|------|------------------|
| **Morpheus** | Knowledge graph & codebase search | HTTP | "Use Morpheus", "Query knowledge graph" |
| **Data Proxy** | Database queries (PostgreSQL, InfluxDB, Redis) | SSE | "Use data-proxy", "Query database" |
| **Figma Console** | Design integration | CLI | "Use Figma", "Get Figma design" |
| **Sentinel** | Error tracking & monitoring | CLI | "Use Sentinel", "Check health" |

---

## 🔧 How It Works

### Installation Pipeline

1. **Discovery** - Scan repository for MCP configuration files
2. **Validation** - Check each MCP configuration for correctness
3. **Dependency Check** - Verify required tools (Node.js, Python, etc.)
4. **Package Installation** - Install npm packages, Python packages, etc.
5. **Configuration** - Update Claude settings.json with MCP servers
6. **Environment Setup** - Set up required environment variables
7. **Verification** - Test each MCP server connection
8. **Reporting** - Provide installation summary and next steps

### Configuration Files

The installer processes these configuration files:

```
hyperbrain-skills/
├── mcp-setup/
│   ├── mcp-config.json           # Always-on MCPs
│   └── install.sh                # Installation script
└── mcp-on-demand/
    └── mcp-config.json           # On-demand MCPs
```

---

## 💡 Usage Examples

### Example 1: Install All MCPs (Interactive)

```bash
# Navigate to HyperBrain skills
cd ~/.claude/skills/hyperbrain-skills

# Install everything (interactive mode)
/mcp-installer install

# Output:
# ╔════════════════════════════════════════════════════════════╗
# ║           MCP Installer - HyperBrain Skills              ║
# ║     Automated MCP Server Setup for Claude Code           ║
# ╚════════════════════════════════════════════════════════════╝
#
# 🔍 Discovering MCP configurations...
# ✅ Found 7 MCP servers
#
# ═════════════════════════════════════════════════════════════
# 📦 Found MCP: notion
# ═════════════════════════════════════════════════════════════
#
# Description:   Notion documentation integration
# Type:          http
# Required:      true
# Category:      always-on
#
# 📋 This MCP requires:
#   • NOTION_API_KEY (required)
#   • Notion integration token from https://www.notion.so/my-integrations
#
# ⚠️  This is an always-on MCP and will start automatically with Claude Code.
#
# Install and configure notion? [Y/n]: Y
#
# ═════════════════════════════════════════════════════════════
# 🔧 Configuring: notion
# ═════════════════════════════════════════════════════════════
#
# Description: Notion documentation integration
# Type: http
#
# ✅ Existing configuration found:
#    NOTION_API_KEY=****
# Use existing configuration? [Y/n]: n
#
# Required for Notion MCP:
# 1. NOTION_API_KEY - Notion integration token
# 2. NOTION_DATABASE_ID (optional) - Default database ID
#
# Get your token: https://www.notion.so/my-integrations
#
# Enter NOTION_API_KEY (or press Enter to skip): [your-token-here]
# ✅ NOTION_API_KEY configured
#
# Enter NOTION_DATABASE_ID (optional, press Enter to skip):
#
# ✅ Configuration complete for notion
#
# ... (continues for each MCP)
#
# 📦 Installing npm-based MCP packages...
# ✅ @modelcontextprotocol/server-notion installed
# ✅ @modelcontextprotocol/server-github installed
# ✅ @modelcontextprotocol/server-slack installed
#
# 🔧 Updating Claude settings...
# ✅ Claude settings updated
#
# 📝 Creating environment file...
# ✅ Environment file created: .env.mcp
# ✅ Environment example created: .env.mcp.example
#
# ℹ️  Next steps:
#
# 1. Load environment variables:
#    source .env.mcp
#
#    Or add to your shell profile (~/.bashrc or ~/.zshrc):
#    echo 'source .env.mcp' >> ~/.zshrc
#
# 2. Restart Claude Code
#
# 3. Test MCP servers:
#    ./mcp-installer/bin/install-mcps.sh test
#
# 4. Use MCPs in conversations:
#    - Use Morpheus to query knowledge graphs
#    - Use data-proxy to query databases
#    - Get Figma designs
#    - Check system health with Sentinel
#
# ✅ Configured with 3 environment variable(s):
#    - NOTION_API_KEY
#    - GITHUB_TOKEN
#    - SLACK_TOKEN
#
# ✅ Installation complete!
```

### Example 2: Install Specific MCPs

```bash
# Install only always-on MCPs
/mcp-installer install --type always-on

# Install only on-demand MCPs
/mcp-installer install --type on-demand

# Install specific MCPs
/mcp-installer install --include "morpheus,data-proxy"

# Exclude specific MCPs
/mcp-installer install --exclude "sentinel,figma-console"
```

### Example 3: Install with Custom Settings

```bash
# Install to custom Claude settings location
/mcp-installer install --claude-settings ~/.claude/settings.json

# Install with verbose output
/mcp-installer install --verbose

# Install without confirmation prompts
/mcp-installer install --yes

# Install with dry-run (show what would be installed)
/mcp-installer install --dry-run
```

### Example 4: Check Installation Status

```bash
# Show installation status
/mcp-installer status

# Output:
# 📊 MCP Installation Status
#
# ✅ Notion MCP (always-on)
#    Status: Installed and running
#    Config: ~/.claude/settings.json
#
# ✅ GitHub MCP (always-on)
#    Status: Installed and running
#    Config: ~/.claude/settings.json
#
# ✅ Slack MCP (always-on)
#    Status: Installed and running
#    Config: ~/.claude/settings.json
#
# ✅ Morpheus MCP (on-demand)
#    Status: Installed, ready to activate
#    Trigger: "Use Morpheus"
#
# ⚠️  Data Proxy MCP (on-demand)
#    Status: Installed, requires VPN
#    Trigger: "Use data-proxy"
#
# ❌ Figma Console MCP (on-demand)
#    Status: Missing FIGMA_ACCESS_TOKEN
#    Action: Set environment variable
#
# ⚠️  Sentinel MCP (on-demand)
#    Status: Installed, requires SENTRY_AUTH_TOKEN
#    Trigger: "Use Sentinel"
```

---

## 🔧 Configuration

### Interactive Confirmation

The installer will **prompt you for each MCP server** before installation:

```bash
# For each MCP, you'll see:
════════════════════════════════════════════════════════════
📦 Found MCP: notion
════════════════════════════════════════════════════════════

Description:   Notion documentation integration
Type:          http
Required:      true
Category:      always-on

📋 This MCP requires:
  • NOTION_API_KEY (required)
  • Notion integration token from https://www.notion.so/my-integrations

Install and configure notion? [Y/n]:
```

### Providing Credentials

When you confirm, you'll be asked for required credentials:

```bash
════════════════════════════════════════════════════════════
🔧 Configuring: notion
════════════════════════════════════════════════════════════

Required for Notion MCP:
1. NOTION_API_KEY - Notion integration token
2. NOTION_DATABASE_ID (optional) - Default database ID

Get your token: https://www.notion.so/my-integrations

Enter NOTION_API_KEY (or press Enter to skip): [paste your token]
✅ NOTION_API_KEY configured

Enter NOTION_DATABASE_ID (optional, press Enter to skip):
```

### CLI Options

```bash
/mcp-installer install [OPTIONS]

Options:
  --type TYPE              MCP type to install [always-on|on-demand|all] [default: all]
  --include SERVERS        Comma-separated list of MCPs to include
  --exclude SERVERS        Comma-separated list of MCPs to exclude
  --claude-settings PATH   Custom Claude settings file path [default: ~/.claude/settings.json]
  --python-path PATH       Custom Python executable path [default: python3]
  --node-path PATH         Custom Node.js executable path [default: node]
  --yes                    Skip prompts and install all (requires pre-configured env vars)
  --dry-run                Show what would be installed without installing
  --verbose                Verbose output
  --force                  Reinstall even if already installed
  --help                   Show help message
```

### Environment Variables

```bash
# Claude settings location
export CLAUDE_SETTINGS_PATH="$HOME/.claude/settings.json"

# Python executable for MCP servers
export PYTHON_MCP_EXECUTABLE="python3"

# Node.js executable for MCP servers
export NODE_MCP_EXECUTABLE="node"

# Installation directory for MCP packages
export MCP_INSTALL_DIR="$HOME/.claude/mcp-servers"
```

---

## 📦 Installation Process

### Step 1: Prerequisites Check

```bash
# The installer automatically checks for:
- Node.js (v18 or higher)
- Python (v3.8 or higher)
- npm or yarn or pnpm
- pip (Python package manager)
- Claude Code installation
- Claude settings directory
```

### Step 2: Dependency Installation

```bash
# Node.js-based MCPs
npm install -g @modelcontextprotocol/server-notion
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-slack

# Python-based MCPs (if any)
pip install mcp-server-postgres
pip install mcp-server-influxdb

# Custom MCPs from repository
npx -y mcp-remote http://10.40.21.254:8100/sse --allow-http
npx -y figma-console-mcp
```

### Step 3: Configuration Updates

The installer updates `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "notion": {
      "url": "https://notion-mcp.example.com/sse",
      "type": "http",
      "disabled": false,
      "required": true
    },
    "github": {
      "url": "https://github-mcp.example.com/sse",
      "type": "http",
      "disabled": false,
      "required": true
    },
    "slack": {
      "url": "https://slack-mcp.example.com/sse",
      "type": "http",
      "disabled": false,
      "required": true
    },
    "morpheus": {
      "url": "https://cody.smartjoules.org/sse",
      "type": "http",
      "disabled": false,
      "required": false,
      "autoApprove": ["mcp__morpheus__*"]
    },
    "data-proxy": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://10.40.21.254:8100/sse", "--allow-http"],
      "disabled": false,
      "required": false
    },
    "figma-console": {
      "command": "npx",
      "args": ["figma-console-mcp"],
      "disabled": false,
      "required": false,
      "env": {
        "FIGMAPATH_ACCESS_TOKEN": "${FIGMAPATH_ACCESS_TOKEN}"
      }
    },
    "sentinel": {
      "command": "node",
      "args": ["/path/to/sentry-server.js"],
      "disabled": false,
      "required": false,
      "env": {
        "SENTRY_DSN": "${SENTRY_DSN}",
        "SENTRY_AUTH_TOKEN": "${SENTRY_AUTH_TOKEN}"
      }
    }
  }
}
```

### Step 4: Environment Setup

The installer creates `.env.example` file:

```bash
# MCP Server Environment Variables
# Copy this file to .env and fill in your values

# Notion MCP
NOTION_API_KEY=your_notion_integration_token_here
NOTION_DATABASE_ID=your_database_id_here

# GitHub MCP
GITHUB_TOKEN=your_github_personal_access_token_here

# Slack MCP
SLACK_TOKEN=your_slack_bot_token_here
SLACKSigningSecret=your_slack_signing_secret_here

# Figma Console MCP
FIGMAPATH_ACCESS_TOKEN=your_figma_access_token_here

# Sentinel MCP (Sentry)
SENTRY_DSN=your_sentry_dsn_here
SENTRY_AUTH_TOKEN=your_sentry_auth_token_here
SENTRY_ORG=your_organization
SENTRY_PROJECT=your_project_id
SENTRY_ENDPOINT=https://sentry.example.com
```

---

## 🧪 Testing and Verification

### Test All MCPs

```bash
# Test all installed MCP servers
/mcp-installer test

# Output:
# 🧪 Testing MCP Servers...
#
# ✅ Notion MCP: Connected
#    Latency: 45ms
#    Capabilities: databases, pages, search
#
# ✅ GitHub MCP: Connected
#    Latency: 120ms
#    Capabilities: repositories, issues, pull_requests
#
# ✅ Slack MCP: Connected
#    Latency: 89ms
#    Capabilities: channels, messages, users
#
# ✅ Morpheus MCP: Connected
#    Latency: 230ms
#    Capabilities: query_graph, search_codebase, read_file
#
# ✅ Data Proxy MCP: Connected
#    Latency: 15ms (local network)
#    Capabilities: execute_postgresql_query, execute_influxdb_query
#
# ❌ Figma Console MCP: Not connected
#    Error: Missing FIGMAPATH_ACCESS_TOKEN
#    Action: Set environment variable
#
# ⚠️  Sentinel MCP: Partial connection
#    Warning: Missing SENTRY_AUTH_TOKEN
#    Action: Set environment variable for full functionality
```

### Test Specific MCP

```bash
# Test specific MCP server
/mcp-installer test morpheus

# Test with verbose output
/mcp-installer test --verbose

# Test and show connection details
/mcp-installer test --show-details
```

---

## 🔄 Updating and Uninstalling

### Update MCP Servers

```bash
# Update all MCP servers to latest versions
/mcp-installer update

# Update specific MCP servers
/mcp-installer update --include "morpheus,data-proxy"

# Update with force reinstall
/mcp-installer update --force
```

### Uninstall MCP Servers

```bash
# Uninstall all MCP servers
/mcp-installer uninstall

# Uninstall specific MCP servers
/mcp-installer uninstall --include "sentinel,figma-console"

# Uninstall but keep configuration
/mcp-installer uninstall --keep-config

# Uninstall with confirmation
/mcp-installer uninstall --yes
```

### Rollback Installation

```bash
# Rollback to previous configuration
/mcp-installer rollback

# Rollback specific MCP
/mcp-installer rollback --include "morpheus"

# Show rollback history
/mcp-installer rollback --list
```

---

## 🔍 Troubleshooting & Automatic Error Handling

### Automatic Error Detection and Fixes

The installer includes **intelligent error detection and automatic fixes** for common issues:

#### 1. Missing Node.js

```bash
❌ Node.js not found
🔧 Fixing: Node.js not installed

Detected macOS. Recommending Homebrew installation...
To install Node.js on macOS:
  1. Install Homebrew (if not installed)
  2. Install Node.js: brew install node

Attempt automatic Homebrew installation? [y/N]: y
✅ Node.js installed successfully
```

#### 2. Node.js Version Too Old

```bash
❌ Node.js version 16 is too old (need 18+)
🔧 Fixing: Node.js version too old
ℹ️  nvm detected. Upgrading Node.js...
✅ Upgraded to Node.js 18.17.0
```

#### 3. Permission Denied

```bash
❌ Permission denied for: npm install
🔧 Fixing: Permission denied
ℹ️  npm permission error. Attempting fixes...

Try installing with sudo? [y/N]: y
🔄 Retrying: Running npm install with sudo...
✅ Package installed successfully

# OR alternative fix:
🔧 Fixing: Permission denied
ℹ️  Alternative: Fix npm permissions to avoid sudo
Apply this fix now? [y/N]: y
✅ npm permissions fixed
```

#### 4. Network Errors

```bash
❌ Network error: Connection timeout
🔧 Fixing: Network connectivity issue
ℹ️  Checking network connectivity...
✅ Internet connectivity OK
ℹ️  Proxy detected: http_proxy=http://proxy.example.com:8080
Configure npm proxy now? [y/N]: y
✅ npm proxy configured
🔄 Retrying: Installing package...
✅ Package installed successfully
```

#### 5. Invalid Configuration JSON

```bash
❌ Configuration validation failed: Invalid JSON in settings.json
🔧 Fixing: Configuration validation issue
ℹ️  Attempting to fix JSON syntax...
✅ JSON syntax fixed
```

#### 6. Retry Mechanism

Failed operations are **automatically retried** with exponential backoff:

```bash
📦 Installing @modelcontextprotocol/server-notion...
❌ Attempt 1/3 failed. Retrying in 1s...
🔄 Retrying: Attempt 2/3...
❌ Attempt 2/3 failed. Retrying in 2s...
🔄 Retrying: Attempt 3/3...
✅ Installation successful
```

### Error Summary

At the end of installation, you'll see a comprehensive error summary:

```bash
════════════════════════════════════════════════════════════
📊 Installation Summary
════════════════════════════════════════════════════════════

⚠️  Encountered 3 error(s):

  • [NODE_VERSION_OLD] Node.js version 16 is too old
  • [JQ_NOT_FOUND] jq not found (optional but recommended)
  • [PERMISSION_DENIED] Permission denied for npm install

✅ Fixed 3 error(s):

  ✅ NODE_VERSION_OLD
  ✅ JQ_NOT_FOUND
  ✅ PERMISSION_DENIED

✅ All errors were automatically fixed!
```

### Manual Fixes

If automatic fixes don't work, try these manual solutions:

### Issue: "Claude settings not found"

```bash
# Solution: Specify custom settings path
./mcp-installer/bin/install-mcps.sh install --claude-settings ~/custom-location/settings.json

# Or create default settings
mkdir -p ~/.claude
echo '{}' > ~/.claude/settings.json
```

### Issue: "Node.js not found" (Manual Install)

```bash
# Solution: Install Node.js manually
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc  # or source ~/.zshrc
nvm install 18
nvm use 18

# Or using Homebrew (macOS)
brew install node

# Verify installation
node --version
npm --version
```

### Issue: "Python not found"

```bash
# Solution: Install Python
# macOS
brew install python@3.11

# Linux (Ubuntu/Debian)
sudo apt-get install python3.11 python3-pip

# Verify installation
python3 --version
pip3 --version
```

### Issue: "jq not found" (Optional but Recommended)

```bash
# macOS
brew install jq

# Linux (Ubuntu/Debian)
sudo apt-get install jq

# Linux (Fedora)
sudo dnf install jq

# Verify installation
jq --version
```

### Issue: "MCP server connection failed"

```bash
# Solution 1: Check network connectivity
ping morpheus.example.com

# Solution 2: Verify environment variables
env | grep -E "(NOTION|GITHUB|SLACK|FIGMA|SENTRY)"

# Solution 3: Test specific MCP
./mcp-installer/bin/install-mcps.sh test morpheus --verbose

# Solution 4: Check firewall/proxy settings
# Ensure MCP server URLs are accessible
```

---

## 📚 Best Practices

### 1. Environment Variable Management

```bash
# Use .env file for sensitive data
cp .env.example .env
nano .env  # Add your API keys

# Load environment variables in shell
echo 'source ~/.claude/mcp-servers/.env' >> ~/.zshrc
source ~/.zshrc
```

### 2. Version Control

```bash
# Commit MCP configuration to repository
git add ~/.claude/settings.json
git commit -m "chore: update MCP server configuration"

# But never commit .env with secrets!
echo ".env" >> .gitignore
```

### 3. Regular Updates

```bash
# Update MCP servers monthly
# Add to crontab
crontab -e
# Add: 0 0 1 * * /mcp-installer update --quiet
```

### 4. Monitoring

```bash
# Regular health checks
/mcp-installer test --cron | mail -s "MCP Health Report" admin@example.com
```

### 5. Backup Configuration

```bash
# Backup before updates
cp ~/.claude/settings.json ~/.claude/settings.json.backup
/mcp-installer update
# If something breaks, restore:
# mv ~/.claude/settings.json.backup ~/.claude/settings.json
```

---

## 🎯 Integration with HyperBrain

### Complementary Skills

1. **mcp-on-demand** - Configuration for on-demand MCPs
2. **mcp-setup** - Always-on MCP configuration
3. **graphify-integration** - Can be used with MCP servers
4. **self-learning** - MCP interactions tracked for learning

### Workflow Example

```bash
# Step 1: Install all MCPs
/mcp-installer install

# Step 2: Set environment variables
cp .env.example .env
nano .env  # Add your keys

# Step 3: Test connections
/mcp-installer test

# Step 4: Restart Claude Code
# Now you can use MCPs in conversations:

# "Use Morpheus to query the backend knowledge graph"
# "Use data-proxy to get all devices for site iah-del"
# "Get Figma design for the dashboard page"
```

---

## 📊 Metrics and Reporting

### Installation Statistics

```bash
# Show installation statistics
/mcp-installer stats

# Output:
# 📊 MCP Installation Statistics
#
# Total MCP Servers: 7
# Always-On: 3
# On-Demand: 4
#
# Installation Status:
# ✅ Installed: 6
# ⚠️  Partial: 1 (Figma Console - missing token)
# ❌ Failed: 0
#
# Storage Usage:
# Node.js MCPs: 245 MB
# Python MCPs: 89 MB
# Config Files: 12 KB
# Total: 334 MB
#
# Last Updated: 2026-05-04 10:30:00
```

### Connection Metrics

```bash
# Show connection performance
/mcp-installer metrics

# Output:
# 📈 MCP Connection Metrics
#
# Average Latency:
# - Notion: 45ms
# - GitHub: 120ms
# - Slack: 89ms
# - Morpheus: 230ms
# - Data Proxy: 15ms
#
# Success Rate (last 24h):
# - Notion: 99.8%
# - GitHub: 100%
# - Slack: 99.5%
# - Morpheus: 97.2%
# - Data Proxy: 100%
#
# Total API Calls: 1,247
# Errors: 8
```

---

## 🚀 Quick Reference Commands

```bash
# Installation
/mcp-installer install                              # Install all MCPs
/mcp-installer install --type always-on            # Install always-on only
/mcp-installer install --include "morpheus"        # Install specific MCPs
/mcp-installer install --yes                       # Auto-confirm

# Status & Testing
/mcp-installer status                               # Show installation status
/mcp-installer list                                 # List all MCPs
/mcp-installer test                                 # Test all MCPs
/mcp-installer test morpheus                        # Test specific MCP

# Updates
/mcp-installer update                               # Update all MCPs
/mcp-installer update --force                       # Force reinstall

# Uninstallation
/mcp-installer uninstall                            # Uninstall all MCPs
/mcp-installer uninstall --keep-config              # Keep config

# Utilities
/mcp-installer stats                                # Show statistics
/mcp-installer metrics                              # Show connection metrics
/mcp-installer backup                               # Backup configuration
/mcp-installer rollback                             # Rollback changes
```

---

## 📞 Support

- **GitHub Issues**: https://github.com/itsatif/hyperbrain-skills/issues
- **Documentation**: ~/.claude/skills/hyperbrain-skills/mcp-installer/
- **MCP Documentation**: https://modelcontextprotocol.io/

---

**MCP Installer: One command to rule all MCP servers!** 🚀
