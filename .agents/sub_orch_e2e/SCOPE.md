# Scope: E2E Testing Track (Milestone 1)

## Architecture
- The E2E Test Suite runs in headless Godot.
- The test runner `tests/E2ETestRunner.gd` inherits from `SceneTree` to allow headless execution using the `-s` command.
- It instantiates `Game.tscn`, executes E2E test cases across Tiers 1-4, records and prints results, and exits with a proper code.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Design TEST_INFRA.md | Detail feature inventory and runner architecture. | None | PLANNED |
| 2 | Build Test Runner | Implement E2ETestRunner.gd in `tests/`. | M1 | PLANNED |
| 3 | Implement Test Cases | Implement Tiers 1-4 covering all 6 features (at least 71 cases). | M2 | PLANNED |
| 4 | Run & Verify Suite | Run tests via Godot console in headless mode, verify output. | M3 | PLANNED |
| 5 | Publish TEST_READY.md | Create and publish TEST_READY.md at project root. | M4 | PLANNED |

## Interface Contracts
### `E2ETestRunner` ↔ `Godot`
- Command: `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\tests\E2ETestRunner.gd`
- Output: Console print lines starting with `[PASS]` or `[FAIL]`, followed by summary and exit code 0 for success, 1 for failure.
