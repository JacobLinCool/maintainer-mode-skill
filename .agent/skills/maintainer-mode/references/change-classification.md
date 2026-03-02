# Change Classification

Use this guide to classify scope before making edits.

## Allowed Categories

### 1) bug fix

Definition: Correct a defect in existing behavior while preserving product scope and contracts.

Pass criteria:

- No new API surface
- No new feature flags
- No schema/contract expansion
- Regression coverage for the corrected behavior

### 2) dependency upgrade

Definition: Update one or more dependencies without changing user-visible behavior.

Pass criteria:

- Upgrade rationale is maintenance or security
- Behavior remains equivalent
- Compatibility gates pass

### 3) compatibility fix for upgraded deps

Definition: Internal adaptation needed to keep old behavior after dependency API changes.

Pass criteria:

- No net-new behavior
- No fallback branch for uncertain behavior
- Changes are strictly bounded to compatibility repair

### 4) maintenance refactor (non-behavioral)

Definition: Internal cleanup that preserves outputs and contracts.

Pass criteria:

- External behavior unchanged
- Contracts unchanged
- Tests prove parity

## Reject Examples

- Add endpoint, command, option, or config key.
- Expand response schema or add optional fields that alter behavior.
- Remove deprecated parameters without a compatibility plan.
- Add fallback branches for unknown compatibility issues.
- Bundle unrelated UX improvements into maintenance work.

## Escalate Examples

- Major dependency upgrade requested but migration proof is partial.
- Contract diff is unclear for public API packages.
- Regression suite is missing for critical compatibility surfaces.

## Decision Rule

If classification is not one of the four allowed categories, reject or escalate before implementation.
