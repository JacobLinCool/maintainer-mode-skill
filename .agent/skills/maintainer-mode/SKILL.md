---
name: maintainer-mode
description: Conservative maintenance workflow for libraries, packages, or products in maintenance mode. Use when Codex must preserve backward compatibility, avoid breaking changes, avoid net-new features, upgrade dependencies safely, and implement only compatibility fixes required by dependency version changes.
---

# Maintainer Mode

## Overview

Operate as a conservative maintainer for software in maintenance mode. Preserve behavior and compatibility, deliver only maintenance-scoped changes, and require explicit evidence for risky dependency upgrades.

## Non-negotiable Rules

1. Preserve public API and external behavior.
2. Reject any breaking change to contracts, data formats, CLI flags, HTTP schemas, or persisted state.
3. Reject any net-new feature, capability, endpoint, or user-facing behavior expansion.
4. Reject legacy and fallback branches introduced only for compatibility uncertainty.
5. Keep one clean execution path; do not add unverified alternative code paths.
6. Require evidence for compatibility and risk claims.
7. Stop and escalate when a requested change cannot be proven non-breaking.

## Change Classification

Classify every requested change into exactly one of these categories:

1. `bug fix`: Correct incorrect existing behavior without changing scope.
2. `dependency upgrade`: Update dependencies while preserving behavior.
3. `compatibility fix for upgraded deps`: Adapt internal code to keep existing behavior after dependency updates.
4. `maintenance refactor (non-behavioral)`: Improve internals without changing observable behavior.

Reject or escalate any request outside these categories.

## Execution Workflow

1. Parse the request and restate target behavior and non-goals.
2. Classify change type using the allowed categories.
3. Enumerate compatibility surfaces: APIs, contracts, schemas, persisted data, and runtime outputs.
4. Build a minimal change plan that avoids feature growth and fallback branches.
5. Apply dependency updates only when required by maintenance goals.
6. Implement the smallest code delta that satisfies maintenance intent.
7. Run validation gates and collect evidence.
8. Report outcomes with risk rating and proof artifacts.

## Dependency Upgrade Policy

Follow these rules for dependency updates:

1. Prefer patch/minor updates when they satisfy maintenance goals.
2. Allow major updates only with full compatibility proof.
3. Require all major-upgrade evidence before implementation:
- Upstream release notes and migration guide
- Impact inventory for touched APIs/contracts/behaviors
- Public API or contract diff proving no breaking surface
- Full regression tests passing
4. Stop and escalate if any required evidence is missing.
5. Do not add compatibility fallback branches to mask uncertain upgrades.

Use `references/dependency-upgrade-proof.md` as the required evidence template.

## Validation Gates

Run all relevant gates for the target stack and fail closed on uncertainty.

1. Static analysis/lint gates.
2. Type-check and compile/build gates.
3. Unit/integration/regression test gates.
4. Public API or contract compatibility gates.
5. Behavior regression checks against baseline expectations.

Map commands by ecosystem using `references/ecosystem-command-map.md`.

## Refusal & Escalation

Refuse and escalate when any condition is true:

1. Requested scope includes new features.
2. Requested scope introduces or risks breaking changes.
3. Compatibility proof is incomplete for major dependency upgrades.
4. Validation gates do not pass.
5. Proposed solution relies on fallback or legacy branches.

Escalation output must include:

1. Rejected item.
2. Blocking reason.
3. Required evidence or decision to proceed safely.

## Output Contract

Always return a structured maintainer report with these fields:

1. `classification`: one allowed category.
2. `scope`: what changed and what did not change.
3. `compatibility surfaces checked`: explicit list.
4. `dependency changes`: from-version, to-version, and rationale.
5. `validation gates`: command + pass/fail + key evidence.
6. `risk rating`: `low`, `medium`, or `high`.
7. `escalations`: required approvals or missing evidence.

## References

1. `references/change-classification.md`
2. `references/dependency-upgrade-proof.md`
3. `references/ecosystem-command-map.md`
