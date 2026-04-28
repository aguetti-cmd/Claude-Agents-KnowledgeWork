# File Location Standards

This file is the executor's quick reference for agent workflow paths. For the detailed spec (folder rationale, naming conventions, tagging, approval workflow), see your vault's organization notes.

**Documents (~/Documents/) = temporary working space. Final approved content lives in the vault.**

Note: vault paths assume `$VAULT_PATH` is configured. If not, vault-dependent features are skipped.

## Content workflow and file locations

### Blog content
```
Research brief (Sofia output)
  $VAULT_PATH/03.Resources/AI-Workspace/research/[topic]-research-brief.md

Outline (Marco working file)
  ~/Documents/01 - Projects/Blog/outlines/[article]-outline.md (temporary)

Draft (Marco working file)
  ~/Documents/01 - Projects/Blog/articles/[article]-draft.md (temporary)

Approved article (final)
  $VAULT_PATH/01.Projects/Blog/articles/[article].md

LinkedIn adaptation (Ren output)
  $VAULT_PATH/01.Projects/Blog/LinkedIn-adaptations/LinkedIn-[article].md

Distribution strategy (Ren output)
  $VAULT_PATH/01.Projects/Blog/distribution-strategies/[article]-distribution.md
```

### Prompt files
```
Prompt (Kai output)
  $VAULT_PATH/03.Resources/AI-Workspace/prompts/[topic].md
```

### Tool evaluations
```
Tool evaluation (Kai output)
  $VAULT_PATH/03.Resources/AI-Workspace/tools/[tool-name]-evaluation.md
```

### Code and technical files
```
Code working file (Leo output)
  ~/Documents/01 - Projects/Code/[project]/[filename]

Technical spec or architecture note (Leo output, persistent)
  $VAULT_PATH/03.Resources/AI-Workspace/code/[topic].md
```

## Vault organization
- All agent briefs should specify file locations upfront
- Giulia files approved content to vault on agent request
- No approved content lives outside the vault
