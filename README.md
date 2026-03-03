# Maintainer Mode Skill

A Claude Code skill and GitHub Actions bot for conservative software maintenance. When `@mentioned` in any repo's issue or PR, the bot applies maintainer-mode rules — preserving backward compatibility, rejecting breaking changes, and allowing only maintenance-scoped work.

No GitHub App installation required. No external infrastructure. Just a bot account + GitHub Actions.

## How It Works

```
Issue/PR comment: @bot-username fix dependency vulnerability
  → GitHub notification to bot account
  → poll.yml (runs every 5 min) picks up the mention
  → Adds 👀 reaction to the comment
  → Dispatches bot.yml workflow
  → bot.yml forks the target repo under the bot account
  → Claude Code analyzes the request under maintainer-mode rules
  → Pushes changes to the fork, opens a cross-fork PR
  → Reports back on the issue
```

## Skill Overview

The maintainer-mode skill enforces a strict maintenance-only workflow. Claude will:

- **Allow** bug fixes, dependency upgrades, compatibility fixes, and non-behavioral refactors
- **Reject** new features, breaking changes, and scope expansion
- **Escalate** when compatibility proof is incomplete or risk is unclear

### Allowed Change Categories

| Category | Description |
|---|---|
| Bug fix | Correct existing behavior without changing scope |
| Dependency upgrade | Update dependencies while preserving behavior |
| Compatibility fix | Adapt code to maintain behavior after dependency changes |
| Maintenance refactor | Internal cleanup with no observable behavior change |

Any request outside these categories is rejected or escalated.

See [`.agent/skills/maintainer-mode/SKILL.md`](.agent/skills/maintainer-mode/SKILL.md) for the full rule set.

## Setup

### Prerequisites

- A dedicated GitHub **bot account** (a regular user account acting as the bot)
- An [Anthropic API key](https://console.anthropic.com/)

### 1. Fork or clone this repo

The bot runs from this repo's GitHub Actions. Fork it to your bot account, or clone and push to a new repo owned by the bot.

### 2. Create secrets

In the repo's **Settings > Secrets and variables > Actions**, add:

| Secret | Description |
|---|---|
| `BOT_PAT` | Classic PAT from the bot account with `repo`, `notifications`, `workflow` scopes |
| `ANTHROPIC_API_KEY` | Anthropic API key for Claude Code |

### 3. Enable workflows

Go to the **Actions** tab and enable the workflows if prompted.

### 4. Start using

Mention `@bot-username` with a command in any **public repo's** issue or PR. The bot does not need write access to the target repo — it operates through forks.

## Usage

### Commands

In any issue or PR, mention the bot:

```
@bot-username ping
```

Returns "pong 🏓" — useful for verifying the bot is working.

```
@bot-username fix <description>
```

```
@bot-username upgrade <dependency>
```

```
@bot-username refactor <description>
```

Any command other than `ping` is dispatched to Claude Code with maintainer-mode rules applied. Claude analyzes the request, classifies it, and either implements it (opening a PR via fork) or explains why it was rejected.

### Examples

```
@bot-username fix the broken date parsing in utils.ts

@bot-username upgrade lodash to latest

@bot-username refactor extract the validation logic into a separate module
```

## Architecture

```
.
├── .github/workflows/
│   ├── poll.yml          # Scheduled notification polling (every 5 min)
│   └── bot.yml           # Command handler (fork → Claude Code → PR)
├── .agent/skills/
│   └── maintainer-mode/  # Skill definition and references
│       ├── SKILL.md
│       ├── agents/
│       │   └── agent.yaml
│       └── references/
│           ├── change-classification.md
│           ├── dependency-upgrade-proof.md
│           └── ecosystem-command-map.md
├── scripts/
│   └── poll.sh           # Notification polling logic
└── README.md
```

### poll.yml

Runs on a 5-minute cron schedule. Calls `scripts/poll.sh` which:

1. Fetches unread notifications via `gh api /notifications`
2. Filters for `reason: mention` on Issues and PRs
3. Parses `@bot-username command [args]` from the comment
4. Adds a 👀 reaction to acknowledge
5. `ping` → replies "pong 🏓" directly
6. Other commands → dispatches `bot.yml` via `gh workflow run`
7. Marks the notification as read

### bot.yml

Located at `.github/workflows/bot.yml`. Triggered by `workflow_dispatch` from `poll.sh`.

**Flow:**

```
workflow_dispatch (from poll.sh)
  │
  ├─ 1. Acknowledge: post comment on the issue
  │
  ├─ 2. Fork & sync: gh repo fork → gh repo sync
  │
  ├─ 3. Checkout fork, create branch: bot/<command>-<issue>-<timestamp>
  │
  ├─ 4. Copy maintainer-mode skill files into workspace
  │
  ├─ 5. claude-code-action: analyze + implement (or reject)
  │     Claude writes .bot-result.json with decision + summary
  │
  └─ 6. Handle result
        │
        ├─ decision = "rejected" or "escalated"
        │     → Reply on issue with reason, NO PR
        │
        ├─ decision = "accepted" + no file changes
        │     → Reply on issue: completed, no changes needed
        │
        └─ decision = "accepted" + file changes
              → Commit, push to fork
              → Open cross-fork PR to source repo
              → Reply on issue with PR link
```

The bot never needs write access to the target repo. All changes go through the standard fork → PR flow.

## Secrets Reference

| Secret | Required | Description |
|---|---|---|
| `BOT_PAT` | Yes | Classic PAT: `repo`, `notifications`, `workflow` scopes |
| `ANTHROPIC_API_KEY` | Yes | From [console.anthropic.com](https://console.anthropic.com/) |
| `REPO_WHITELIST` | No | Regexp pattern to restrict which repos the bot responds to |

### `REPO_WHITELIST`

An extended regular expression (ERE) matched against `owner/repo`. Only notifications from matching repos are processed. Unmatched notifications are marked as read and ignored.

If not set, the bot responds to all repos.

Examples:

```
# Single repo
^myorg/my-repo$

# All repos under an org
^myorg/

# Multiple orgs
^(myorg|another-org)/

# Specific repos
^(myorg/repo-a|myorg/repo-b|friend/project)$
```

### Why Classic PAT?

Fine-grained PATs are limited to repos you own or belong to. Since the bot forks and interacts with arbitrary public repos, a classic PAT with `repo` scope is required.

## Debugging

- **Manual trigger**: Go to Actions > "Poll Notifications" > "Run workflow" to trigger polling immediately
- **Check logs**: Each poll run and bot handler run logs detailed information about processed notifications and commands
- **Test with `ping`**: The simplest way to verify the bot is working end-to-end

## License

[MIT](LICENSE)
