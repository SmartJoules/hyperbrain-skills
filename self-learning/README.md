# Self-Learning & Context Improvement - Quick Reference

**Part of HyperBrain Skills Library**

**Purpose:** Continuously improve AI capabilities through user context and learning

**Version:** 1.0.0
**Last Updated:** 2026-05-04

---

## 🎯 Overview

HyperBrain continuously learns from your interactions, adapts to your preferences, and personalizes responses to match your coding style and patterns.

---

## 🧠 How It Works

### Learning Pipeline

```
Interaction → Capture Context → Store → Analyze → Improve → Apply
```

### What It Learns

- **Coding Preferences:** Patterns, frameworks, conventions
- **Project Context:** Structure, team practices, deployment
- **Successful Patterns:** What works well for you
- **User Feedback:** Corrections, preferences, satisfaction
- **Domain Knowledge:** Terminology, APIs, schemas

---

## 📚 Storage Locations

All data stored locally in `~/.claude/memory/`:

```
~/.claude/memory/
├── user-context.json         # Your profile and preferences
├── interactions.jsonl         # Interaction history (append-only)
├── patterns.json             # Learned patterns
└── learning-metrics.json    # Improvement metrics
```

---

## 🎯 Personalization Levels

### Level 1: Basic (First 100 interactions)
- Your name, role, expertise
- Preferred languages/frameworks
- Basic coding style

### Level 2: Pattern (100-500 interactions)
- Preferred architectural patterns
- Testing approach
- Documentation style

### Level 3: Context (500-1000 interactions)
- Project structure and conventions
- Team practices
- Domain terminology

### Level 4: Predictive (1000+ interactions)
- Workflow patterns
- Proactive suggestions
- Time-based optimization

---

## 💡 Example: Adaptive Learning

### Before Learning

```
AI: "I'll create a basic component for you"
```

### After Learning (Your Context)

```
AI: "Based on your preferred Container/Presenter pattern and TDD workflow,
I'll create:
1. DeviceMonitoringContainer (logic, state)
2. DeviceMonitoringComponent (UI presentation)
3. DeviceMonitoringService (API via Facade)
4. Tests first (TDD Red-Green-Refactor)
5. 80%+ coverage target"
```

---

## 🔒 Privacy & Control

### Privacy Features
- ✅ All data stored locally (never leaves your machine)
- ✅ No cloud sync or sharing
- ✅ Encrypted at rest
- ✅ Automatic data retention (90 days for interactions)
- ✅ Full user control

### Opt-Out
```typescript
// Disable learning anytime
AI: "Disable learning for this session"
```

---

## ⚙️ Configuration

### Enable/Disable Learning

**In ~/.claude/settings.json:**
```json
{
  "learning": {
    "enabled": true,
    "storage_location": "~/.claude/memory",
    "retention_days": 90,
    "anonymize_data": true
  }
}
```

---

## 📈 Improvement Metrics

HyperBrain tracks:
- **Total Interactions:** How many times you've used it
- **Successful Patterns:** What works well
- **User Satisfaction:** Feedback-based scoring
- **Pattern Adoption:** How often patterns are reused
- **Learning Velocity:** New patterns learned per week

---

## 🎯 Benefits

### 1. Personalized Responses
- Matches your coding style
- Uses your preferred patterns
- Follows your conventions

### 2. Continuous Improvement
- Gets smarter with every interaction
- Adapts to changes in your style
- Learns new patterns automatically

### 3. Context Awareness
- Understands your projects
- Knows your team practices
- Remembers your preferences

### 4. Proactive Assistance
- Suggests optimal approaches
- Anticipates your needs
- Recommends patterns

---

## 📚 Integration

Works seamlessly with:
- **superpowers-brainstorming** - Applies learning to planning
- **expert-personas** - Personalizes persona responses
- **ui-ux-design** - Adapts to your design preferences
- **tdd-workflow** - Learns your testing style
- **all skills** - Improves all skill responses

---

**The more you use HyperBrain, the more personalized it becomes!** 🚀
