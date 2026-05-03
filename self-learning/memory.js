#!/usr/bin/env node

/**
 * Memory System for HyperBrain Self-Learning
 *
 * This script manages the learning memory system:
 * - Creates memory directory structure
 * - Initializes storage files
 * - Provides CLI for memory management
 */

const fs = require('fs');
const path = require('path');

const MEMORY_DIR = `${process.env.HOME}/.claude/memory`;
const USER_CONTEXT_FILE = `${MEMORY_DIR}/user-context.json`;
const INTERACTIONS_FILE = `${MEMORY_DIR}/interactions.jsonl`;
const PATTERNS_FILE = `${MEMORY_DIR}/patterns.json`;
const METRICS_FILE = `${MEMORY_DIR}/learning-metrics.json`;

// Colors for output
const GREEN = '\x1b[32m';
const BLUE = '\x1b[34m';
const YELLOW = '\x1b[33m';
const RED = '\x1b[31m';
const NC = '\x1b[0m';

/**
 * Create memory directory structure
 */
function initializeMemory() {
  console.log(`${BLUE}📁 Initializing HyperBrain memory system...${NC}`);

  if (!fs.existsSync(MEMORY_DIR)) {
    fs.mkdirSync(MEMORY_DIR, { recursive: true });
    console.log(`${GREEN}✅ Created memory directory: ${MEMORY_DIR}${NC}`);
  } else {
    console.log(`${YELLOW}⚠️  Memory directory already exists${NC}`);
  }

  // Initialize user context
  if (!fs.existsSync(USER_CONTEXT_FILE)) {
    const defaultContext = {
      user_profile: {
        name: "User",
        email: "",
        organization: "",
        role: "",
        expertise: [],
        experience_level: "",
        timezone: "",
        preferred_editor: "",
        working_hours: {
          start: "09:00",
          end: "18:00",
          days: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        }
      },
      coding_preferences: {
        language: "TypeScript",
        frameworks: {},
        patterns: {},
        conventions: {},
        anti_patterns: []
      },
      project_context: {
        current_project: "",
        tech_stack: {},
        team_practices: {},
        deployments: {}
      },
      learned_patterns: {
        successful_interactions: [],
        user_feedback: [],
        custom_solutions: [],
        preferred_approaches: []
      },
      privacy: {
        learning_enabled: true,
        data_retention_days: 90,
        anonymize_data: true
      },
      learning_metrics: {
        total_interactions: 0,
        successful_patterns: {},
        user_satisfaction_rate: 0.0,
        pattern_adoption_rate: 0.0,
        context_accuracy: 0.0,
        learning_velocity: 0,
        created_at: new Date().toISOString(),
        last_updated: new Date().toISOString()
      }
    };

    fs.writeFileSync(USER_CONTEXT_FILE, JSON.stringify(defaultContext, null, 2));
    console.log(`${GREEN}✅ Created user context file${NC}`);
  }

  // Initialize interactions file
  if (!fs.existsSync(INTERACTIONS_FILE)) {
    fs.writeFileSync(INTERACTIONS_FILE, '');
    console.log(`${GREEN}✅ Created interactions file${NC}`);
  }

  // Initialize patterns file
  if (!fs.existsSync(PATTERNS_FILE)) {
    const defaultPatterns = {
      angular_patterns: {},
      backend_patterns: {},
      testing_patterns: {},
      ui_patterns: {}
    };
    fs.writeFileSync(PATTERNS_FILE, JSON.stringify(defaultPatterns, null, 2));
    console.log(`${GREEN}✅ Created patterns file${NC}`);
  }

  // Initialize metrics file
  if (!fs.existsSync(METRICS_FILE)) {
    const defaultMetrics = {
      total_interactions: 0,
      successful_patterns: {},
      user_satisfaction_rate: 0.0,
      pattern_adoption_rate: 0.0,
      context_accuracy: 0.0,
      learning_velocity: 0,
      created_at: new Date().toISOString(),
      last_updated: new Date().toISOString()
    };
    fs.writeFileSync(METRICS_FILE, JSON.stringify(defaultMetrics, null, 2));
    console.log(`${GREEN}✅ Created metrics file${NC}`);
  }

  console.log(`${GREEN}✅ Memory system initialized successfully!${NC}`);
}

/**
 * Show memory statistics
 */
function showStats() {
  console.log(`${BLUE}📊 HyperBrain Learning Statistics${NC}\n`);

  if (!fs.existsSync(USER_CONTEXT_FILE)) {
    console.log(`${RED}❌ Memory system not initialized. Run 'init' first.${NC}`);
    return;
  }

  const context = JSON.parse(fs.readFileSync(USER_CONTEXT_FILE, 'utf-8'));
  const metrics = context.learning_metrics || JSON.parse(fs.readFileSync(METRICS_FILE, 'utf-8'));

  // User Profile
  console.log(`${YELLOW}👤 User Profile:${NC}`);
  console.log(`   Name: ${context.user_profile.name}`);
  console.log(`   Role: ${context.user_profile.role}`);
  console.log(`   Expertise: ${context.user_profile.expertise.join(', ') || 'Not specified'}`);
  console.log(`   Learning Enabled: ${context.privacy.learning_enabled ? '✅ Yes' : '❌ No'}`);

  // Learning Metrics
  console.log(`\n${YELLOW}📈 Learning Metrics:${NC}`);
  console.log(`   Total Interactions: ${metrics.total_interactions}`);
  console.log(`   User Satisfaction Rate: ${(metrics.user_satisfaction_rate * 100).toFixed(1)}%`);
  console.log(`   Pattern Adoption Rate: ${(metrics.pattern_adoption_rate * 100).toFixed(1)}%`);
  console.log(`   Learning Velocity: ${metrics.learning_velocity} patterns/week`);

  // Preferred Patterns
  const preferredPatterns = context.learned_patterns.preferred_approaches || [];
  console.log(`\n${YELLOW}⭐ Preferred Patterns (${preferredPatterns.length}):${NC}`);
  preferredPatterns.slice(0, 10).forEach(pattern => {
    console.log(`   • ${pattern}`);
  });

  // Recent Interactions
  if (fs.existsSync(INTERACTIONS_FILE)) {
    const interactions = fs.readFileSync(INTERACTIONS_FILE, 'utf-8').split('\n').filter(Boolean);
    const recentInteractions = interactions.slice(-5).reverse().map(line => JSON.parse(line));

    console.log(`\n${YELLOW}📝 Recent Interactions (${recentInteractions.length}):${NC}`);
    recentInteractions.forEach((interaction, index) => {
      const timestamp = new Date(interaction.timestamp).toLocaleString();
      const satisfaction = interaction.success_metrics.user_satisfied ? '✅' : '❌';
      console.log(`   ${index + 1}. ${satisfaction} ${interaction.request.substring(0, 60)}...`);
      console.log(`      ${timestamp}`);
    });
  }
}

/**
 * Export memory data
 */
function exportMemory(outputPath) {
  console.log(`${BLUE}📦 Exporting HyperBrain memory...${NC}`);

  if (!fs.existsSync(USER_CONTEXT_FILE)) {
    console.log(`${RED}❌ Memory system not initialized. Run 'init' first.${NC}`);
    return;
  }

  const exportData = {
    user_context: JSON.parse(fs.readFileSync(USER_CONTEXT_FILE, 'utf-8')),
    patterns: JSON.parse(fs.readFileSync(PATTERNS_FILE, 'utf-8')),
    metrics: JSON.parse(fs.readFileSync(METRICS_FILE, 'utf-8')),
    exported_at: new Date().toISOString()
  };

  const outputPathResolved = outputPath || path.join(process.env.HOME, 'hyperbrain-memory-export.json');
  fs.writeFileSync(outputPathResolved, JSON.stringify(exportData, null, 2));

  console.log(`${GREEN}✅ Memory exported to: ${outputPathResolved}${NC}`);
}

/**
 * Clear interaction history
 */
function clearInteractions(olderThanDays) {
  console.log(`${BLUE}🗑️  Clearing interaction history...${NC}`);

  if (!fs.existsSync(INTERACTIONS_FILE)) {
    console.log(`${RED}❌ No interaction history found.${NC}`);
    return;
  }

  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

  const lines = fs.readFileSync(INTERACTIONS_FILE, 'utf-8').split('\n').filter(Boolean);
  const filteredLines = lines.filter(line => {
    const interaction = JSON.parse(line);
    const interactionDate = new Date(interaction.timestamp);
    return interactionDate >= cutoffDate;
  });

  fs.writeFileSync(INTERACTIONS_FILE, filteredLines.join('\n'));

  console.log(`${GREEN}✅ Cleared ${lines.length - filteredLines.length} old interactions${NC}`);
  console.log(`${GREEN}✅ Kept ${filteredLines.length} recent interactions${NC}`);
}

/**
 * Optimize patterns
 */
function optimizePatterns() {
  console.log(`${BLUE}⚡ Optimizing learned patterns...${NC}`);

  if (!fs.existsSync(PATTERNS_FILE)) {
    console.log(`${RED}❌ No patterns found. Run 'init' first.${NC}`);
    return;
  }

  const patterns = JSON.parse(fs.readFileSync(PATTERNS_FILE, 'utf-8'));
  let optimizedCount = 0;

  Object.entries(patterns).forEach(([category, categoryPatterns]) => {
    Object.entries(categoryPatterns).forEach(([name, pattern]) => {
      if (pattern.success_rate < 0.7 && pattern.usage_count >= 5) {
        // Consistently underperforming
        pattern.status = 'retired';
        optimizedCount++;
      } else if (pattern.success_rate > 0.9 && pattern.usage_count > 10) {
        // High performing
        pattern.status = 'recommended';
        optimizedCount++;
      }
    });
  });

  fs.writeFileSync(PATTERNS_FILE, JSON.stringify(patterns, null, 2));
  console.log(`${GREEN}✅ Optimized ${optimizedCount} patterns${NC}`);
}

/**
 * Main CLI
 */
function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'init':
      initializeMemory();
      break;

    case 'stats':
      showStats();
      break;

    case 'export':
      const outputPath = args[1];
      exportMemory(outputPath);
      break;

    case 'clear':
      const days = parseInt(args[1]) || 90;
      clearInteractions(days);
      break;

    case 'optimize':
      optimizePatterns();
      break;

    case 'help':
      console.log(`${BLUE}HyperBrain Memory System${NC}\n`);
      console.log(`Usage: node memory.js <command> [options]\n`);
      console.log(`Commands:`);
      console.log(`  init              Initialize memory system`);
      console.log(`  stats             Show learning statistics`);
      console.log(`  export [path]     Export memory data to JSON`);
      console.log(`  clear [days]      Clear interactions older than N days (default: 90)`);
      console.log(`  optimize          Optimize learned patterns`);
      console.log(`  help              Show this help message\n`);
      break;

    default:
      console.log(`${RED}❌ Unknown command: ${command}${NC}`);
      console.log(`Run 'node memory.js help' for usage.\n`);
      process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = {
  initializeMemory,
  showStats,
  exportMemory,
  clearInteractions,
  optimizePatterns
};
