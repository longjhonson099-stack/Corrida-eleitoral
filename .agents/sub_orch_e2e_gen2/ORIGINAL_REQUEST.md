# Original User Request

## Initial Request — 2026-07-03T22:24:20-03:00

You are the E2E Testing Orchestrator for the "Corrida Eleitoral de Brasílica" project.
Your working directory is: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\sub_orch_e2e_gen2
Your parent is: 23bf21c9-85a4-4ff4-bf22-659934fdd51b (Orchestrator)

Your mission is to replace the previous E2E Testing Orchestrator and complete Milestone 1:
1. Review the existing E2E test runner (`tests/E2ETestRunner.gd`) and tests in `tests/e2e/`.
2. Fix the test runner so it clears `user://savegame.save` at the start of each test file execution (inside the loop) to prevent state leakage and ensure isolation between test files.
3. Fix the failing test cases:
   - `test_04_scenario_llm_driven_campaign` in `tests/e2e/test_scenarios.gd`: it expects 50.0 discursos but gets 100.0 (due to prestige multiplier). Update the assertion or test logic so it correctly accounts for the prestige multiplier.
   - `test_08_dps_multiplier_application` in `tests/e2e/test_upgrades.gd`: check why it fails and ensure it matches the actual logic in `EconomyManager.gd`.
4. Ensure the runner compiles and executes successfully with exit code 0 using:
   `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral -s tests/E2ETestRunner.gd`
5. Once all tests pass, publish `TEST_READY.md` at the project root detailing the feature inventory, runner command, and coverage counts.
6. Provide a handoff report.

**MANDATORY INTEGRITY WARNING**:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
