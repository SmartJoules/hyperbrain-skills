---
name: local-kb
description: Generate a local knowledge base for any repository using Graphify to reduce token consumption and provide instant context. Use when you want to precompute and cache a repo's structure so the AI has fast, low-token access to project context.
---

# Local Knowledge Base Generator

**Part of HyperBrain Skills Library**

**Purpose:** Automatically generate local knowledge bases for any repository using Graphify to reduce token consumption and provide instant context

**Version:** 1.0.0  
**Last Updated:** 2026-05-04

---

## 🎯 Overview

The Local KB Generator uses **Graphify** to create compact, queryable knowledge bases for any repository, enabling AI agents to understand your codebase with **71.5x fewer tokens** compared to reading raw files.

### Key Benefits

✅ **Token Efficiency** - 71.5x reduction (95% fewer tokens) vs reading entire codebase  
✅ **Instant Context** - Complete architecture in seconds  
✅ **Auto-Generated** - One command creates entire KB  
✅ **Always Updated** - Git hooks keep KB in sync  
✅ **AI-Optimized** - Structured for agent queries  
✅ **Repository-Agnostic** - Works with any codebase  
✅ **Powered by Graphify** - Production-ready AST extraction

---

## 🚀 Quick Start

### Prerequisites

First, install Graphify (the engine behind Local KB):

```bash
# Install Graphify
pip install graphifyy

# Verify installation
graphify --version
```

### Basic Usage

```bash
# Navigate to your repository
cd ~/workspace/my-project

# Generate local knowledge base using Graphify
/local-kb generate

# Or with specific options
/local-kb generate --include "**/*.ts" --exclude "**/*.spec.ts"

# View the generated KB
cat .hyperbrain-kb/GRAPH_REPORT.md
open .hyperbrain-kb/graph.html
```

### Query the Knowledge Base

```bash
# Ask questions about the codebase
graphify query "What is the project architecture?"
graphify query "List all API endpoints"
graphify query "How does authentication work?"

# Or use Graphify's path tracing
graphify path "AuthController" to "DatabaseService"
```

---

## 📚 When to Use

### Perfect For:

1. **New Repository Setup**
   - Generate KB on first clone
   - Commit KB to repository
   - Team has instant context

2. **Large Codebases**
   - Reduce token consumption
   - Fast context loading
   - Architecture discovery

3. **Team Collaboration**
   - Shareable knowledge base
   - Onboarding new members
   - Architecture documentation

4. **CI/CD Integration**
   - Auto-update KB on commits
   - Always synchronized
   - Version controlled

### Works With:

- **Monorepos** - Multi-project repositories
- **Microservices** - Individual service repositories
- **Libraries** - Package repositories
- **Legacy Code** - Understanding old systems
- **Any Language** - Framework-agnostic

---

## 🔧 How It Works

### Knowledge Base Structure

```
.hyperbrain-kb/
├── graph.html                # Interactive knowledge graph visualization
├── graph.json                # Machine-readable graph structure
├── GRAPH_REPORT.md           # Human-readable architecture report
├── METADATA.json             # KB metadata and statistics
└── README.md                 # Quick start guide
```

### Generation Pipeline (Powered by Graphify)

1. **File Discovery** - Recursive scan with 40+ file type support
2. **Language Detection** - Automatic identification of 25+ languages
3. **AST Extraction** - Deterministic parsing using tree-sitter
4. **Semantic Extraction** - Claude-based understanding for docs/papers
5. **Cross-File Linking** - Call graphs, imports, references
6. **Community Detection** - Leiden algorithm finds clusters
7. **Graph Construction** - Nodes, edges, hyperedges with confidence
8. **Output Generation** - HTML, JSON, Markdown reports
9. **Local KB Setup** - Copy to .hyperbrain-kb/ for repository persistence

---

## 💡 Usage Examples

### Example 1: New Repository Setup

```bash
# Clone a new repository
git clone https://github.com/org/new-project.git
cd new-project

# Generate knowledge base using Graphify
/local-kb generate

# Review generated KB
cat .hyperbrain-kb/GRAPH_REPORT.md

# Open interactive visualization
open .hyperbrain-kb/graph.html

# Commit KB to repository
git add .hyperbrain-kb/
git commit -m "docs: add HyperBrain knowledge base"
git push origin main
```

### Example 2: Update Existing KB

```bash
# After making significant changes
git add .
git commit -m "feat: add new authentication system"

# Auto-update KB (via git hook)
# OR manually:
/local-kb update

# Commit updated KB
git add .hyperbrain-kb/
git commit -m "docs: update knowledge base"
```

### Example 3: Query for Context

```bash
# AI agents can query KB for context
cd .hyperbrain-kb
graphify query "What is the authentication flow?"

# Graphify responds with structured context from the knowledge graph:
# Authentication Flow:
# 1. User submits credentials to /api/auth/login
# 2. AuthController validates input
# 3. AuthService hashes password (bcrypt)
# 4. UserRepository checks database
# 5. JWT token generated (365d expiry)
# 6. Token stored in localStorage
# 7. Subsequent requests use Authorization header
#
# Files involved:
# - src/auth/AuthController.ts
# - src/auth/AuthService.ts
# - src/auth/AuthRepository.ts
# - src/middleware/auth.middleware.ts
```

### Example 4: Integration with AI Agents

```bash
# When working with AI agents, they can load KB first
cat .hyperbrain-kb/GRAPH_REPORT.md

# Then answer questions with full context
# AI: "Based on the knowledge base in .hyperbrain-kb/, this project uses:
#      - Angular 16 for frontend
#      - Node.js/Express for backend
#      - PostgreSQL for database
#      - JWT for authentication
#      - Container/Presenter pattern for components
#
#      I'll follow these patterns for the new feature."
```

---

## 🔧 Configuration

### CLI Options

```bash
/local-kb generate [OPTIONS]

Options:
  --include PATTERN       Glob pattern for files to include [default: **/*]
  --exclude PATTERN       Glob pattern for files to exclude [default: node_modules/**]
  --output-dir PATH       Output directory [default: .hyperbrain-kb]
  --watch                 Watch mode - auto-update on file changes
  --verbose               Verbose output
  --force                 Overwrite existing KB
  --help                  Show help
```

### Environment Variables

```bash
# Set Claude API key for semantic extraction
export ANTHROPIC_API_KEY="your-api-key-here"

# Set parallel processing workers
export GRAPHIIFY_WORKERS=4

# Set max file size for processing (MB)
export GRAPHIIFY_MAX_FILE_SIZE=10
```

### Config File (.hyperbrain-kb/config.json)

```json
{
  "version": "1.0.0",
  "generated_at": "2026-05-04T10:00:00Z",
  "repository": {
    "name": "my-project",
    "url": "https://github.com/org/my-project",
    "branch": "main"
  },
  "settings": {
    "include_patterns": [
      "**/*.ts",
      "**/*.js",
      "**/*.json",
      "**/*.md"
    ],
    "exclude_patterns": [
      "node_modules/**",
      "dist/**",
      "build/**",
      ".git/**",
      "**/*.spec.ts",
      "**/*.test.ts"
    ],
    "graphify_options": {
      "semantic_extraction": true,
      "cross_file_linking": true,
      "community_detection": true
    }
  }
}
```

---

## 🔄 Git Integration

### Auto-Update on Commit

```bash
# Install git hook
/local-kb hook install

# Now KB auto-updates on every commit
git add .
git commit -m "feat: add new feature"
# KB automatically updated and included in commit
```

### Manual Update

```bash
# After significant changes
/local-kb update

# Commit updated KB
git add .hyperbrain-kb/
git commit -m "docs: update knowledge base"
```

### Pre-commit Hook Script

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run on every commit
/local-kb update --quiet

# Add updated KB to commit
git add .hyperbrain-kb/

# Continue with commit
exit 0
```

---

## 📈 Token Savings (Powered by Graphify)

### Without Local KB

```
AI Agent reads entire codebase:
- Frontend: 200,000 tokens
- Backend: 150,000 tokens
- Shared: 50,000 tokens
- Total: 400,000 tokens (exceeds 200K context window!)
```

### With Local KB (via Graphify)

```
AI Agent reads knowledge base:
- graph.json: 2,100 tokens (complete graph structure)
- GRAPH_REPORT.md: 2,000 tokens (architecture summary)
- Total: 4,100 tokens (71.5x reduction!)

AI Agent has complete context with:
- All functions, classes, modules
- Call graphs and dependencies
- API endpoints and routes
- Database schemas
- Design patterns
```

### Benefits

✅ **Faster Responses** - 71.5x less context to process  
✅ **Lower Costs** - 95% fewer tokens consumed  
✅ **Better Understanding** - AST-based extraction, not just text  
✅ **Accurate** - Deterministic parsing with tree-sitter  
✅ **Consistent** - Same context every time  
✅ **Version Controlled** - KB evolves with code  
✅ **Visual** - Interactive HTML graph exploration

---

## 🎯 Advanced Usage

### Custom KB Templates

```bash
# Use custom template
/local-kb generate --template ~/.hyperbrain/templates/startup-kb.md

# Template includes:
- Architecture decision records (ADRs)
- Business logic documentation
- API contracts
- Database schemas
- Deployment procedures
```

### Multi-Project KB

```bash
# Generate KB for monorepo with multiple projects
/local-kb generate --monorepo

# Creates:
.hyperbrain-kb/
├── PROJECTS.md           # List of all projects
├── project1/             # KB for project1
├── project2/             # KB for project2
└── shared/               # Shared dependencies
```

### CI/CD Integration

```yaml
# .github/workflows/update-kb.yml
name: Update Knowledge Base

on:
  push:
    branches: [main]

jobs:
  update-kb:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install HyperBrain
        run: npm install -g hyperbrain-skills
      - name: Update KB
        run: /local-kb update
      - name: Commit KB
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add .hyperbrain-kb/
          git commit -m "docs: auto-update knowledge base" || exit 0
          git push
```

---

## 🔍 Query Examples

### Architecture Questions

```bash
/local-kb query "What is the overall architecture?"
# Returns: Layered architecture description with diagram

/local-kb query "How does frontend communicate with backend?"
# Returns: REST API, WebSocket, authentication flow
```

### Implementation Questions

```bash
/local-kb query "How do I add a new API endpoint?"
# Returns: Step-by-step guide with file locations

/local-kb query "Where is authentication logic implemented?"
# Returns: File paths and class names
```

### Dependency Questions

```bash
/local-kb query "What databases are used?"
# Returns: PostgreSQL, Redis with use cases

/local-kb query "What are the key external dependencies?"
# Returns: Stripe API, SendGrid, AWS S3
```

### Pattern Questions

```bash
/local-kb query "What design patterns are used?"
# Returns: Repository, Factory, Observer, etc.

/local-kb query "How are errors handled?"
# Returns: Error handling patterns and middleware
```

---

## 🛠️ Troubleshooting

### Issue: "KB not found"

```bash
# Solution: Generate KB first
/local-kb generate
```

### Issue: "KB is outdated"

```bash
# Solution: Update KB
/local-kb update

# Or use git hook for auto-update
/local-kb hook install
```

### Issue: "Too much information in KB"

```bash
# Solution: Customize include/exclude patterns
/local-kb generate --include "**/*.ts" --exclude "**/*.spec.ts"
```

### Issue: "Missing information in KB"

```bash
# Solution: Add custom documentation
# Edit .hyperbrain-kb/CUSTOM.md to add project-specific knowledge

/local-kb query "Custom information"
# Will include CUSTOM.md in response
```

---

## 📚 Best Practices

### 1. Commit KB to Repository

```bash
# Always commit KB to version control
git add .hyperbrain-kb/
git commit -m "docs: add knowledge base"
git push origin main
```

### 2. Update Regularly

```bash
# Use git hooks for auto-update
/local-kb hook install

# Or update manually after significant changes
/local-kb update
```

### 3. Customize for Your Team

```bash
# Add team-specific documentation
echo "# Team Conventions" > .hyperbrain-kb/TEAM.md
echo "- We use 2-space indentation" >> .hyperbrain-kb/TEAM.md
echo "- PRs require 1 approval" >> .hyperbrain-kb/TEAM.md
```

### 4. Use with AI Agents

```bash
# When starting a new session, load KB first
/local-kb load

# Then AI has full context from the beginning
```

### 5. Share with Team

```bash
# KB is part of repository, so team automatically has it
# When cloning repo, they get KB too
git clone https://github.com/org/my-project.git
cd my-project
cat .hyperbrain-kb/REPOSITORY_OVERVIEW.md
```

---

## 🎯 Integration with HyperBrain

### Complementary Skills

1. **graphify-integration** - Deep AST analysis for complex patterns
2. **superpowers-brainstorm** - Plan features using KB context
3. **expert-personas** - Expert reviews based on KB architecture
4. **tdd-workflow** - Write tests based on KB patterns
5. **knowledge-bases** - Enhance with domain-specific knowledge

### Workflow Example

```bash
# Step 1: Generate KB for new repo
cd ~/workspace/new-project
/local-kb generate

# Step 2: Commit KB to repository
git add .hyperbrain-kb/
git commit -m "docs: add knowledge base"

# Step 3: Use with HyperBrain skills
# AI: "Based on the knowledge base, this project uses Angular 16
#      with Container/Presenter pattern. I'll follow this pattern
#      for the new component."
```

---

## 📊 KB Statistics

The generator automatically tracks:

- **Files Analyzed**: Total number of files scanned
- **Lines of Code**: Total LOC in repository
- **Languages Detected**: Programming languages used
- **Frameworks Identified**: Frameworks and libraries
- **API Endpoints**: Total REST/GraphQL endpoints
- **Database Models**: Total database tables/models
- **Test Coverage**: Percentage of code tested
- **Documentation**: Percentage of documented code
- **Token Reduction**: Estimated token savings vs raw files

---

## 🚀 Quick Reference Commands

```bash
# Generation
/local-kb generate                              # Generate KB
/local-kb generate --force                      # Overwrite existing
/local-kb update                                # Update existing KB

# Querying
/local-kb query "architecture"                 # Query KB
/local-kb load                                  # Load KB for AI session

# Git Integration
/local-kb hook install                          # Install git hook
/local-kb hook uninstall                        # Remove git hook

# Configuration
/local-kb config show                           # Show config
/local-kb config set key value                  # Set config value

# Information
/local-kb stats                                 # Show KB statistics
/local-kb validate                              # Validate KB completeness
```

---

## 📞 Support

- **GitHub Issues**: https://github.com/itsatif/hyperbrain-skills/issues
- **Documentation**: ~/.claude/skills/hyperbrain-skills/local-kb/
- **Examples**: ~/.claude/skills/hyperbrain-skills/local-kb/examples/

---

**Local KB Generator: Instant repository context, minimal tokens!** 🚀
