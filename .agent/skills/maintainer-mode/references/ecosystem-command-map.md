# Ecosystem Command Map

Use these commands as baseline gates. Prefer project-native scripts when present.

## JavaScript / TypeScript (npm, pnpm, yarn)

- Install/update deps:
  - `pnpm up <pkg>`
  - `npm update <pkg>`
  - `yarn up <pkg>`
- Static/lint:
  - `pnpm lint`
  - `npm run lint`
- Type-check/build:
  - `pnpm typecheck`
  - `pnpm build`
  - `npm run build`
- Tests/regression:
  - `pnpm test`
  - `npm test`

## Python (pip, uv, poetry)

- Install/update deps:
  - `uv add <pkg>`
  - `pip install -U <pkg>`
  - `poetry add <pkg>@latest`
- Static/lint:
  - `ruff check .`
  - `flake8`
- Type-check/build:
  - `mypy .`
  - `python -m build`
- Tests/regression:
  - `pytest`

## Go

- Install/update deps:
  - `go get module@version`
  - `go mod tidy`
- Static/lint:
  - `go vet ./...`
  - `golangci-lint run`
- Build:
  - `go build ./...`
- Tests/regression:
  - `go test ./...`

## Rust

- Install/update deps:
  - `cargo update -p <crate>`
- Static/lint:
  - `cargo clippy --all-targets --all-features -- -D warnings`
- Type-check/build:
  - `cargo check --all-targets --all-features`
  - `cargo build --all-targets --all-features`
- Tests/regression:
  - `cargo test --all-features`

## Gate Recording Format

For each executed gate, record:

- Command
- Exit status
- Key evidence (summary line)
- Impacted compatibility surfaces
