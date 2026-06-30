---
name: mcp-setup
description: Set up and configure MCP (Model Context Protocol) servers for AI assistants. Use when configuring MCP servers, editing MCP config files, or troubleshooting MCP server connections.
---

# MCP Configuration Setup

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Setup and configure MCP (Model Context Protocol) servers for AI assistants
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL MCP server setup:**
- Configuring local MCP servers for Claude Code
- Setting up access tokens for external services (Notion, Figma, etc.)
- Managing MCP server configurations
- Troubleshooting MCP connections
- Adding new MCP servers to your environment

---

## 🏗️ MCP Architecture

### What are MCP Servers?

MCP (Model Context Protocol) servers enable AI assistants to:
- Access external services (Notion, Figma, GitHub, etc.)
- Query databases and APIs
- Perform actions on behalf of users
- Extend AI capabilities beyond base functionality

### MCP Server Types

**1. Database MCPs**
- **PostgreSQL:** Query relational databases
- **MySQL:** Access MySQL databases
- **MongoDB:** NoSQL document operations
- **Redis:** Key-value cache operations

**2. Service Integration MCPs**
- **Notion:** Document management, wikis
- **Figma:** Design system collaboration
- **GitHub:** Repository management, PRs, issues
- **Slack:** Team communication
- **Jira:** Project management

**3. Data Processing MCPs**
- **Morpheus:** Knowledge graph queries
- **data-proxy:** Secure database/API access
- **graphify:** Visualize data structures

---

## 📝 Quick Setup

### Step 1: Install MCP Servers

```bash
# Navigate to MCP directory
cd ~/.claude/mcp

# Install MCP servers
npm install @modelcontextprotocol/server-postgres
npm install @modelcontextprotocol/server-notion
npm install @modelcontextprotocol/server-figma
npm install @modelcontextprotocol/server-github
npm install @modelcontextprotocol/server-slack
```

### Step 2: Configure Environment Variables

Create `.env` file in `~/.claude/`:

```bash
# Create environment file
cat > ~/.claude/.env << 'EOF'
# Notion Integration
NOTION_API_KEY=your_notion_integration_token_here
NOTION_DATABASE_ID=your_database_id_here

# Figma Integration
FIGMA_ACCESS_TOKEN=your_figma_access_token_here
FIGMA_FILE_KEY=your_file_key_here

# GitHub Integration
GITHUB_TOKEN=your_github_personal_access_token_here
GITHUB_REPOSITORY=owner/repo

# Slack Integration
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_CHANNEL_ID=your-channel-id

# Database Connections
POSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/dbname
MONGODB_CONNECTION_STRING=mongodb://localhost:27017/dbname
REDIS_URL=redis://localhost:6379

# Custom MCP Servers
MORPHEUS_ENDPOINT=http://localhost:3000
DATA_PROXY_ENDPOINT=http://localhost:3001
EOF

# Set proper permissions
chmod 600 ~/.claude/.env
```

### Step 3: Update Claude Config

Edit `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-notion"],
      "env": {
        "NOTION_API_KEY": "${NOTION_API_KEY}",
        "NOTION_DATABASE_ID": "${NOTION_DATABASE_ID}"
      }
    },
    "figma": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-figma"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "${FIGMA_ACCESS_TOKEN}",
        "FIGMA_FILE_KEY": "${FIGMA_FILE_KEY}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "slack": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
        "SLACK_CHANNEL_ID": "${SLACK_CHANNEL_ID}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"
      }
    }
  }
}
```

---

## 🔧 Service-Specific Setup

### Notion MCP

**Purpose:** Access and manage Notion documents, databases, and wikis

**Setup:**

1. **Create Notion Integration**
   - Go to https://www.notion.so/my-integrations
   - Click "New integration"
   - Give it a name (e.g., "AI Assistant")
   - Select workspace
   - Copy "Integration Token" (Internal Integration Secret)

2. **Share Database with Integration**
   - Open your Notion database
   - Click "..." → "Add connections"
   - Select your integration
   - Copy database ID from URL: `https://notion.so/database/{DATABASE_ID}?v=...`

3. **Configure Environment**
   ```bash
   export NOTION_API_KEY="your_integration_token"
   export NOTION_DATABASE_ID="your_database_id"
   ```

**Usage Examples:**
```bash
# AI can now:
- Query Notion databases for PRD requirements
- Create design documents in Notion
- Update project tracking databases
- Search across all Notion pages
```

---

### Figma MCP

**Purpose:** Access design systems, components, and collaborate on designs

**Setup:**

1. **Create Figma Access Token**
   - Go to https://www.figma.com/settings
   - Scroll to "Personal Access Tokens"
   - Click "Create new token"
   - Give it a name (e.g., "AI Assistant")
   - Copy the token

2. **Get File Key**
   - Open your Figma file
   - Copy file ID from URL: `https://figma.com/file/{FILE_KEY}/...`

3. **Configure Environment**
   ```bash
   export FIGMA_ACCESS_TOKEN="your_figma_token"
   export FIGMA_FILE_KEY="your_file_key"
   ```

**Usage Examples:**
```bash
# AI can now:
- Access design system components
- Read design specifications
- Generate code from Figma designs
- Create design documentation
```

---

### GitHub MCP

**Purpose:** Manage repositories, PRs, issues, and workflows

**Setup:**

1. **Create GitHub Personal Access Token**
   - Go to https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"
   - Select scopes:
     - `repo` (Full control of private repositories)
     - `workflow` (Update GitHub Action workflows)
     - `read:org` (Read org and team membership)
   - Copy token

2. **Configure Environment**
   ```bash
   export GITHUB_TOKEN="your_github_token"
   export GITHUB_REPOSITORY="owner/repo"
   ```

**Usage Examples:**
```bash
# AI can now:
- Create and manage PRs
- Update issues and project boards
- Trigger CI/CD workflows
- Analyze code across repositories
```

---

### Slack MCP

**Purpose:** Send notifications, update channels, manage team communication

**Setup:**

1. **Create Slack App**
   - Go to https://api.slack.com/apps
   - Click "Create New App"
   - Select "From scratch"
   - Give it a name and select workspace

2. **Configure Bot Permissions**
   - Go to "OAuth & Permissions"
   - Add scopes:
     - `chat:write` (Send messages)
     - `channels:read` (View channels)
     - `channels:history` (Read messages)
   - Install app to workspace
   - Copy "Bot User OAuth Token"

3. **Get Channel ID**
   - Right-click channel → "Copy Link" → Extract ID from URL
   - Or use Slack API: `slack.conversations.list`

4. **Configure Environment**
   ```bash
   export SLACK_BOT_TOKEN="xoxb-your-bot-token"
   export SLACK_CHANNEL_ID="C1234567890"
   ```

**Usage Examples:**
```bash
# AI can now:
- Send deployment notifications
- Update team on progress
- Alert on errors or failures
- Create daily standup summaries
```

---

### Database MCPs

**PostgreSQL MCP**

**Setup:**
```bash
# Install
npm install @modelcontextprotocol/server-postgres

# Configure
export POSTGRES_CONNECTION_STRING="postgresql://user:password@localhost:5432/dbname"

# Update settings.json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "${POSTGRES_CONNECTION_STRING}"
      }
    }
  }
}
```

**Usage:**
```bash
# AI can now:
- Query database schemas
- Execute SQL queries
- Analyze data patterns
- Generate reports from database
```

**MongoDB MCP**
```bash
export MONGODB_CONNECTION_STRING="mongodb://localhost:27017/dbname"
```

**Redis MCP**
```bash
export REDIS_URL="redis://localhost:6379"
```

---

## 🔐 Security Best Practices

### 1. Never Commit Access Tokens

**Add to `.gitignore`:**
```bash
# .gitignore
.env
.env.local
.env.*.local
*.pem
*.key
credentials.json
```

**Use `.env.example`:**
```bash
# .env.example
NOTION_API_KEY=your_notion_integration_token_here
FIGMA_ACCESS_TOKEN=your_figma_access_token_here
GITHUB_TOKEN=your_github_token_here
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
POSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/dbname
```

### 2. File Permissions

```bash
# Restrict .env file to owner only
chmod 600 ~/.claude/.env

# Verify permissions
ls -la ~/.claude/.env
# Should show: -rw------- (600)
```

### 3. Token Rotation

**Rotate tokens regularly:**
- GitHub tokens: Every 90 days
- Slack tokens: Every year
- Notion tokens: Rotate if compromised
- Figma tokens: Rotate if compromised

### 4. Use Environment-Specific Tokens

**Development:**
```bash
# .env.development
GITHUB_TOKEN=ghp_dev_token_with_limited_scope
```

**Production:**
```bash
# .env.production
GITHUB_TOKEN=ghp_prod_token_with_full_scope
```

---

## 🧪 Testing MCP Connections

### Test Notion Connection

```bash
# Using curl
curl -X GET https://api.notion.com/v1/users/me \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"

# Expected output: User object with name and email
```

### Test Figma Connection

```bash
# Using curl
curl -X GET "https://api.figma.com/v1/files/$FIGMA_FILE_KEY" \
  -H "X-Figma-Token: $FIGMA_ACCESS_TOKEN"

# Expected output: File object with name and lastModified
```

### Test GitHub Connection

```bash
# Using gh CLI
gh auth status

# Expected output: Logged in as username
```

### Test Slack Connection

```bash
# Using curl
curl -X POST "https://slack.com/api/auth.test" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN"

# Expected output: {"ok": true, "url": "..."}
```

---

## 🚀 Automated Setup Script

Create `setup-mcp.sh`:

```bash
#!/bin/bash

set -e

echo "🚀 Setting up MCP servers..."

# Create .env file if it doesn't exist
if [ ! -f ~/.claude/.env ]; then
  echo "📝 Creating .env file..."
  cat > ~/.claude/.env << 'EOF'
# Notion Integration
NOTION_API_KEY=
NOTION_DATABASE_ID=

# Figma Integration
FIGMA_ACCESS_TOKEN=
FIGMA_FILE_KEY=

# GitHub Integration
GITHUB_TOKEN=
GITHUB_REPOSITORY=

# Slack Integration
SLACK_BOT_TOKEN=
SLACK_CHANNEL_ID=

# Database Connections
POSTGRES_CONNECTION_STRING=
MONGODB_CONNECTION_STRING=
REDIS_URL=
EOF
  chmod 600 ~/.claude/.env
  echo "✅ Created ~/.claude/.env"
fi

# Prompt for tokens
echo "🔑 Enter your API tokens (leave blank to skip):"

read -p "Notion API Key: " notion_key
read -p "Notion Database ID: " notion_db
read -p "Figma Access Token: " figma_token
read -p "Figma File Key: " figma_key
read -p "GitHub Token: " github_token
read -p "Slack Bot Token: " slack_token

# Update .env file
if [ -n "$notion_key" ]; then
  sed -i.bak "s/NOTION_API_KEY=.*/NOTION_API_KEY=$notion_key/" ~/.claude/.env
fi

if [ -n "$notion_db" ]; then
  sed -i.bak "s/NOTION_DATABASE_ID=.*/NOTION_DATABASE_ID=$notion_db/" ~/.claude/.env
fi

if [ -n "$figma_token" ]; then
  sed -i.bak "s/FIGMA_ACCESS_TOKEN=.*/FIGMA_ACCESS_TOKEN=$figma_token/" ~/.claude/.env
fi

if [ -n "$figma_key" ]; then
  sed -i.bak "s/FIGMA_FILE_KEY=.*/FIGMA_FILE_KEY=$figma_key/" ~/.claude/.env
fi

if [ -n "$github_token" ]; then
  sed -i.bak "s/GITHUB_TOKEN=.*/GITHUB_TOKEN=$github_token/" ~/.claude/.env
fi

if [ -n "$slack_token" ]; then
  sed -i.bak "s/SLACK_BOT_TOKEN=.*/SLACK_BOT_TOKEN=$slack_token/" ~/.claude/.env
fi

echo "✅ MCP setup complete!"
echo "📝 Edit ~/.claude/.env to add more tokens"
echo "🔄 Restart Claude Code to load MCP servers"
```

**Usage:**
```bash
chmod +x setup-mcp.sh
./setup-mcp.sh
```

---

## 📊 MCP Server Directory

**Available MCP Servers:**

| MCP Server | Purpose | Installation |
|------------|---------|--------------|
| **@modelcontextprotocol/server-notion** | Document management | `npm install @modelcontextprotocol/server-notion` |
| **@modelcontextprotocol/server-figma** | Design collaboration | `npm install @modelcontextprotocol/server-figma` |
| **@modelcontextprotocol/server-github** | Repository management | `npm install @modelcontextprotocol/server-github` |
| **@modelcontextprotocol/server-slack** | Team communication | `npm install @modelcontextprotocol/server-slack` |
| **@modelcontextprotocol/server-postgres** | PostgreSQL database | `npm install @modelcontextprotocol/server-postgres` |
| **@modelcontextprotocol/server-mysql** | MySQL database | `npm install @modelcontextprotocol/server-mysql` |
| **@modelcontextprotocol/server-mongodb** | MongoDB database | `npm install @modelcontextprotocol/server-mongodb` |
| **@modelcontextprotocol/server-redis** | Redis cache | `npm install @modelcontextprotocol/server-redis` |
| **morpheus-mcp** | Knowledge graph queries | `npm install morpheus-mcp` |
| **data-proxy-mcp** | Secure data access | `npm install data-proxy-mcp` |

---

## 🔍 Troubleshooting

### Issue: MCP Server Not Starting

**Solution:**
```bash
# Check if MCP server is installed
npm list -g @modelcontextprotocol/server-notion

# Reinstall if missing
npm install -g @modelcontextprotocol/server-notion

# Check Claude settings
cat ~/.claude/settings.json | grep -A 10 "mcpServers"
```

### Issue: Authentication Failed

**Solution:**
```bash
# Verify token is set
echo $NOTION_API_KEY

# Test token manually
curl -X GET https://api.notion.com/v1/users/me \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"
```

### Issue: Environment Variables Not Loading

**Solution:**
```bash
# Verify .env file exists
ls -la ~/.claude/.env

# Check file permissions
chmod 600 ~/.claude/.env

# Restart Claude Code
# Environment variables are loaded at startup
```

---

## 📚 Related Skills

- **DeJoule Knowledge Base** - Organizational context
- **Superpowers Brainstorming** - AI-powered planning
- **TDD Workflow** - Test-driven development
- **QA Automation** - Test generation from KB

---

## ✅ Setup Checklist

Before using MCP servers:
- [ ] .env file created in ~/.claude/
- [ ] Access tokens configured in .env
- [ ] File permissions set to 600
- [ ] Claude settings.json updated with MCP servers
- [ ] MCP servers installed via npm
- [ ] Connections tested successfully
- [ ] Claude Code restarted to load MCP servers

---

**This MCP setup enables AI assistants to access external services, databases, and APIs with proper authentication and security.** 🚀
