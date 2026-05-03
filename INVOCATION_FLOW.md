# Skill Invocation Flow - Visual Guide

**How AI-SDLC Skills Work Automatically**

---

## 🎯 The Simple Version

```
YOU ASK A QUESTION
        ↓
   AI THINKS
        ↓
   ACTIVATES SKILLS AUTOMATICALLY
        ↓
   GIVES YOU ANSWER
```

**That's it!** No manual skill selection needed.

---

## 🧠 The Detailed Version

### Step 1: You Ask a Question

```
User: "Create a new Angular component for user profile"
```

### Step 2: AI Automatically Activates Superpowers

```
AI: [Superpowers Brainstorming ACTIVATES AUTOMATICALLY]

    "Let me understand your requirements:
    1. What data should it display?
    2. Any user interactions needed?
    3. Should it fetch data from API?
    4. Any state management needed?"
```

### Step 3: AI Detects Context

```
AI: [Scans project files]
    ✅ Detects: Angular project (angular.json, *.ts files)
    ✅ Detects: TypeScript
    ✅ Detects: @angular imports

    [Loads jouletrack-angular skill AUTOMATICALLY]
```

### Step 4: AI Loads Knowledge Base

```
AI: [Detects "component" keyword]
    [Activates DeJoule Knowledge Base]

    "Based on DeJoule patterns:
    - Container/Presenter pattern
    - Service layer for API calls
    - TDD test-first approach
    - 80%+ test coverage"
```

### Step 5: AI Generates Code

```
AI: [Follows Angular patterns]
    [Follows TDD workflow]
    [Follows DeJoule conventions]

    Creates:
    ✅ UserProfileContainer (logic)
    ✅ UserProfile (presentation)
    ✅ UserProfileService (API)
    ✅ UserProfile.component.spec.ts (tests)
```

---

## 🔍 How AI Knows Which Skills to Use

### Keyword Detection

```
Your Request                    →  AI Activates
────────────────────────────────────────────────────────
"Create Angular component"      →  jouletrack-angular
"Write unit tests"              →  tdd-workflow
"Debug MQTT connection"         →  mqtt-patterns + iot-kb
"Query PostgreSQL database"     →  database-patterns
"Create PRD in Notion"          →  Notion MCP
"Update GitHub PR"              →  GitHub MCP
"Generate E2E tests"            →  playwright-patterns
```

### Context Detection

```
Project Files                   →  AI Activates
────────────────────────────────────────────────────────
angular.json, *.ts              →  jouletrack-angular
package.json (express)          →  nodejs-patterns
requirements.txt (fastapi)      →  python-patterns
go.mod                           →  go-patterns
docker-compose.yml (mqtt)       →  mqtt-patterns
```

### Always Active

```
Superpowers Brainstorming       →  ACTIVATES FOR EVERY REQUEST
────────────────────────────────────────────────────────
Ask anything                    →  AI brainstorms first
```

---

## 💡 Real Examples

### Example 1: Simple Request

```
YOU: "Create a login form"
      ↓
AI: [Superpowers activates]
    "What authentication method? Email/password? OAuth?"
      ↓
YOU: "Email with JWT"
      ↓
AI: [Detects: Frontend form]
    [Loads: Angular patterns]
    [Loads: TDD workflow]
    [Loads: Backend KB for JWT API]

    "I'll create:
    - LoginComponent (Container/Presenter)
    - LoginService (JWT handling)
    - AuthGuard (Route protection)
    - Tests (80%+ coverage)"
      ↓
AI: [Generates all files]
    ✅ Complete
```

### Example 2: Complex Request

```
YOU: "Add device monitoring dashboard"
      ↓
AI: [Superpowers activates]
    "Let me understand:
    1. Which devices? (Chillers, AHUs?)
    2. What metrics? (Temperature, energy, SEC?)
    3. Real-time updates? (WebSocket?)
    4. Historical data? (Time charts?)"
      ↓
YOU: "All chillers, real-time SEC, with historical trends"
      ↓
AI: [Detects: Dashboard + IoT]
    [Loads: Angular patterns]
    [Loads: IoT Knowledge Base]
    [Loads: DeJoule KB]
    [Loads: InfluxDB patterns]
    [Loads: TDD workflow]
    [Loads: Playwright for E2E]

    "Based on IoT architecture:
    - MQTT topic: data/{siteId}/{controllerId}/chiller
    - InfluxDB query: Flux for time-series
    - WebSocket for real-time updates

    I'll create:
    1. DeviceDashboardComponent
    2. DeviceMonitoringService (WebSocket)
    3. InfluxDB service (Flux queries)
    4. SEC chart component
    5. Unit tests (Jasmine)
    6. Integration tests (Supertest)
    7. E2E tests (Playwright)"
      ↓
AI: [Generates complete solution]
    ✅ Complete with tests
```

### Example 3: MCP Integration

```
YOU: "Create a PRD in Notion and link Figma designs"
      ↓
AI: [Superpowers activates]
    "What's the feature for?"
      ↓
YOU: "Mobile app for site monitoring"
      ↓
AI: [Detects: "Notion" keyword]
    [Activates: Notion MCP]
    [Detects: "Figma" keyword]
    [Activates: Figma MCP]

    "Creating PRD in Notion...
    ✅ PRD created: https://notion.so/mobile-app-prd

    Fetching Figma designs...
    ✅ Found 3 design files
    ✅ Linked to PRD

    Complete!"
```

---

## 🎯 Summary

### You DON'T Need To:
- ❌ Know which skill to use
- ❌ Manually activate skills
- ❌ Remember skill names
- ❌ Load skills explicitly
- ❌ Configure anything

### Just:
- ✅ Ask your question
- ✅ Answer AI's clarifying questions
- ✅ Get complete solution

### AI Automatically:
- ✅ Activates Superpowers Brainstorming
- ✅ Detects relevant skills
- ✅ Loads knowledge bases
- ✅ Follows patterns
- ✅ Generates code/tests/docs
- ✅ Uses MCP servers when needed

---

## 🚀 Try It Now

After installation, just ask:

```
"Create a user profile page"
"Debug this MQTT connection"
"Write tests for this service"
"Create a PRD for the new feature"
"Update the GitHub PR with my changes"
```

**AI will handle everything automatically!** 🎉
