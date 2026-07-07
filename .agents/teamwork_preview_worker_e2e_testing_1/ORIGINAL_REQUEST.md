## 2026-07-04T00:01:45Z
You are a worker agent (teamwork_preview_worker).
Your task is to build and verify the headless Godot E2E Test runner and test suite for the "Corrida Eleitoral de Brasílica" project.

Specifically:
1. Create `TEST_INFRA.md` at the project root detailing:
   - Feature inventory (N = 6 features: manual clicker, upgrades, prestige, fake news, LLM speech generation, Tug-of-war win/loss).
   - Test runner command and architecture.
2. Build a test runner `tests/E2ETestRunner.gd` that executes tests in headless Godot using the console executable in `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe`.
   - The test runner must inherit from `SceneTree`.
   - It should dynamically scan `tests/e2e/` for all test files beginning with `test_` and ending with `.gd`.
   - It must execute the tests sequentially, instantiating `res://scenes/main/Game.tscn` and adding it to the root viewport (`root`), calling test methods on the test instance, performing assertions, cleaning up the game instance, and quitting the engine with exit code 0 on success, 1 on failure.
   - It must isolate the save state by backing up `user://savegame.save` to `user://savegame.save.backup` at startup, deleting the save file for clean test runs, and restoring the backup upon termination.
3. Design and implement the test suite under `tests/e2e/` covering Tiers 1-4 with at least 71 total test cases:
   - Tier 1: Feature Coverage (>=5 per feature for 6 features -> >= 30 cases)
   - Tier 2: Boundary & Corner Cases (>=5 per feature for 6 features -> >= 30 cases)
   - Tier 3: Cross-Feature Combinations (pairwise -> >= 6 cases)
   - Tier 4: Real-World Application Scenarios (end-to-end game runs -> >= 5 cases)
   *Note*: Since the Local LLM feature (`LocalLLMClient` node/class) is planned but not yet implemented, design the tests to expect its planned interface (e.g. method `generate_speech_async(topic, prompt)`, signals `speech_generated(text)` and `generation_failed(error_msg)`). Implement a mock client at `tests/mocks/MockLLMClient.gd` or similar, which can be dynamically swapped onto the game scene during tests to verify the UI's reaction, thinking state, signal responses, and timeouts.
4. Run the test suite using the Godot console executable in headless mode and verify that it runs and outputs results.
   Command: `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd`
5. Publish `TEST_READY.md` at the project root upon successful execution.
6. Write a complete handoff report in your directory: `c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\teamwork_preview_worker_e2e_testing_1`.
7. Send a handoff message back to me (parent conversation ID: 31684abb-ff03-4a97-83d3-079b2953cc42).

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
