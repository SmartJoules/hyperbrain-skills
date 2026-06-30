# AI-SDLC Skills Library - Installation Guide

**Quick installation for Claude Code, Cursor, Copilot, and other AI coding assistants**

---

## 🚀 Quick Install

### Option 1: Automatic Installation (Recommended)

```bash
# Clone and run installer
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills
cd /tmp/hyperbrain-skills
./install.sh

# Skills are now active! Restart your AI assistant.
```

### Option 2: Manual Installation

Each skill is a directory containing a `SKILL.md`, and Claude Code expects every
skill as its own folder under `~/.claude/skills/`. Do **not** clone the repo
directly into `~/.claude/skills` — that nests everything one level too deep and
adds the repo's top-level docs and `.git`. Instead, clone elsewhere and copy each
skill directory:

```bash
# Clone the repo to a temp location
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills

# Copy every skill (each dir containing a SKILL.md) into ~/.claude/skills/
mkdir -p ~/.claude/skills
find /tmp/hyperbrain-skills -name SKILL.md -not -path '*/.git/*' | while read -r f; do
  d="$(dirname "$f")"
  cp -r "$d" ~/.claude/skills/"$(basename "$d")"
done

# Restart Claude Code — skills are automatically active
```

---

## 📋 Supported AI Assistants

### Claude Code (Default)
```bash
./install.sh --assistant claude
```
**Install Location:** `~/.claude/skills/`

### Cursor AI
```bash
./install.sh --assistant cursor
```
**Install Location:** `~/.cursor/skills/`

### GitHub Copilot
```bash
./install.sh --assistant copilot
```
**Install Location:** `~/.copilot/skills/`

### OpenAI Codex
```bash
./install.sh --assistant codex
```
**Install Location:** `~/.codex/skills/`

---

## 🔧 Advanced Options

### Custom Installation Directory
```bash
./install.sh --dir ~/my-custom-skills
```

### Skip Backup
```bash
./install.sh --skip-backup
```

### Full Help
```bash
./install.sh --help
```

---

## ✅ Verification

### Check Installation

```bash
# Run activation helper
~/.claude/activate-skills.sh

# Or manually check
ls -la ~/.claude/skills/
```

### Expected Output
```
AI-SDLC Skills Library Status:
================================

✓ Skills directory exists

Installed Skills:
  superpowers-brainstorming  ✓
  tdd-workflow              ✓
  angular-patterns          ✓
  react-patterns            ✓
  vue-patterns              ✓
  nextjs-patterns           ✓
  state-management          ✓
  nodejs-patterns           ✓
  python-patterns           ✓
  go-patterns               ✓
  database-patterns         ✓
  mqtt-patterns             ✓
  kafka-patterns            ✓
  influxdb-patterns         ✓
  iot-architecture          ✓
```

---

## 🎯 Usage

### Activate AI Superpowers

**Just ask any question!** The brainstorming skill activates automatically.

```bash
# Example questions that trigger AI Superpowers:
"Add user authentication to my app"
"Create a REST API for user management"
"Build a real-time dashboard with charts"
"Design an IoT data pipeline"
"Optimize database queries"
```

### What Happens

1. **AI Superpowers activates** automatically
2. **Asks clarifying questions** to understand requirements
3. **Presents multiple approaches** for your consideration
4. **Creates detailed plan** once you select an approach
5. **Implements using technical skills** (Angular, React, Node.js, etc.)

---

## 🔄 Update Skills

```bash
# Pull latest changes
cd ~/.claude/skills
git pull origin main

# Or re-run installer
cd /tmp
git clone https://github.com/SmartJoules/hyperbrain-skills.git
cd hyperbrain-skills
./install.sh --skip-backup
```

---

## 🗑️ Uninstall

```bash
# Remove skills directory
rm -rf ~/.claude/skills

# Or keep backup
mv ~/.claude/skills ~/.claude/skills.old
```

---

## 📚 Documentation

- **Full Documentation:** https://github.com/SmartJoules/hyperbrain-skills
- **Skills Index:** See individual SKILL.md files
- **Examples:** Check README.md for workflow examples

---

## 🆘 Troubleshooting

### Skills Not Appearing

1. **Restart AI Assistant**
   ```bash
   # Fully restart Claude Code/Cursor/Copilot
   ```

2. **Check Installation Directory**
   ```bash
   ls -la ~/.claude/skills/
   ```

3. **Verify File Permissions**
   ```bash
   chmod -R 755 ~/.claude/skills/
   ```

4. **Clear AI Assistant Cache**
   ```bash
   # Claude Code
   rm -rf ~/.claude/cache/

   # Cursor
   rm -rf ~/.cursor/cache/

   # Copilot
   rm -rf ~/.copilot/cache/
   ```

### Conflicting Skills

If you have existing skills:
```bash
# Backup first
cp -r ~/.claude/skills ~/.claude/skills.backup

# Reinstall
./install.sh
```

---

## 🎓 Getting Started

After installation:

1. **Restart your AI assistant**
2. **Ask any question** - e.g., "Create a user login feature"
3. **AI will automatically:**
   - Ask clarifying questions
   - Present multiple approaches
   - Create detailed plan
   - Implement using best practices

### Example Session

```
You: "Add user authentication to my Angular app"

AI: "Let me understand your authentication needs:
     1. What authentication methods? (Email/password, OAuth, SAML?)
     2. Any social logins needed? (Google, GitHub?)
     3. Role-based permissions required?
     4. Any compliance requirements? (GDPR, HIPAA?)
     5. Session management preferences?

You: "Email/password with JWT, role-based access"

AI: "Perfect! I see 3 approaches:
     Option 1: Angular + JWT interceptors (Simple, fast)
     Option 2: Angular + Auth0 library (Feature-rich, managed)
     Option 3: Custom auth service (Maximum control, more work)

     Which approach interests you?"

You: "Option 1"

AI: "Great! Here's the implementation plan:
     Phase 1: Auth Service (login, logout, token refresh)
     Phase 2: Route Guards (protected routes)
     Phase 3: JWT Interceptor (attach tokens to API calls)
     Phase 4: Role-based directives (UI access control)

     Ready to start with Phase 1?"
```

---

## 📞 Support

- **Issues:** https://github.com/SmartJoules/hyperbrain-skills/issues
- **Discussions:** https://github.com/SmartJoules/hyperbrain-skills/discussions
- **Email:** atif8486@gmail.com

---

**Happy coding with AI Superpowers! 🚀**
