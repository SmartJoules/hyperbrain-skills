---
name: graphify-integration
description: Transform a codebase into a queryable knowledge graph using AST-based extraction and semantic analysis. Use when you want to map a repository's structure, generate a knowledge graph, or reduce token usage by giving the AI precomputed code context.
---

# Graphify Integration - Knowledge Graph Creation

**Part of HyperBrain Skills Library**

**Purpose:** Transform codebases into queryable knowledge graphs using AST-based extraction and semantic analysis

**Version:** 1.0.0  
**Last Updated:** 2026-05-04

---

## 🎯 Overview

Graphify is an AI-powered knowledge graph extraction tool that converts source code, documentation, and research papers into queryable knowledge graphs with 71.5x token efficiency compared to raw files.

### Core Capabilities

- **AST Extraction**: Deterministic code parsing for 25+ programming languages
- **Semantic Extraction**: Claude-based understanding of documentation, papers, images
- **Community Detection**: Leiden algorithm finds concept clusters
- **Cross-File Analysis**: Call graphs, dependency tracking, architectural patterns
- **Multi-Modal Support**: Code, docs, PDFs, images, video/audio transcriptions
- **Interactive Outputs**: HTML visualization, JSON export, Markdown reports
- **MCP Server**: Expose knowledge graphs for live querying

---

## 🚀 Quick Start

### Installation

```bash
# Option 1: Using uv (recommended - fastest)
pip install uv
uv pip install graphifyy

# Option 2: Using pipx
pipx install graphifyy

# Option 3: Using pip
pip install graphifyy

# Verify installation
graphify --version
```

### Platform-Specific Setup

**macOS:**
```bash
# Install system dependencies
brew install tree-sitter ffmpeg

# Install graphify
pip install graphifyy
```

**Linux:**
```bash
# Install system dependencies
sudo apt-get update
sudo apt-get install -y tree-sitter libyaml-dev ffmpeg

# Install graphify
pip install graphifyy
```

**Windows:**
```bash
# Install using pip (WSL recommended)
pip install graphifyy
```

---

## 📚 When to Use

### Use Graphify When You Need To:

1. **Understand Large Codebases**
   - New team member onboarding
   - Legacy system documentation
   - Architecture discovery

2. **Create Knowledge Bases**
   - Transform existing code into queryable graphs
   - Build semantic indexes for services
   - Generate documentation from code

3. **Analyze Code Patterns**
   - Find design patterns across services
   - Identify coupling and dependencies
   - Trace data flow through systems

4. **Review Architecture**
   - Service interaction analysis
   - API endpoint discovery
   - Component relationship mapping

5. **Process Research**
   - Extract knowledge from academic papers
   - Analyze technical documentation
   - Process video transcripts with code references

---

## 🔧 How It Works

### Extraction Pipeline (9 Steps)

1. **File Discovery** - Recursive scan with 40+ file type support
2. **Language Detection** - Automatic identification of 25+ languages
3. **AST Extraction** - Deterministic parsing using tree-sitter
4. **Semantic Extraction** - Claude-based understanding for docs/papers
5. **Cross-File Linking** - Call graphs, imports, references
6. **Community Detection** - Leiden algorithm finds clusters
7. **Graph Construction** - Nodes, edges, hyperedges with confidence
8. **Output Generation** - HTML, JSON, Markdown reports
9. **Optional MCP** - Expose as queryable server

### Knowledge Graph Structure

```json
{
  "nodes": [
    {
      "id": "UserService.register",
      "type": "function",
      "language": "typescript",
      "file": "services/user.service.ts",
      "line": 42,
      "metadata": {
        "visibility": "public",
        "async": true,
        "parameters": ["userData: UserDTO"]
      }
    }
  ],
  "edges": [
    {
      "source": "UserService.register",
      "target": "UserRepository.create",
      "type": "EXTRACTED",
      "relationship": "calls",
      "confidence": 1.0
    }
  ],
  "hyperedges": [
    {
      "id": "auth_flow",
      "nodes": ["AuthService.login", "UserService.validate", "TokenService.generate"],
      "type": "workflow"
    }
  ]
}
```

### Edge Types

- **EXTRACTED** (confidence: 1.0) - Explicit in source code (imports, function calls)
- **INFERRED** (confidence: 0.7) - Reasonable inference (data flow, implicit dependencies)
- **AMBIGUOUS** (confidence: 0.3) - Uncertain relationships (potential coupling)

---

## 💡 Usage Examples

### Basic Usage

```bash
# Analyze current directory
graphify

# Analyze specific directory
graphify /path/to/codebase

# Analyze with custom output
graphify --output-dir ./knowledge-graphs/my-service

# Include/exclude patterns
graphify --include "**/*.ts" --exclude "**/*.spec.ts"

# Verbose output
graphify --verbose
```

### HyperBrain Integration

```bash
# Create knowledge base for jt-api-v2
cd ~/.claude/skills/hyperbrain-skills/backend-knowledge-base
graphify --output-dir ./knowledge/jt-api-v2-graph

# Create knowledge base for IoT platform
cd ~/workspace/iot-application
graphify --output-dir ~/.claude/skills/hyperbrain-skills/iot-knowledge-base/knowledge/iot-graph

# Analyze Angular components
cd ~/workspace/jouletrack-angular
graphify --include "**/*.component.ts" --output-dir ./knowledge/components-graph
```

### Advanced Queries

```bash
# Query the knowledge graph
graphify query "What are all the REST endpoints in jt-api-v2?"

# Find call paths
graphify path "UserService.register" to "DatabaseService.execute"

# Explain architectural patterns
graphify explain "How does device telemetry flow from MQTT to InfluxDB?"

# Interactive exploration
graphify query --interactive
```

### Continuous Updates

```bash
# Watch mode - auto-update on file changes
graphify --watch

# Update existing graph
graphify update --graph-dir ./knowledge/jt-api-v2-graph

# Git hook integration
graphify hook install  # Runs on pre-commit
```

---

## 🔍 Integration with HyperBrain

### 1. Backend Knowledge Base Enhancement

**Current:** Manual documentation of jt-api-v2 architecture  
**With Graphify:** Automatically extracted service graph

```bash
cd ~/workspace/jt-api-v2
graphify \
  --include "**/*.ts" \
  --exclude "**/*.spec.ts" \
  --output-dir ~/.claude/skills/hyperbrain-skills/backend-knowledge-base/knowledge/auto-extracted
```

**Results:**
- All 50+ endpoints automatically documented
- Service dependencies mapped
- Middleware stack identified
- Database schema relationships extracted

### 2. IoT Knowledge Base Enhancement

**Current:** MQTT/Kafka patterns documented manually  
**With Graphify:** Semantic extraction of IoT architecture

```bash
cd ~/workspace/iot-application
graphify \
  --include "**/*.ts" \
  --output-dir ~/.claude/skills/hyperbrain-skills/iot-knowledge-base/knowledge/iot-graph
```

**Results:**
- MQTT topic subscriptions mapped
- Kafka consumer groups identified
- InfluxDB schema relationships documented
- Device telemetry flow traced end-to-end

### 3. Frontend Component Analysis

**Current:** Angular component patterns documented  
**With Graphify:** Component dependency and state flow

```bash
cd ~/workspace/jouletrack-angular
graphify \
  --include "**/*.component.ts" \
  --include "**/*.service.ts" \
  --output-dir ~/.claude/skills/hyperbrain-skills/jouletrack-angular/knowledge/components
```

**Results:**
- Component hierarchy mapped
- Service dependencies identified
- RxJS observable chains analyzed
- Routing structure documented

### 4. Multi-Modal Documentation

```bash
# Include research papers and architecture diagrams
graphify \
  --code-dir ~/workspace/jt-api-v2 \
  --docs-dir ~/docs/architecture \
  --papers-dir ~/research/optimization-papers \
  --output-dir ./knowledge/full-stack
```

**Results:**
- Code implementation linked to design docs
- Research papers connected to implementation
- Architecture diagrams annotated with code references

---

## 📊 Output Formats

### 1. Interactive HTML (graph.html)

- **Visual exploration** of knowledge graph
- **Search and filter** by node type, language, file
- **Drill-down** into function/class details
- **Call graph visualization** with interactive paths
- **Community detection** highlighted

**Usage:**
```bash
# Generate and open HTML
graphify --output-dir ./knowledge
open ./knowledge/graph.html
```

### 2. JSON Export (graph.json)

- **Machine-readable** graph structure
- **MCP server** integration ready
- **Custom query** capability
- **Version control** friendly

**Usage:**
```bash
# Use with MCP server
graphify --mcp --port 8080

# Or query programmatically
cat ./knowledge/graph.json | jq '.nodes[] | select(.type == "function")'
```

### 3. Markdown Report (GRAPH_REPORT.md)

- **Human-readable** summary
- **Architecture overview**
- **Key metrics** (LOC, complexity, coupling)
- **Recommendations** for refactoring

**Usage:**
```bash
# View report
cat ./knowledge/GRAPH_REPORT.md

# Commit to documentation
git add ./knowledge/GRAPH_REPORT.md
```

---

## 🎯 Token Efficiency

### Problem: Large Codebases Exceed Context

Reading entire codebase:
- **jt-api-v2**: ~150,000 tokens
- **iot-application**: ~120,000 tokens
- **jouletrack-angular**: ~200,000 tokens

**Total**: 470,000 tokens (exceeds 200K context window)

### Solution: Knowledge Graph Compression

Graphify extracts:
- **jt-api-v2**: ~2,100 tokens (71.5x reduction)
- **iot-application**: ~1,700 tokens (70.6x reduction)
- **jouletrack-angular**: ~2,800 tokens (71.4x reduction)

**Total**: 6,600 tokens (fits in context with room to spare)

### Benefits

1. **Complete Context** - Entire codebase in single query
2. **Semantic Understanding** - Relationships, not just text
3. **Fast Analysis** - No need to read multiple files
4. **Accurate Responses** - Grounded in extracted structure

---

## 🔧 Configuration

### CLI Options

```bash
graphify [OPTIONS] [PATH]

Options:
  --output-dir PATH       Output directory for graph files [default: ./graph-output]
  --include PATTERN       Glob pattern for files to include [default: **/*]
  --exclude PATTERN       Glob pattern for files to exclude [default: None]
  --watch                 Watch mode - auto-update on file changes
  --verbose               Verbose output
  --mcp                   Start MCP server for live querying
  --mcp-port PORT         MCP server port [default: 8080]
  --cluster-only          Only run community detection, skip extraction
  --help                  Show help message
  --version               Show version
```

### Environment Variables

```bash
# Set Claude API key for semantic extraction
export ANTHROPIC_API_KEY="your-api-key-here"

# Set parallel processing workers
export GRAPHIIFY_WORKERS=4

# Set max file size for processing (MB)
export GRAPHIIFY_MAX_FILE_SIZE=10

# Enable/disable semantic extraction
export GRAPHIIFY_SEMANTIC_EXTRACTION=true
```

### Config File (~/.graphify/config.yaml)

```yaml
extraction:
  languages:
    - typescript
    - python
    - go
    - sql

  include:
    - "**/*.ts"
    - "**/*.py"
    - "**/*.go"
    - "**/*.sql"

  exclude:
    - "**/*.spec.ts"
    - "**/node_modules/**"
    - "**/dist/**"

  semantic_extraction:
    enabled: true
    model: claude-sonnet-4-20250514

output:
  formats:
    - html
    - json
    - markdown

  directory: ./knowledge-graphs

mcp:
  enabled: false
  port: 8080
```

---

## 🎓 Advanced Workflows

### Workflow 1: Architecture Review

```bash
# Step 1: Extract knowledge graph
cd ~/workspace/jt-api-v2
graphify --output-dir ./knowledge

# Step 2: Query for architectural patterns
graphify query "What are the main service layers?"
graphify query "How are services organized by domain?"

# Step 3: Identify coupling
graphify query "Which services have high dependencies?"

# Step 4: Generate report
graphify explain "Service architecture and recommendations"
```

### Workflow 2: Dependency Analysis

```bash
# Step 1: Extract dependencies
graphify --include "**/*.ts" --output-dir ./knowledge

# Step 2: Find all call paths
graphify path "AuthService" to "DatabaseService"

# Step 3: Identify circular dependencies
graphify query "Find circular dependencies in services"

# Step 4: Visualize in HTML
open ./knowledge/graph.html
```

### Workflow 3: Onboarding New Team Member

```bash
# Step 1: Create comprehensive knowledge base
cd ~/workspace/jouletrack-angular
graphify --output-dir ./knowledge/onboarding

# Step 2: Generate documentation
cat ./knowledge/onboarding/GRAPH_REPORT.md > docs/ARCHITECTURE.md

# Step 3: Explore interactively
open ./knowledge/onboarding/graph.html

# Step 4: Query specific workflows
graphify query "How does device registration work?"
graphify query "Show authentication flow"
```

### Workflow 4: Continuous Documentation

```bash
# Step 1: Install git hook
graphify hook install

# Step 2: Commit changes
git add .
git commit -m "Add new device monitoring service"

# Step 3: Graphify auto-updates knowledge graph
# Knowledge base always stays in sync with code
```

---

## 🔍 Query Examples

### Code Navigation

```bash
# Find all REST endpoints
graphify query "List all @Controller or @RestController endpoints"

# Find database operations
graphify query "Show all database queries and their tables"

# Find async operations
graphify query "List all async functions and their awaited operations"
```

### Architecture Analysis

```bash
# Identify service boundaries
graphify query "What are the distinct service modules?"

# Find shared utilities
graphify query "Which utilities are used across multiple services?"

# Analyze error handling
graphify query "Show error handling patterns across services"
```

### Dependency Tracking

```bash
# Trace data flow
graphify path "DeviceController.create" to "InfluxDBService.write"

# Find impact of changes
graphify query "What depends on UserService.authenticate?"

# Identify deprecated code
graphify query "Find unused or unreachable functions"
```

### Pattern Discovery

```bash
# Find design patterns
graphify query "Identify Factory pattern implementations"

# Find anti-patterns
graphify query "Show God classes with too many responsibilities"

# Find test coverage gaps
graphify query "Which functions lack test coverage?"
```

---

## 📈 Metrics and Analysis

### Graph Metrics

Graphify automatically calculates:

- **Node Count** - Total functions, classes, modules
- **Edge Count** - Total relationships and dependencies
- **Average Degree** - Average connections per node
- **Community Count** - Number of clusters found
- **Modularity Score** - How well-clustered the graph is
- **Largest Community Size** - Biggest cluster size

### Code Metrics

- **Lines of Code** - Total LOC analyzed
- **Language Distribution** - Breakdown by language
- **File Type Distribution** - Code vs docs vs config
- **Complexity Score** - Cyclomatic complexity average
- **Coupling Score** - Average module dependencies
- **Cohesion Score** - How focused modules are

### Quality Metrics

- **Test Coverage** - Functions with tests vs without
- **Documentation Coverage** - Documented vs undocumented
- **Code Duplication** - Similar function detection
- **Dead Code** - Unused functions and imports
- **Circular Dependencies** - Circular reference detection

---

## 🔧 Troubleshooting

### Common Issues

**Issue: "tree-sitter not found"**
```bash
# Install tree-sitter
brew install tree-sitter  # macOS
sudo apt-get install tree-sitter  # Linux
```

**Issue: "ffmpeg not found" (for video processing)**
```bash
# Install ffmpeg
brew install ffmpeg  # macOS
sudo apt-get install ffmpeg  # Linux
```

**Issue: "Out of memory during extraction"**
```bash
# Limit file size or reduce workers
export GRAPHIIFY_MAX_FILE_SIZE=5
export GRAPHIIFY_WORKERS=2
```

**Issue: "Claude API rate limit"**
```bash
# Disable semantic extraction for code-only analysis
export GRAPHIIFY_SEMANTIC_EXTRACTION=false
```

### Debug Mode

```bash
# Enable verbose output
graphify --verbose

# Check what's being processed
graphify --verbose 2>&1 | tee graphify.log

# Test with single file
graphify --include "src/services/user.service.ts"
```

---

## 🚀 Best Practices

### 1. Start Small

```bash
# Test on single directory first
graphify src/services --output-dir ./test-graph

# Verify output quality
cat ./test-graph/GRAPH_REPORT.md

# Then scale to full codebase
graphify --output-dir ./knowledge
```

### 2. Use Exclude Patterns

```bash
# Exclude generated code and tests
graphify \
  --exclude "**/*.spec.ts" \
  --exclude "**/node_modules/**" \
  --exclude "**/dist/**" \
  --exclude "**/*.generated.ts"
```

### 3. Combine with HyperBrain Skills

```bash
# Step 1: Extract graph
graphify --output-dir ./knowledge

# Step 2: Use with expert-personas
# "Act as Google L7 Backend Engineer and review the architecture in ./knowledge/GRAPH_REPORT.md"

# Step 3: Use with tdd-workflow
# "Based on the dependency graph in ./knowledge/graph.json, write tests for critical paths"
```

### 4. Regular Updates

```bash
# Schedule weekly knowledge graph updates
crontab -e
# Add: 0 0 * * 0 cd ~/workspace/jt-api-v2 && graphify --output-dir ./knowledge
```

### 5. Version Control Knowledge Graphs

```bash
# Commit knowledge graphs to documentation branch
git add knowledge/GRAPH_REPORT.md
git commit -m "docs: update knowledge graph"
git push origin documentation
```

---

## 📚 Integration with HyperBrain Ecosystem

### Complementary Skills

1. **superpowers-brainstorming** - Plan architecture changes using graph insights
2. **expert-personas** - Domain experts review extracted knowledge
3. **backend-knowledge-base** - Graphify auto-extracts, manual docs refine
4. **iot-knowledge-base** - MQTT/Kafka patterns from semantic extraction
5. **tdd-workflow** - Identify critical paths for testing from graph
6. **qa-automation** - Generate test cases from call graph analysis

### Workflow Example

```bash
# Step 1: Extract current architecture
cd ~/workspace/jt-api-v2
graphify --output-dir ./knowledge/before-refactor

# Step 2: Plan refactoring with HyperBrain
# /superpowers-brainstorm "Refactor jt-api-v2 for microservices architecture"

# Step 3: Implement changes using TDD
# /tdd "Implement device service microservice"

# Step 4: Extract new architecture
graphify --output-dir ./knowledge/after-refactor

# Step 5: Compare graphs
graphify query "Show differences between before and after architectures"
```

---

## 📞 Support and Resources

### Official Resources

- **GitHub**: https://github.com/safishamsi/graphify
- **PyPI Package**: https://pypi.org/project/graphifyy/ (note: double 'y')
- **Documentation**: https://github.com/safishamsi/graphify#readme
- **Issues**: https://github.com/safishamsi/graphify/issues

### HyperBrain Integration

- **HyperBrain GitHub**: https://github.com/itsatif/hyperbrain-skills
- **Documentation**: ~/.claude/skills/hyperbrain-skills/HYPERBRAIN_SYSTEM.md
- **Examples**: ~/.claude/skills/hyperbrain-skills/graphify-integration/examples/

### Getting Help

```bash
# Graphify help
graphify --help

# Check version
graphify --version

# Report issues
gh issue create --repo safishamsi/graphify
```

---

## 🎯 Quick Reference Commands

```bash
# Basic usage
graphify                                          # Analyze current directory
graphify /path/to/codebase                        # Analyze specific path
graphify --output-dir ./knowledge                  # Custom output

# Filtering
graphify --include "**/*.ts"                       # Include only TypeScript
graphify --exclude "**/*.spec.ts"                  # Exclude test files
graphify --include "**/*.ts" --exclude "**/*.spec.ts"  # Both

# Continuous mode
graphify --watch                                   # Auto-update on changes
graphify update --graph-dir ./knowledge            # Update existing graph

# Querying
graphify query "REST endpoints"                    # Query knowledge
graphify path "A" to "B"                           # Find path
graphify explain "architecture"                    # Explain pattern

# Output formats
graphify --output-dir ./knowledge                  # Generate all formats
graphify --mcp --port 8080                         # Start MCP server

# Git integration
graphify hook install                              # Install pre-commit hook
graphify hook uninstall                            # Remove hooks
```

---

**Graphify Integration: Transform your codebase into queryable knowledge!** 🚀
