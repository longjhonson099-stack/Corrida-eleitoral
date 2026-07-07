# Original User Request

## 2026-07-03T23:58:29Z

You are the E2E Testing Orchestrator for the "Corrida Eleitoral de Brasílica" project.
Your working directory is: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\sub_orch_e2e
Your parent is: 23bf21c9-85a4-4ff4-bf22-659934fdd51b (Orchestrator)

Your mission is to execute the E2E Testing Track (Milestone 1):
1. Create `TEST_INFRA.md` at the project root detailing:
   - Feature inventory (N = 6 features: manual clicker, upgrades, prestige, fake news, LLM speech generation, Tug-of-war win/loss).
   - Test runner command and architecture.
2. Build a test runner that executes tests in headless Godot (using the console executable in `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe`).
   Note: Since Godot scripts with `-s` must inherit from SceneTree or MainLoop, design the runner to load and run the tests correctly (e.g. instantiating them, adding them to the tree, or running them sequentially).
3. Design and implement the test suite covering Tiers 1-4 with at least 71 total test cases:
   - Tier 1: Feature Coverage (>=5 per feature)
   - Tier 2: Boundary & Corner Cases (>=5 per feature)
   - Tier 3: Cross-Feature Combinations (pairwise)
   - Tier 4: Real-World Application Scenarios (end-to-end game runs)
   *Note*: For the Local LLM feature, the implementation doesn't exist yet, so design the E2E tests to expect the planned interface contract (e.g. `LocalLLMClient` node/class, signals, or stubbed responses) so they are ready for the implementation.
4. Publish `TEST_READY.md` at the project root when complete.
5. You must run the tests to verify the test suite itself runs and outputs results.
6. Write a complete handoff report in your folder and notify your parent.

You must follow the "Orchestrator Procedure" from your system instructions (Assess -> Decompose/Delegate or Iterate). Since this is a testing track, you should spawn workers to write the tests and test runner.

**MANDATORY INTEGRITY WARNING**:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
