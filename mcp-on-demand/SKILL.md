---
name: mcp-on-demand
description: On-demand activation of specialized MCP servers. Use when a task needs a specific MCP server (such as Figma, Morpheus, or a database connector) that should be enabled only when required.
---

# On-Demand MCP Servers

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** On-demand activation of specialized MCP servers
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use ON-DEMAND when needed:**
- **Morpheus MCP** - Query knowledge graphs, search codebase, read files
- **Data Proxy MCP** - Access database services, execute queries
- **Figma Console MCP** - Access Figma designs and components
- **Sentinel MCP** - Monitor and track system health

**These MCP servers activate ONLY when explicitly requested, not automatically.**

---

## 🚀 On-Demand MCP Servers

### 1. Morpheus MCP

**Purpose:** Knowledge graph queries and codebase search

**When to Activate:**
- Query knowledge graphs for specific information
- Search codebase for patterns or implementations
- Get architecture overview
- Retrieve InfluxDB schema information
- Read specific files with context

**How to Activate:**
```
User: "Use Morpheus to query the knowledge graph"
User: "Search codebase for container pattern"
User: "Get architecture from Morpheus"
```

**Available Tools:**
```javascript
// Knowledge Graph Queries
query_graph(graphName, query)
// Example: Query jt-api-v2 architecture

// Code Search
search_codebase(searchTerm, options)
// Example: Search for "Container" pattern

// File Reading
read_file(filePath, options)
// Example: Read service file with context

// Architecture Overview
get_architecture(serviceName)
// Example: Get iot-application architecture

// InfluxDB Schema
influx_schema(measurement)
// Example: Get components measurement schema
```

**Configuration:**
```json
{
  "mcpServers": {
    "morpheus": {
      "url": "https://cody.smartjoules.org/sse",
      "type": "http",
      "disabled": false,
      "required": false,
      "description": "DeJoule AI Assistant - HTTP MCP Server",
      "autoApprove": [
        "mcp__morpheus__*",
        "query_graph",
        "search_codebase",
        "read_file",
        "get_architecture",
        "influx_schema",
        "code_search",
        "code_read"
      ]
    }
  }
}
```

**Usage Examples:**

```bash
# Example 1: Query knowledge graph
User: "Use Morpheus to query the backend knowledge graph"

AI: [Activates Morpheus MCP on-demand]
    "Querying backend knowledge graph...
    
    Retrieved from jt-api-v2:
    - Architecture: Layered (Controller → Service → Repository)
    - Services: 7 microservices
    - API Endpoints: 50+ routes
    - Database: PostgreSQL, InfluxDB, Redis"

# Example 2: Search codebase
User: "Use Morpheus to search for Container pattern implementation"

AI: [Activates Morpheus MCP on-demand]
    "Searching codebase for Container pattern...
    
    Found 15 results:
    1. jouletrack-angular/lib/components/ContainerComponent.ts
    2. jouletrack-angular/lib/presenters/DevicePresenter.ts
    3. jouletrack-angular/lib/services/DeviceContainer.service.ts
    ..."

# Example 3: Get architecture
User: "Use Morpheus to get iot-application architecture"

AI: [Activates Morpheus MCP on-demand]
    "Retrieving iot-application architecture...
    
    iot-application Architecture:
    - Purpose: MQTT to InfluxDB data bridge
    - Language: Node.js/TypeScript
    - Responsibilities:
      • Subscribe to MQTT telemetry topics
      • Validate incoming message schemas
      • Transform to InfluxDB line protocol
      • Write to InfluxDB (device_component/autogen)
      • Publish acknowledgments"
```

---

### 2. Data Proxy MCP

**Purpose:** Access database services and execute queries

**When to Activate:**
- Query databases (PostgreSQL, InfluxDB, Redis)
- Execute database operations
- Access time-series data
- Retrieve device telemetry
- Perform data analytics

**How to Activate:**
```
User: "Use data-proxy to query PostgreSQL"
User: "Execute InfluxDB query through data-proxy"
User: "Get device telemetry from data-proxy"
```

**Available Tools:**
```javascript
// PostgreSQL Queries
execute_postgresql_query(query, params)
// Example: Query device information

// InfluxDB Queries
execute_influxdb_query(query)
// Example: Query time-series telemetry data

// Redis Operations
execute_redis_command(command, params)
// Example: Get/set cache values

// Database Health
check_database_health(databaseType)
// Example: Check connection status
```

**Configuration:**
```json
{
  "mcpServers": {
    "data-proxy": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://10.40.21.254:8100/sse",
        "--allow-http"
      ],
      "disabled": false,
      "description": "Local SSE proxy for data services",
      "autoApprove": []
    }
  }
}
```

**Usage Examples:**

```bash
# Example 1: Query PostgreSQL
User: "Use data-proxy to get all devices for site iah-del"

AI: [Activates data-proxy MCP on-demand]
    "Querying PostgreSQL...
    
    SELECT * FROM devices WHERE site_id = 'iah-del';
    
    Results:
    - chiller-1 (Controller: ctrl-1, Type: Chiller)
    - chiller-2 (Controller: ctrl-1, Type: Chiller)
    - ahu-1 (Controller: ctrl-2, Type: AHU)
    - ahu-2 (Controller: ctrl-2, Type: AHU)"

# Example 2: Query InfluxDB
User: "Use data-proxy to get last 24 hours of SEC data"

AI: [Activates data-proxy MCP on-demand]
    "Querying InfluxDB...
    
    SELECT mean(\"value\") FROM \"components\" 
    WHERE (\"field\" = 'sec') 
    AND time > now() - 24h 
    GROUP BY time(1h), \"componentId\"
    
    Results:
    - chiller-1: Average SEC = 0.75 kWh/TR
    - chiller-2: Average SEC = 0.82 kWh/TR
    - ahu-1: Average SEC = N/A (not applicable)"

# Example 3: Redis cache
User: "Use data-proxy to check cache for dashboard data"

AI: [Activates data-proxy MCP on-demand]
    "Checking Redis cache...
    
    GET dashboard:iah-del:overview
    
    Cache Status: HIT
    Data: { consumption: 1520.5, efficiency: 0.75, devices: 4 }"
```

---

### 3. Figma Console MCP

**Purpose:** Access Figma designs and components

**When to Activate:**
- Get Figma file data
- Access design components
- Take screenshots of designs
- Get component for development
- Access design tokens

**How to Activate:**
```
User: "Use Figma to get the dashboard design"
User: "Get component from Figma"
User: "Take screenshot of Figma design"
```

**Configuration:**
```json
{
  "mcpServers": {
    "figma-console": {
      "command": "npx",
      "args": [
        "figma-console-mcp"
      ],
      "env": {
        "FIGMA_ACCESS_TOKEN": "YOUR_FIGMA_TOKEN",
        "ENABLE_MCP_APPS": "true"
      },
      "disabled": false,
      "autoApprove": [
        "figma_get_status",
        "figma_get_file_data",
        "figma_get_component_for_development",
        "figma_get_component_image",
        "figma_take_screenshot",
        "figma_get_design_context",
        "figma_get_figjam"
      ]
    }
  }
}
```

**Usage Examples:**

```bash
# Example 1: Get Figma file
User: "Use Figma to get the dashboard design file"

AI: [Activates Figma Console MCP on-demand]
    "Fetching Figma file...
    
    File: Dashboard Design
    - Pages: 5 (Dashboard, Analytics, Settings, Profile, Help)
    - Components: 23
    - Styles: 12 color styles, 8 text styles
    - Last modified: 2026-05-02"

# Example 2: Get component
User: "Use Figma to get the button component for development"

AI: [Activates Figma Console MCP on-demand]
    "Fetching component...
    
    Component: Primary Button
    - Properties:
      • Width: 120px, Height: 40px
      • Background: #1976D2
      • Border Radius: 4px
      • Font: Roboto Medium 14px
      • Color: #FFFFFF
    - States: Default, Hover, Disabled, Loading"
```

---

### 4. Sentinel MCP

**Purpose:** Monitor and track system health

**When to Activate:**
- Check system health status
- Monitor application metrics
- Track error rates
- Get performance data

**How to Activate:**
```
User: "Use Sentinel to check system health"
User: "Get application metrics from Sentinel"
```

**Usage Examples:**

```bash
# Example 1: Check system health
User: "Use Sentinel to check the health of all services"

AI: [Activates Sentinel MCP on-demand]
    "Checking system health...
    
    Service Status:
    - jt-api-v2: ✅ Healthy (Uptime: 99.9%)
    - iot-application: ✅ Healthy (Uptime: 99.8%)
    - iot-feedback-handler: ✅ Healthy (Uptime: 99.7%)
    - hostServices: ⚠️ Degraded (Uptime: 98.5%)
    
    Overall System: ✅ Healthy"
```

---

## 🎯 On-Demand Activation Strategy

### How On-Demand Activation Works

```
USER REQUEST WITHOUT TRIGGER
    ↓
AI: Does NOT activate MCP server
    ↓
AI: Uses built-in knowledge and skills

USER REQUEST WITH TRIGGER
    ↓
AI: Detects on-demand trigger keyword
    ↓
AI: Activates specific MCP server
    ↓
AI: Executes operation via MCP
    ↓
AI: Returns results
```

### Trigger Keywords

| MCP Server | Trigger Keywords | Example Requests |
|------------|-----------------|------------------|
| **Morpheus** | "Use Morpheus", "Query knowledge graph", "Search codebase" | "Use Morpheus to query backend architecture" |
| **Data Proxy** | "Use data-proxy", "Query database", "Execute SQL" | "Use data-proxy to query devices" |
| **Figma** | "Use Figma", "Get Figma design", "Figma component" | "Use Figma to get dashboard design" |
| **Sentinel** | "Use Sentinel", "Check health", "System status" | "Use Sentinel to check system health" |

---

## 📋 MCP Server Specifications

### Morpheus MCP

**Server Details:**
- **URL:** `https://cody.smartjoules.org/sse`
- **Type:** HTTP SSE (Server-Sent Events)
- **Status:** Production
- **Latency:** ~100ms average
- **Uptime:** 99.9%

**Available Functions:**
1. `query_graph(graphName, query)` - Query knowledge graphs
2. `search_codebase(searchTerm, options)` - Search codebase
3. `read_file(filePath, options)` - Read file with context
4. `get_architecture(serviceName)` - Get service architecture
5. `influx_schema(measurement)` - Get InfluxDB schema
6. `code_search(pattern)` - Search for code patterns

**Knowledge Graphs Available:**
- `dejoule-organization` - Complete org knowledge
- `jt-api-v2` - Backend architecture
- `iot-platform` - IoT systems
- `qa-automation` - Testing knowledge

---

### Data Proxy MCP

**Server Details:**
- **URL:** `http://10.40.21.254:8100/sse`
- **Type:** HTTP SSE (Server-Sent Events)
- **Status:** Internal network
- **Latency:** ~50ms average
- **Network:** Internal VLAN

**Available Databases:**
1. **PostgreSQL** - Relational data
   - Device information
   - User accounts
   - Site configuration
   - Historical data

2. **InfluxDB** - Time-series data
   - Telemetry data
   - Device metrics
   - Energy consumption
   - Performance data

3. **Redis** - Cache layer
   - API responses
   - Session data
   - Real-time state

**Available Functions:**
1. `execute_postgresql_query(query, params)` - Execute PostgreSQL query
2. `execute_influxdb_query(query)` - Execute Flux query
3. `execute_redis_command(command, params)` - Execute Redis command
4. `check_database_health(databaseType)` - Check database status

---

## 🔒 Security Considerations

### Access Control

**Morpheus MCP:**
- Requires authentication via HTTPS
- Auto-approves read-only operations
- Enforces query rate limits
- Logs all queries

**Data Proxy MCP:**
- Internal network access only
- Requires VPN connection
- Database-level permissions
- Query execution time limits

**Figma Console MCP:**
- Requires Figma access token
- Read-only access to designs
- No design modification capability
- Token rotation every 90 days

---

## 🚀 Performance Optimization

### Connection Pooling

```javascript
// MCP server connections are pooled
const connectionPool = {
  morpheus: {
    minConnections: 1,
    maxConnections: 5,
    connectionTimeout: 5000
  },
  dataProxy: {
    minConnections: 2,
    maxConnections: 10,
    connectionTimeout: 3000
  }
};
```

### Query Optimization

```javascript
// Queries are optimized automatically
const queryOptimizer = {
  cacheResults: true,
  cacheDuration: 300000, // 5 minutes
  maxResults: 1000,
  timeout: 10000 // 10 seconds
};
```

---

## ✅ Best Practices

### When to Use On-Demand MCP

✅ **Use MCP when:**
- Querying large knowledge bases
- Searching codebase for patterns
- Accessing real-time database data
- Getting latest Figma designs
- Checking system health status

❌ **Don't use MCP when:**
- Basic coding tasks (use built-in skills)
- Simple pattern matching (use knowledge base)
- Local file operations (use filesystem tools)
- General questions (use built-in knowledge)

### Performance Tips

1. **Cache Results** - MCP responses are cached for 5 minutes
2. **Batch Queries** - Combine multiple queries when possible
3. **Use Specific Queries** - Narrow down query scope
4. **Set Timeouts** - Don't wait indefinitely for responses

---

## 📚 Integration with Other Skills

- **superpowers-brainstorming** - Initial planning
- **dejoule-knowledge-base** - Organizational context
- **backend-knowledge-base** - Backend patterns
- **iot-knowledge-base** - IoT patterns
- **mcp-setup** - MCP server configuration

---

## 🎯 Summary

**On-Demand MCP Servers:**
- ✅ Activate ONLY when explicitly requested
- ✅ Provide specialized capabilities
- ✅ Integrate seamlessly with skills
- ✅ Maintain security and performance
- ✅ Auto-approve safe operations

**No automatic activation - full control!** 🚀
