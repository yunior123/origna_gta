# 🚀 Quick Start: Parallel Claude Agents

## Installation (une seule fois)

```bash
chmod +x orchestrate-agents.sh fix-backend-tests.sh
```

## Utilisation

### Démarrer les 6 agents
```bash
./orchestrate-agents.sh
```

**Ce qui se passe:**
- 6 nouveaux terminaux s'ouvrent automatiquement
- Chaque agent commence son cycle de monitoring
- Les logs sont sauvegardés dans `.agent-logs/`

### Voir ce que font les agents

```bash
# Test runner (toutes les 60s)
tail -f .agent-logs/test-runner.log

# Backend guardian (code quality)
tail -f .agent-logs/backend-guardian.log

# Frontend polish (UI/UX checks)
tail -f .agent-logs/frontend-polish.log

# Security audit (vulns scan)
tail -f .agent-logs/security-scan.log

# Performance optimizer (N+1 queries)
tail -f .agent-logs/performance-n1.log

# Docs keeper (documentation)
tail -f .agent-logs/docs-todos.log

# Tous en même temps
tail -f .agent-logs/*.log
```

### Arrêter tous les agents
```bash
./stop-agents.sh
```

## Slash Commands Disponibles

Dans n'importe quelle session Claude (console, terminal, VS Code):

```bash
/permissions           # Active permissions pré-approuvées
/test-all             # Lance tous les tests
/fix-tests backend    # Répare tests backend
/commit-push "msg"    # Commit intelligent + push
/deploy staging       # Déploie staging
/audit-security       # Scan sécurité
/optimize-db          # Optimise database
```

## Workflow Recommandé

```bash
# 1. Début de session
/permissions
./orchestrate-agents.sh

# 2. Développer normalement
# Les agents monitent automatiquement

# 3. Avant commit
/test-all
/commit-push "My changes"

# 4. Avant deploy
/audit-security
/deploy staging
# Si OK:
/deploy production
```

## Documentation Complète

- [PARALLEL_AGENTS_SETUP_COMPLETE.md](PARALLEL_AGENTS_SETUP_COMPLETE.md) - Guide complet
- [CLAUDE.md](CLAUDE.md) - Configuration master
- [docs/AUDIT_INDEX.md](docs/AUDIT_INDEX.md) - Index audits
- [.claude/commands/*.md](.claude/commands/) - Détails slash commands

## Support

Questions? Consultez:
1. [CLAUDE.md](CLAUDE.md) - Configuration & règles
2. [.claude/test_runner_agent.md](.claude/test_runner_agent.md) - Agent tests
3. [PARALLEL_AGENTS_SETUP_COMPLETE.md](PARALLEL_AGENTS_SETUP_COMPLETE.md) - Setup complet
