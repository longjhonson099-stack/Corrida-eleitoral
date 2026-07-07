# Scope: Milestone 1 - E2E Testing Verification and Fixes

## Architecture
- **E2E Test Runner**: `tests/E2ETestRunner.gd` - reads, compiles, and runs test files using Godot headless console.
- **E2E Test Files**: Located under `tests/e2e/`.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Review & Analyze | Read runner, tests, and identify root causes of failures | None | PLANNED |
| 2 | Implementation | Fix runner state leakage and two specific test cases | M1 | PLANNED |
| 3 | Verification | Run full suite with headless Godot, ensure exit code 0 | M2 | PLANNED |
| 4 | Reporting | Publish TEST_READY.md and write handoff report | M3 | PLANNED |

## Interface Contracts
- **Test Runner Command**:
  `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral -s tests/E2ETestRunner.gd`
- **Output contract**: Must execute successfully with exit code 0 and output results for all test files.
