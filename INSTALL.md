# AI-SDLC Skills Library - Installation Guide

**Quick installation for Claude Code, Cursor, Copilot, and other AI coding assistants**

---

## 🚀 Quick Install

### Option 1: Automatic Installation (Recommended)

```bash
# Clone and run installer
git clone https://github.com/SmartJoules/hyperbrain-skills.git hyperbrain-skills
cd hyperbrain-skills
./install.sh

# Skills are now active! Restart your AI assistant.
```

### Option 2: Manual Installation

Each skill is a directory containing a `SKILL.md`, and Claude Code expects every
skill as its own folder under the assistant skills directory. Do **not** clone the repo
directly into that directory — that nests everything one level too deep and
adds the repo's top-level docs and `.git`. Instead, clone elsewhere and copy each
skill directory:

```bash
# Run from the hyperbrain-skills repo root.
: "${ASSISTANT_SKILLS_DIR:?Set ASSISTANT_SKILLS_DIR first}"
mkdir -p "$ASSISTANT_SKILLS_DIR"
find . -name SKILL.md -not -path '*/.git/*' | while read -r f; do
  d="$(dirname "$f")"
  cp -R "$d" "$ASSISTANT_SKILLS_DIR/$(basename "$d")"
done

# Restart Claude Code — skills are automatically active
```

---

## 📋 Supported AI Assistants

### Claude Code (Default)
```bash
./install.sh --assistant claude
```
**Install Location:** assistant default skills directory

### Pi (pi.dev)
```bash
./install.sh --assistant pi
```
**Install Location:** Pi default skills directory

> Pi uses the **same skill format as Claude Code** — a `SKILL.md` per directory with
> `name` + `description` frontmatter — and discovers directories containing `SKILL.md`
> under Pi's default skills directory. So every hyperbrain skill works in Pi unchanged. Skills
> load automatically (Pi lists available skills in its system prompt) or on demand via
> `/skill:<name>`. Any skill that ships a `bin/` CLI or slash commands is installed
> by the installer for the selected assistant.

### Cursor AI
```bash
./install.sh --assistant cursor
```
**Install Location:** Cursor default skills directory

### GitHub Copilot
```bash
./install.sh --assistant copilot
```
**Install Location:** Copilot default skills directory

### OpenAI Codex
```bash
./install.sh --assistant codex
```
**Install Location:** Codex default skills directory

> **How Codex / Cursor / Copilot use these skills.** These agents have no native
> `SKILL.md` registry (that auto-activation is Claude-Code-specific). The installer
> therefore puts the skills under `skills/<name>/SKILL.md` **and generates an
> `AGENTS.md`** index next to them. `AGENTS.md` lists every skill with its
> description and bakes in the mandatory engineering standards. To use it:
>
> - **Codex** auto-reads an `AGENTS.md` from the working directory — copy the
>   generated `AGENTS.md` from the Codex skills install into your repo root, or point Codex at it.
> - The agent opens the matching `skills/<name>/SKILL.md` for the task at hand.
> - `engineering-standards` applies to every change.
>
> So the *content* is fully reusable by Codex; only the automatic per-task
> activation that Claude Code does is replaced by the `AGENTS.md` index.

---

## 🔧 Advanced Options

### Custom Installation Directory
```bash
./install.sh --dir ./my-custom-skills
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
# Run from the hyperbrain-skills repo root.
./install.sh --assistant claude
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
git pull origin main

# Or re-run installer
./install.sh --skip-backup
```

---

## 🗑️ Uninstall

```bash
# Remove skills directory
: "${ASSISTANT_SKILLS_DIR:?Set ASSISTANT_SKILLS_DIR first}"
rm -rf "$ASSISTANT_SKILLS_DIR"

# Or keep backup
mv "$ASSISTANT_SKILLS_DIR" "${ASSISTANT_SKILLS_DIR}.old"
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
   : "${ASSISTANT_SKILLS_DIR:?Set ASSISTANT_SKILLS_DIR first}"
   ls -la "$ASSISTANT_SKILLS_DIR"
   ```

3. **Verify File Permissions**
   ```bash
   : "${ASSISTANT_SKILLS_DIR:?Set ASSISTANT_SKILLS_DIR first}"
   chmod -R 755 "$ASSISTANT_SKILLS_DIR"
   ```

4. **Clear AI Assistant Cache**
   Use the assistant's own cache-clear or restart flow.

### Conflicting Skills

If you have existing skills:
```bash
# Backup first
: "${ASSISTANT_SKILLS_DIR:?Set ASSISTANT_SKILLS_DIR first}"
cp -R "$ASSISTANT_SKILLS_DIR" "${ASSISTANT_SKILLS_DIR}.backup"

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
