# Self-Learning & Context Improvement System

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Continuously improve AI capabilities through user context and learning
**Version:** 1.0.0
**Last Updated:** 2026-05-04

---

## 🎯 When to Use This Skill

**Use AUTOMATICALLY for ALL interactions:**
- Capture user preferences and patterns
- Learn from successful interactions
- Adapt to user's coding style
- Improve context understanding
- Build personalized knowledge base

---

## 🧠 How Self-Learning Works

### Learning Pipeline

```
USER INTERACTION
    ↓
[CAPTURE CONTEXT]
• User preferences
• Code style choices
• Domain patterns
• Feedback patterns
    ↓
[STORE IN KNOWLEDGE BASE]
• User context file
• Interaction history
• Pattern library
    ↓
[ANALYZE & IMPROVE]
• Identify patterns
• Extract best practices
• Build custom rules
    ↓
[APPLY LEARNING]
• Personalized responses
• Adaptive suggestions
• Context-aware assistance
```

---

## 📚 Context Storage Structure

### User Context File

**Location:** `~/.claude/memory/user-context.json`

```json
{
  "user_profile": {
    "name": "Atif Salafi",
    "email": "atif8486@gmail.com",
    "organization": "DeJoule / Smart Joules",
    "role": "Software Architect",
    "expertise": ["Angular", "Node.js", "IoT", "System Design"],
    "experience_level": "Senior",
    "timezone": "Asia/Kolkata",
    "preferred_editor": "VS Code",
    "working_hours": {
      "start": "09:00",
      "end": "18:00",
      "days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
  },
  "coding_preferences": {
    "language": "TypeScript",
    "frameworks": {
      "frontend": "Angular",
      "backend": "Node.js/Express",
      "database": "PostgreSQL"
    },
    "patterns": {
      "angular": "Container/Presenter pattern",
      "api": "Layered architecture (Controller → Service → Repository)",
      "testing": "TDD with 80%+ coverage",
      "ui": "Mobile-first, single-page dashboards"
    },
    "conventions": {
      "naming": "camelCase for variables, PascalCase for classes",
      "file_structure": "feature-based modules",
      "commit_style": "conventional commits",
      "documentation": "JSDoc for all functions"
    },
    "anti_patterns": [
      "Avoid any in TypeScript files",
      "No console.log in production code",
      "No hardcoded values (use constants)",
      "No mutation (immutable patterns)"
    ]
  },
  "project_context": {
    "current_project": "JouleTRACK",
    "tech_stack": {
      "frontend": "Angular 17",
      "backend": "Node.js 20",
      "database": "PostgreSQL 15, InfluxDB 2.x",
      "iot": "MQTT, BACnet, Modbus"
    },
    "team_practices": {
      "code_review": "Required before merge",
      "ci_cd": "GitHub Actions",
      "testing": "80%+ coverage required",
      "documentation": "Required for all features"
    },
    "deployments": {
      "development": "Docker Compose",
      "staging": "Kubernetes (single node)",
      "production": "Kubernetes (multi-node)"
    }
  },
  "learned_patterns": {
    "successful_interactions": [],
    "user_feedback": [],
    "custom_solutions": [],
    "preferred_approaches": []
  }
}
```

### Interaction History

**Location:** `~/.claude/memory/interactions.jsonl`

```json
{
  "timestamp": "2026-05-04T10:30:00Z",
  "request": "Create a new Angular component for device monitoring",
  "approach_taken": "Container/Presenter pattern with TDD",
  "user_feedback": "positive",
  "success_metrics": {
    "code_generated": true,
    "tests_passed": true,
    "user_satisfied": true
  },
  "patterns_used": ["angular-container-presenter", "tdd-workflow"],
  "context": {
    "project": "JouleTRACK",
    "component_type": "monitoring-dashboard",
    "complexity": "high"
  }
}
```

### Pattern Library

**Location:** `~/.claude/memory/patterns.json`

```json
{
  "angular_patterns": {
    "component_structure": {
      "name": "Container/Presenter Pattern",
      "usage_count": 45,
      "success_rate": 0.95,
      "user_preference": "high",
      "last_used": "2026-05-04T10:30:00Z"
    },
    "state_management": {
      "name": "NgRx with Facade Pattern",
      "usage_count": 23,
      "success_rate": 0.92,
      "user_preference": "medium",
      "last_used": "2026-05-03T16:45:00Z"
    }
  },
  "backend_patterns": {
    "api_design": {
      "name": "Layered Architecture",
      "usage_count": 67,
      "success_rate": 0.98,
      "user_preference": "high",
      "last_used": "2026-05-04T09:15:00Z"
    }
  },
  "testing_patterns": {
    "tdd_approach": {
      "name": "Red-Green-Refactor",
      "usage_count": 89,
      "success_rate": 0.97,
      "user_preference": "high",
      "last_used": "2026-05-04T11:00:00Z"
    }
  }
}
```

---

## 🔄 Learning Mechanisms

### 1. Preference Learning

**What it learns:**
- User's preferred patterns
- Framework choices
- Code style preferences
- Documentation style
- Testing approach

**How it works:**
```typescript
// After each interaction
if (userFeedback === "positive") {
  patternUsage.successCount++;
  patternUsage.lastUsed = new Date().toISOString();
  
  if (patternUsage.successCount > 5) {
    // Promote to preferred pattern
    userPreferences.preferredPatterns.push(patternName);
  }
}
```

### 2. Context Learning

**What it learns:**
- Project structure
- Team conventions
- Domain terminology
- Deployment environments
- API endpoints and schemas

**How it works:**
```typescript
// Capture project context
function captureProjectContext(projectPath) {
  return {
    structure: analyzeDirectoryStructure(projectPath),
    dependencies: extractDependencies(packageJson),
    conventions: detectCodeConventions(sourceFiles),
    apis: discoverApiEndpoints(apiSpecs),
    database: analyzeDatabaseSchema(schemaFiles)
  };
}
```

### 3. Pattern Recognition

**What it learns:**
- Repeated user requests
- Successful solutions
- Common problems
- Optimal approaches

**How it works:**
```typescript
// Analyze interaction patterns
function analyzeInteractionPatterns(history) {
  const patterns = history
    .filter(h => h.success_metrics.user_satisfied)
    .groupBy(h => h.request_type)
    .map(group => ({
      type: group.request_type,
      successful_approaches: group.approach_taken,
      success_rate: calculateSuccessRate(group),
      avg_time_to_solution: calculateAvgTime(group)
    }));
  
  return patterns;
}
```

### 4. Feedback Integration

**What it learns:**
- What works well
- What doesn't work
- User's corrections
- Preferred alternatives

**How it works:**
```typescript
// Capture user feedback
function captureFeedback(request, response, userCorrection) {
  const feedback = {
    original_response: response,
    user_correction: userCorrection,
    timestamp: new Date().toISOString(),
    lesson: extractLesson(userCorrection)
  };
  
  // Update pattern library
  updatePatternLibrary(feedback);
  
  // Avoid same mistake in future
  storeNegativePattern(feedback);
}
```

---

## 🎯 Adaptive Behaviors

### 1. Adaptive Code Generation

**Before Learning:**
```typescript
// Generic approach
function generateComponent(featureName) {
  return `
@Component({
  selector: 'app-${featureName}',
  template: '<div></div>',
  styleUrls: ['./${featureName}.component.scss']
})
export class ${featureName}Component {}
  `;
}
```

**After Learning (User Context):**
```typescript
// Personalized approach
function generateComponent(featureName) {
  // Knows user prefers Container/Presenter pattern
  return `
// Container Component
@Component({
  selector: 'app-${featureName}-container',
  template: '<app-${featureName} [data]="data$"></app-${featureName}>',
  styleUrls: ['./${featureName}-container.component.scss']
})
export class ${featureName}Container {
  data$ = this.${featureName}Service.getData$();
}

// Presenter Component
@Component({
  selector: 'app-${featureName}',
  template: '<div>{{ data | async }}</div>',
  styleUrls: ['./${featureName}.component.scss']
})
export class ${featureName}Component {
  @Input() set data(value) { this.data$.next(value); }
}
  `;
}
```

### 2. Adaptive Suggestions

**Before Learning:**
```
AI: "I suggest creating a service class for data fetching"
```

**After Learning:**
```
AI: "Based on your preferred Container/Presenter pattern and TDD workflow,
I suggest:
1. Create Container component (logic)
2. Create Presenter component (UI)
3. Create Service (data fetching)
4. Write tests first (TDD)
5. Use Facade pattern for data access"
```

### 3. Adaptive Documentation

**Before Learning:**
```markdown
# Component Documentation

This component displays user data.
```

**After Learning:**
```markdown
# DeviceMonitoringComponent Documentation

**Pattern:** Container/Presenter
**Author:** Atif Salafi
**Last Modified:** 2026-05-04

## Overview
This component displays real-time device monitoring data using the Container/Presenter pattern.

## Architecture
- **Container:** DeviceMonitoringContainer (logic, state management)
- **Presenter:** DeviceMonitoringComponent (UI rendering)
- **Service:** DeviceMonitoringService (API calls via Facade)
- **Testing:** TDD with 80%+ coverage (Jasmine)

## Dependencies
- @dejoule/api-client (Facade layer)
- @dejoule/models (Device model)
- @dejoule/utils (Date formatting)

## Usage
```typescript
<app-device-monitoring-container [siteId]="'iah-del'">
</app-device-monitoring-container>
```
```

---

## 📊 Learning Metrics

### Tracking Metrics

```json
{
  "learning_metrics": {
    "total_interactions": 1250,
    "successful_patterns": {
      "angular_container_presenter": 45,
      "tdd_workflow": 89,
      "layered_architecture": 67
    },
    "user_satisfaction_rate": 0.94,
    "pattern_adoption_rate": 0.87,
    "context_accuracy": 0.91,
    "learning_velocity": "23 new patterns/week"
  }
}
```

### Improvement Indicators

```typescript
// Measure improvement over time
function measureImprovement(timeRange) {
  return {
    response_accuracy: calculateAccuracy(timeRange),
    user_satisfaction: calculateSatisfaction(timeRange),
    time_to_solution: calculateAvgTime(timeRange),
    pattern_reuse_rate: calculateReuseRate(timeRange),
    context_relevance: calculateContextRelevance(timeRange)
  };
}
```

---

## 🛠️ Implementation

### Memory Storage

```typescript
// Memory system interface
interface MemoryStorage {
  saveUserProfile(profile: UserProfile): void;
  getUserProfile(): UserProfile;
  saveInteraction(interaction: Interaction): void;
  getInteractions(limit?: number): Interaction[];
  savePattern(pattern: Pattern): void;
  getPatterns(type?: string): Pattern[];
  saveFeedback(feedback: Feedback): void;
  getFeedback(success?: boolean): Feedback[];
}

// File-based implementation
class FileMemoryStorage implements MemoryStorage {
  private memoryDir = `${process.env.HOME}/.claude/memory`;
  
  constructor() {
    this.ensureMemoryDirectory();
  }
  
  private ensureMemoryDirectory() {
    if (!fs.existsSync(this.memoryDir)) {
      fs.mkdirSync(this.memoryDir, { recursive: true });
    }
  }
  
  saveUserProfile(profile: UserProfile) {
    const filePath = `${this.memoryDir}/user-context.json`;
    fs.writeFileSync(filePath, JSON.stringify(profile, null, 2));
  }
  
  getUserProfile(): UserProfile {
    const filePath = `${this.memoryDir}/user-context.json`;
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    }
    return this.getDefaultProfile();
  }
  
  saveInteraction(interaction: Interaction) {
    const filePath = `${this.memoryDir}/interactions.jsonl`;
    const line = JSON.stringify(interaction);
    fs.appendFileSync(filePath, line + '\n');
  }
  
  getInteractions(limit: number = 100): Interaction[] {
    const filePath = `${this.memoryDir}/interactions.jsonl`;
    if (!fs.existsSync(filePath)) return [];
    
    const lines = fs.readFileSync(filePath, 'utf-8').split('\n').filter(Boolean);
    return lines
      .slice(-limit)
      .map(line => JSON.parse(line))
      .reverse(); // Most recent first
  }
  
  savePattern(pattern: Pattern) {
    const filePath = `${this.memoryDir}/patterns.json`;
    const patterns = this.getPatterns();
    patterns[pattern.id] = pattern;
    fs.writeFileSync(filePath, JSON.stringify(patterns, null, 2));
  }
  
  getPatterns(type?: string): Pattern[] {
    const filePath = `${this.memoryDir}/patterns.json`;
    if (!fs.existsSync(filePath)) return [];
    
    const allPatterns = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    if (type) {
      return Object.values(allPatterns).filter(p => p.type === type);
    }
    return Object.values(allPatterns);
  }
  
  private getDefaultProfile(): UserProfile {
    return {
      name: "User",
      expertise: [],
      coding_preferences: {
        language: "TypeScript",
        frameworks: {},
        patterns: {},
        conventions: {},
        anti_patterns: []
      },
      learned_patterns: {
        successful_interactions: [],
        user_feedback: [],
        custom_solutions: [],
        preferred_approaches: []
      }
    };
  }
}
```

### Learning Engine

```typescript
// Learning engine
class LearningEngine {
  private storage: MemoryStorage;
  
  constructor(storage: MemoryStorage) {
    this.storage = storage;
  }
  
  // Learn from interaction
  learn(interaction: Interaction) {
    // Store interaction
    this.storage.saveInteraction(interaction);
    
    // Update patterns if successful
    if (interaction.success_metrics.user_satisfied) {
      this.updatePatterns(interaction);
    }
    
    // Extract preferences
    this.extractPreferences(interaction);
    
    // Improve context
    this.improveContext(interaction);
  }
  
  // Update pattern library
  private updatePatterns(interaction: Interaction) {
    interaction.patterns_used.forEach(pattern => {
      const existing = this.storage.getPatterns(pattern.type);
      const patternData = existing.find(p => p.name === pattern.name);
      
      if (patternData) {
        patternData.usage_count++;
        patternData.last_used = new Date().toISOString();
      } else {
        this.storage.savePattern({
          id: generateId(),
          name: pattern.name,
          type: pattern.type,
          usage_count: 1,
          success_rate: 1.0,
          user_preference: 'medium',
          last_used: new Date().toISOString()
        });
      }
    });
  }
  
  // Extract user preferences
  private extractPreferences(interaction: Interaction) {
    const profile = this.storage.getUserProfile();
    
    // Detect patterns in user's choices
    if (interaction.user_feedback === "positive") {
      interaction.patterns_used.forEach(pattern => {
        if (!profile.learned_patterns.preferred_approaches.includes(pattern.name)) {
          profile.learned_patterns.preferred_approaches.push(pattern.name);
        }
      });
    }
    
    this.storage.saveUserProfile(profile);
  }
  
  // Improve context understanding
  private improveContext(interaction: Interaction) {
    const profile = this.storage.getUserProfile();
    
    // Update project context
    if (interaction.context.project) {
      profile.project_context.current_project = interaction.context.project;
      profile.project_context.tech_stack = interaction.context.tech_stack;
    }
    
    this.storage.saveUserProfile(profile);
  }
  
  // Get personalized recommendations
  getRecommendations(request: string): Recommendation[] {
    const profile = this.storage.getUserProfile();
    const patterns = this.storage.getPatterns();
    const history = this.storage.getInteractions(50);
    
    // Analyze similar past requests
    const similarInteractions = history.filter(h => 
      h.request.toLowerCase().includes(request.toLowerCase().split(' ')[0])
    );
    
    // Generate recommendations
    return [
      ...this.getRecommendedPatterns(patterns, profile),
      ...this.getRecommendedApproaches(similarInteractions),
      ...this.getPreferredConventions(profile)
    ];
  }
  
  private getRecommendedPatterns(patterns: Pattern[], profile: UserProfile): Recommendation[] {
    return Object.values(patterns)
      .filter(p => p.success_rate > 0.8)
      .filter(p => profile.learned_patterns.preferred_approaches.includes(p.name))
      .slice(0, 5)
      .map(p => ({
        type: 'pattern',
        name: p.name,
        confidence: p.success_rate,
        reason: `High success rate (${p.success_rate}) and user preferred`
      }));
  }
  
  private getRecommendedApproaches(interactions: Interaction[]): Recommendation[] {
    const successfulApproaches = interactions
      .filter(i => i.success_metrics.user_satisfied)
      .map(i => i.approach_taken)
      .reduce((acc, approach) => {
        acc[approach] = (acc[approach] || 0) + 1;
        return acc;
      }, {} as Record<string, number>);
    
    return Object.entries(successfulApproaches)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 3)
      .map(([approach, count]) => ({
        type: 'approach',
        name: approach,
        confidence: count / interactions.length,
        reason: `Used successfully ${count} times`
      }));
  }
  
  private getPreferredConventions(profile: UserProfile): Recommendation[] {
    return [
      {
        type: 'convention',
        name: 'Container/Presenter Pattern',
        confidence: 0.95,
        reason: 'User preference detected'
      },
      {
        type: 'convention',
        name: 'TDD Workflow',
        confidence: 0.97,
        reason: 'User preference detected'
      },
      {
        type: 'convention',
        name: 'Mobile-First UI',
        confidence: 0.92,
        reason: 'User preference detected'
      }
    ];
  }
}
```

---

## 🎯 Continuous Improvement

### Daily Learning Cycle

```typescript
// Run daily to analyze and improve
function dailyLearningCycle() {
  const storage = new FileMemoryStorage();
  const engine = new LearningEngine(storage);
  
  // Get yesterday's interactions
  const yesterday = getYesterdayDate();
  const interactions = getInteractionsByDate(yesterday);
  
  // Analyze patterns
  const insights = analyzeInteractions(interactions);
  
  // Update patterns
  insights.successfulPatterns.forEach(pattern => {
    engine.storage.savePattern(pattern);
  });
  
  // Update user profile
  const profile = engine.storage.getUserProfile();
  profile.learning_metrics = insights.metrics;
  engine.storage.saveUserProfile(profile);
  
  // Generate improvement report
  generateImprovementReport(insights);
}
```

### Weekly Pattern Optimization

```typescript
// Run weekly to optimize patterns
function weeklyPatternOptimization() {
  const storage = new FileMemoryStorage();
  const patterns = storage.getPatterns();
  
  // Identify underperforming patterns
  const underperforming = patterns.filter(p => p.success_rate < 0.7);
  
  // Retire or update patterns
  underperforming.forEach(pattern => {
    if (pattern.usage_count < 5) {
      // Not enough data, keep trying
      pattern.status = 'experimental';
    } else {
      // Consistently underperforming, retire
      pattern.status = 'retired';
    }
    storage.savePattern(pattern);
  });
  
  // Promote high-performing patterns
  const highPerforming = patterns.filter(p => 
    p.success_rate > 0.9 && p.usage_count > 10
  );
  
  highPerforming.forEach(pattern => {
    pattern.status = 'recommended';
    storage.savePattern(pattern);
  });
}
```

---

## 📈 Personalization Levels

### Level 1: Basic Learning (First 100 interactions)

**Learns:**
- User's name and role
- Preferred programming languages
- Basic coding style preferences
- Common frameworks used

**Output:**
- Personalized greetings
- Language-specific syntax
- Framework-aware suggestions

### Level 2: Pattern Learning (100-500 interactions)

**Learns:**
- Preferred architectural patterns
- Testing approach
- Documentation style
- Code organization preferences

**Output:**
- Pattern-specific implementations
- Adaptive code generation
- Consistent with user's style

### Level 3: Context Learning (500-1000 interactions)

**Learns:**
- Project structure and conventions
- Team practices
- Domain terminology
- API endpoints and schemas
- Deployment environments

**Output:**
- Context-aware suggestions
- Domain-specific knowledge
- Project-specific patterns

### Level 4: Predictive Learning (1000+ interactions)

**Learns:**
- User's workflow patterns
- Common problems and solutions
- Optimal approaches for specific tasks
- Time-based patterns (morning vs evening work)

**Output:**
- Proactive suggestions
- Anticipatory assistance
- Workflow optimization
- Time-aware recommendations

---

## ✅ Learning Quality Assurance

### Privacy Controls

```json
{
  "privacy": {
    "data_retention": {
      "interactions": "90 days",
      "patterns": "indefinitely",
      "user_profile": "indefinitely"
    },
    "data_anonymization": {
      "enabled": true,
      "strip_pii": true,
      "hash_identifiers": true
    },
    "user_control": {
      "can_export": true,
      "can_delete": true,
      "can_opt_out": true
    }
  }
}
```

### Learning Validation

```typescript
// Validate learning quality
function validateLearning(learning: Learning): boolean {
  // Check if learning is accurate
  if (learning.confidence < 0.7) return false;
  
  // Check if learning is relevant
  const timeSinceLastUse = Date.now() - new Date(learning.last_used).getTime();
  if (timeSinceLastUse > 90 * 24 * 60 * 60 * 1000) return false; // 90 days
  
  // Check if learning has been validated
  if (learning.validation_count < 3) return false;
  
  return true;
}
```

---

## 🔒 Privacy & Security

### Data Protection

- **Local Storage:** All data stored locally on user's machine
- **No Cloud Sync:** Learning data never leaves local system
- **Encryption:** Sensitive data encrypted at rest
- **User Control:** Full control over what's stored

### Opt-Out Mechanism

```typescript
// User can opt-out of learning
function optOutOfLearning() {
  const profile = storage.getUserProfile();
  profile.privacy.learning_enabled = false;
  storage.saveUserProfile(profile);
}

// Check if learning is enabled
function isLearningEnabled(): boolean {
  const profile = storage.getUserProfile();
  return profile.privacy.learning_enabled !== false;
}
```

---

## 📚 Integration with Other Skills

- **superpowers-brainstorming** - Initial planning with learned context
- **expert-personas** - Apply learning to persona responses
- **ui-ux-design** - Learn user's design preferences
- **tdd-workflow** - Adapt TDD approach based on feedback
- **jouletrack-angular** - Learn Angular patterns user prefers
- **backend-knowledge-base** - Learn backend patterns user uses

---

## 🎯 Summary

**Self-Learning System:**
- ✅ Captures user context automatically
- ✅ Learns from every interaction
- ✅ Adapts to user's preferences
- ✅ Improves over time
- ✅ Personalizes all responses
- ✅ Privacy-focused (local storage)
- ✅ User control (opt-out anytime)

**The more you use it, the smarter it gets!** 🧠
