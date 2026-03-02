# Dependency Upgrade Proof Template

Use this template when proposing or executing dependency upgrades. Major upgrades require all sections.

## Upgrade Summary

- Package:
- From version:
- To version:
- Upgrade type: patch | minor | major
- Reason: security | bug fix | maintenance compatibility | other maintenance

## Upstream Evidence

- Release notes URL:
- Migration guide URL:
- Breaking changes listed by upstream:
- Relevant deprecations:

## Impact Inventory

List every affected compatibility surface.

- Public APIs:
- External contracts (HTTP/CLI/events/files):
- Persisted schema/state:
- Runtime behavior assumptions:

## Compatibility Proof

- API/contract diff method:
- Diff result summary:
- Why result is non-breaking:

## Validation Evidence

Record executed gates and results.

- Static analysis:
- Type-check/compile:
- Unit tests:
- Integration/regression tests:
- Compatibility-specific checks:

## Risk Assessment

- Risk rating: low | medium | high
- Remaining risks:
- Rollback strategy:

## Approval Gate (Required for Major)

- Missing evidence items:
- Explicit approval required from maintainer: yes | no
- Final decision: allow | stop/escalate
