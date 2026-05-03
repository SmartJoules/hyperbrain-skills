# JouleTRACK Development Skills

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** Smart Joules
**Purpose:** Complete skill library for JouleTRACK development team
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## Overview

This repository contains the complete skill library for the JouleTRACK development team. These skills ensure all team members follow the same coding standards, patterns, and best practices when using Claude Code for development.

---

## 📚 Skills Included

### Core Skills

1. **JouleTRACK Library** (`jouletrack-library/`)
   - Master index and overview
   - Learning paths for different roles
   - Quick reference guide

2. **JouleTRACK Onboarding** (`jouletrack-onboarding/`)
   - Complete team setup and orientation
   - System architecture overview
   - Development environment setup
   - Data flow diagrams
   - Team workflows

3. **JouleTRACK Angular** (`jouletrack-angular/`)
   - Angular patterns matching @itsatif's coding style
   - Component patterns (from RapidPlantBuilderModule)
   - Service patterns (from ConfigService)
   - Observable handling patterns
   - PrimeNG + Material usage
   - Complete JSDoc documentation standards

4. **TDD Workflow** (`tdd-workflow/`)
   - Test-driven development process
   - Red-Green-Refactor cycle
   - Git checkpoint commits
   - Coverage requirements (80%+)
   - Testing patterns for Angular and Node.js

---

## 🎯 Key Features

### Automatic Pattern Enforcement
- ✅ ViewEncapsulation.None on all components
- ✅ JSDoc documentation with @description, @type, @param, @returns
- ✅ Explicit type annotations (never inferred)
- ✅ Observable$ naming convention
- ✅ combineLatest + switchMap patterns
- ✅ filter() after store.select()
- ✅ PrimeNG first, Material second
- ✅ All components declared in module

### Exact Code Style Match
All generated code matches @itsatif's coding style from:
- `RapidPlantBuilderModule` - Module structure
- `ConfigService` - Service patterns
- Component patterns with complete documentation

---

## 🚀 How to Use

### For Team Members

1. **Install the skills**
   ```bash
   # Clone this repository
   git clone https://github.com/smartjoules/jouletrack-skills.git ~/.claude/skills/
   ```

2. **Start using Claude Code**
   ```bash
   # The skills are automatically available
   # Just start coding!
   ```

3. **Example usage**
   ```bash
   # Onboarding new developer
   /jouletrack-onboarding

   # Create Angular component
   "Create a rapid plant builder component"

   # Use TDD
   "Implement chiller efficiency feature using TDD"
   ```

---

## 📋 Installation

### Option 1: Clone to Claude Skills Directory
```bash
# Clone directly to Claude skills
git clone https://github.com/smartjoules/jouletrack-skills.git ~/.claude/skills/

# Skills are immediately available in Claude Code
```

### Option 2: Manual Installation
```bash
# Clone to temporary location
git clone https://github.com/smartjoules/jouletrack-skills.git /tmp/jouletrack-skills

# Copy to Claude skills
cp -r /tmp/jouletrack-skills/* ~/.claude/skills/

# Skills are now available
```

---

## 🔧 Skill Structure

```
jouletrack-skills/
├── README.md                           # This file
├── jouletrack-library/
│   └── SKILL.md                        # Master index
├── jouletrack-onboarding/
│   └── SKILL.md                        # Team setup
├── jouletrack-angular/
│   └── SKILL.md                        # Angular patterns
└── tdd-workflow/
    └── SKILL.md                        # TDD process
```

---

## 📖 Documentation

### Internal Documentation
- `README.md` - Repository overview
- `jouletrack-library/SKILL.md` - Complete skill index
- `jouletrack-onboarding/SKILL.md` - Team setup guide
- `jouletrack-angular/SKILL.md` - Angular patterns
- `tdd-workflow/SKILL.md` - TDD process

### Related Documentation
- `AI_CONTEXT.md` - JouleTRACK system context
- `kiro_steering.md` - AI assistant rules
- `docs/ai/` - Module-specific AI context

---

## 🎓 Learning Paths

### Frontend Developer (1 Week)
1. **Day 1-2:** Complete onboarding (`/jouletrack-onboarding`)
2. **Day 3-4:** Learn Angular patterns (`/jouletrack-angular`)
3. **Day 5:** Learn TDD workflow (`/tdd-workflow`)
4. **Day 6-7:** Real project work with code reviews

### Backend Developer (1 Week)
Similar path with backend-specific skills (coming soon)

### IoT Developer (1 Week)
Similar path with IoT-specific skills (coming soon)

---

## ✅ Quality Standards

### Code Quality Checklist
- [ ] ViewEncapsulation.None set
- [ ] JSDoc documentation complete
- [ ] Explicit types declared
- [ ] Observable$ naming used
- [ ] PrimeNG components used
- [ ] Store integration with filter()
- [ ] TDD workflow followed
- [ ] 80%+ test coverage

### Code Review Standards
- [ ] Matches @itsatif's coding style
- [ ] No `any` types used
- [ ] Proper error handling
- [ ] Memory leak prevention
- [ ] Site context handling
- [ ] Documentation complete

---

## 🤝 Contributing

### Adding New Skills
1. Create skill directory following naming convention
2. Create SKILL.md with proper frontmatter
3. Update `jouletrack-library/SKILL.md` to include new skill
4. Submit pull request
5. Get review from itsatif and AbhilashSri

### Skill Template
```markdown
---
name: skill-name
description: Skill description
origin: Smart Joules
---

# Skill Title

## When to Use This Skill
[Describe when to activate]

## Core Principles
[List key principles]

## Implementation Patterns
[Show code examples]

## Quality Checklist
[What to check before completing]
```

---

## 📊 Benefits

### For Your Team
- **Consistency** - Everyone codes the same way
- **Quality** - Automatic pattern enforcement
- **Speed** - Faster development with proven patterns
- **Onboarding** - New developers productive in days
- **Code Reviews** - Automated checks before human review

### For Your Codebase
- **Maintainability** - Consistent patterns
- **Reliability** - Fewer bugs with TDD
- **Performance** - Best practices applied
- **Documentation** - Fully documented code

---

## 🔗 Links

- **JouleTRACK Repository:** [JouleTRACK GitHub](https://github.com/smartjoules/)
- **Internal Wiki:** [Smart Joules Wiki](https://wiki.smartjoules.org/)
- **Documentation:** [JouleTRACK Docs](https://docs.smartjoules.org/)

---

## 📞 Support

For questions or issues:
- Create an issue in this repository
- Contact itsatif for JouleTRACK-specific questions
- Check with team leads for process questions

---

## 📜 License

Copyright © 2026 Smart Joules. All rights reserved.

Internal use only - Not for distribution outside Smart Joules.

---

**Remember:** These skills ensure your entire team builds high-quality JouleTRACK software that follows proven patterns and best practices!
